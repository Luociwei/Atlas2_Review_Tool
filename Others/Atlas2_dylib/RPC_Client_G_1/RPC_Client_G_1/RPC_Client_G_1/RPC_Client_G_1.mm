//
//  RPC_Client.m
//  RPC_Client
//
//

#include "RPC_Client_G_1.h"


#include "zmq.h"

#include <iostream>
#include <sstream>

#include <unistd.h>

#define kRPCClientRequester           @"requester"
#define kRPCClientReceiver            @"receiver"
#define PEP_AUTOMATION_ADDRESS          "tcp://127.0.0.1:3100"
#define kFixtureControl               @"/Users/gdlocal/Config/fixtureControl.txt"

RPC_Client_G_1::RPC_Client_G_1()
{
    m_lockBuffer = [[NSLock alloc]init];
    bNeedZmq = false;
    ENDPOINT = [NSMutableDictionary new];
    NON_EXISTING_ENDPOINT = [NSMutableDictionary new];
    
    
    [ENDPOINT setValue:@"tcp://127.0.0.1:5556" forKey:kRPCClientRequester];
    [ENDPOINT setValue:@"tcp://127.0.0.1:15556" forKey:kRPCClientReceiver];
    [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:5555" forKey:kRPCClientRequester];
    [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:15555" forKey:kRPCClientReceiver];
    dic_rpcCommand = [[NSMutableDictionary alloc] init];
    NSLog(@"RPC_CLIENT: %@\n",@"RPC Client Dylib init!");
}

RPC_Client_G_1::RPC_Client_G_1(const char* filePath)
{
    m_lockBuffer = [[NSLock alloc]init];
    bNeedZmq = false;
    ENDPOINT = [NSMutableDictionary new];
    NON_EXISTING_ENDPOINT = [NSMutableDictionary new];
    
    
    [ENDPOINT setValue:@"tcp://127.0.0.1:5556" forKey:kRPCClientRequester];
    [ENDPOINT setValue:@"tcp://127.0.0.1:15556" forKey:kRPCClientReceiver];
    [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:5555" forKey:kRPCClientRequester];
    [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:15555" forKey:kRPCClientReceiver];
    
    NSString *file = [NSString stringWithUTF8String:filePath];
    dic_rpcCommand = [[NSMutableDictionary alloc] initWithContentsOfFile:file];

    NSLog(@"RPC_CLIENT: %@\n",@"RPC Client Dylib init!");
}

RPC_Client_G_1::~RPC_Client_G_1()
{
    if (m_lockBuffer) {
        [m_lockBuffer release];
    }
    UnLockSendCmd("rpc_send_command");
    [ENDPOINT release];
    [NON_EXISTING_ENDPOINT release];
    [dic_rpcCommand release];
    
    NSLog(@"RPC_CLIENT: %@\n",@"RPC Client Dylib quit!");
}

int RPC_Client_G_1::CreateIPC(const char* reply, const char* publish)
{
    CPubliser::bind(publish);
    CReplier::bind(reply);
    bNeedZmq = true;
    return 0;
}

int RPC_Client_G_1::initWithEndpoint(const char* requester, const char* receiver)
{
    [ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%s",requester] forKey:kRPCClientRequester];
    [ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%s",receiver] forKey:kRPCClientReceiver];
    
    m_Client = [RPCClientWrapper initWithEndpoint:ENDPOINT];
    if (m_Client) {
        return 0;
    }
    return -1;
}

int RPC_Client_G_1::initWithEndpoint(const char* requester, const char* receiver, int interval_ms, int retries)
{
    [ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%s",requester] forKey:kRPCClientRequester];
    [ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%s",receiver] forKey:kRPCClientReceiver];
    
    if (retries < 1) retries = 1;
    for (int i=0; i<= retries; i++) {
        m_Client = [RPCClientWrapper initWithEndpoint:ENDPOINT];
        if (m_Client) {
            return 0;
        }
        usleep(1000*interval_ms);
    }
    
    NSLog(@"RPCClientWrapper cannot initial successful, retry: %d times", retries);
    return -1;
}

int RPC_Client_G_1::isServerReady()
{
    NSString* ready = [m_Client isServerReady];
    NSLog(@"===>read: %@",ready);
    if (![ready isEqualToString:@"PASS"]) {
        NSLog(@"RPC server Ready Status should be PASS, but actually is %@",ready);
        return -3;
    }
    return 0;
    
//    NSString* mode = [m_Client getServerMode];
//    if (![mode isEqualToString:@"normal"]) {
//        NSLog(@"==>RPC server mode should be normal, but actually is %@",mode);
//        return -1;
//    }
    
//    NSString* versionCheck = [m_Client isServerUpToDate];
//    if (![versionCheck isEqualToString:@"PASS"]) {
//        NSLog(@"RPC server isServerUpToDate should be PASS, but actually is %@",versionCheck);
//        return -2;
//    }
    
//    NSString* ready = [m_Client isServerReady];
//    if (![ready isEqualToString:@"PASS"]) {
//        NSLog(@"RPC server Ready Status should be PASS, but actually is %@",ready);
//        return -3;
//    }
  //  return 0;
}

const char* RPC_Client_G_1::getServerMode()
{
    NSString* mode = [m_Client getServerMode];
    return [mode UTF8String];
}

const char* RPC_Client_G_1::isServerUpToDate()
{
    //NSString* versionCheck = [m_Client isServerUpToDate];
    //return [versionCheck UTF8String];
    return "";
}



const char* RPC_Client_G_1::rpc_client(const char* command,int timeout)
{
    NSString *cmd = [NSString stringWithUTF8String:command];
    if(CPubliser::m_socket)
    {
        NSString *sendcmd = [NSString stringWithFormat:@"[sendcmd] %s",command];
        Pulish((void *)[sendcmd UTF8String], [sendcmd length]);
    }
    NSArray *arrCmd = nil;
    if ([cmd containsString:@"]"])
    {
        NSArray *arrSub= [cmd componentsSeparatedByString:@"]"];
        arrCmd = [arrSub[1] componentsSeparatedByString:@"("];
    }
    else
    {
        arrCmd = [cmd componentsSeparatedByString:@"("];
    }
    if ([arrCmd count]<2)
    {
        NSString *err = @"command format error\r\n";
        if(CPubliser::m_socket)
        {
            Pulish((void *)[err UTF8String], [err length]);
        }
        return [err UTF8String];
    }
    if (!dic_rpcCommand[arrCmd[0]])
    {
        NSString *err = @"command error, not define in rpc_command.plist\r\n";
        if(CPubliser::m_socket)
        {
           Pulish((void *)[err UTF8String], [err length]);
        }
        return [err UTF8String];
    }
    
    NSString *method = dic_rpcCommand[arrCmd[0]];
    NSString * strArgs = [arrCmd[1] stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSArray *arrArgs = [strArgs componentsSeparatedByString:@","];
    if ([method isEqualToString:@"io_set"] || [method isEqualToString:@"io_get"])
    {
        NSMutableArray * arrTemp = [[NSMutableArray alloc]initWithArray:arrArgs];
        [arrTemp removeObjectAtIndex:0];
        NSString *tempString = [arrTemp componentsJoinedByString:@";"];
        [arrTemp release];
        arrArgs = [tempString componentsSeparatedByString:@","];
    }
    else if ([method isEqualToString:@"power_write"] || [method isEqualToString:@"power_write_read"])
    {
        arrArgs = [strArgs componentsSeparatedByString:@"###"];
    }
    NSMutableDictionary* dicKwargs = [NSMutableDictionary dictionary];
    [dicKwargs setObject:@(timeout) forKey:@"timeout_ms"];
    NSLog(@"[rpc_client] method: %@, args: %@, kwargs: nil,timeout_ms: %d",method,arrArgs,timeout);
    if(CPubliser::m_socket)
    {
        NSString *timeLog = [NSString stringWithFormat:@"[rpc_client] method:%@, args:%@, kwargs:nil, timeout_ms:%d",method,strArgs,timeout];
        Pulish((void *)[timeLog UTF8String], [timeLog length]);  //Publish out data to suberscriber.
    }
    if ([[arrArgs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]
        )
    {
        arrArgs = nil;
    }
    
    id rtn = [m_Client rpc:method args:arrArgs kwargs:dicKwargs];
   
    
    NSString* receiver = [NSString stringWithFormat:@"%@",rtn];
    if(CPubliser::m_socket)
    {
        NSString * ret = [NSString stringWithFormat:@"[result] %@\r\n",receiver];
        Pulish((void *)[ret UTF8String], [ret length]);  //Publish out data to suberscriber.
    }
    return [receiver UTF8String];
}


const char* RPC_Client_G_1::rpc_client2(const char* command,int timeout)
{
    NSString *cmd = [NSString stringWithUTF8String:command];
    if(CPubliser::m_socket)
    {
        NSString *sendcmd = [NSString stringWithFormat:@"[sendcmd] %s",command];
        Pulish((void *)[sendcmd UTF8String], [sendcmd length]);
    }
    NSArray *arrCmd = nil;
    if ([cmd containsString:@"]"])
    {
        NSArray *arrSub= [cmd componentsSeparatedByString:@"]"];
        arrCmd = [arrSub[1] componentsSeparatedByString:@"("];
    }
    else
    {
        arrCmd = [cmd componentsSeparatedByString:@"("];
    }
    if ([arrCmd count]<2)
    {
        NSString *err = @"command format error\r\n";
        if(CPubliser::m_socket)
        {
            Pulish((void *)[err UTF8String], [err length]);
        }
        return [err UTF8String];
    }
    if (!dic_rpcCommand[arrCmd[0]])
    {
        NSString *err = @"command error, not define in rpc_command.plist\r\n";
        if(CPubliser::m_socket)
        {
            Pulish((void *)[err UTF8String], [err length]);
        }
        return [err UTF8String];
    }
    
    NSString *method = dic_rpcCommand[arrCmd[0]];
    NSString * strArgs = [arrCmd[1] stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSArray *arrArgs = [strArgs componentsSeparatedByString:@","];
    if ([method isEqualToString:@"io_set"] || [method isEqualToString:@"io_get"])
    {
        NSMutableArray * arrTemp = [[NSMutableArray alloc]initWithArray:arrArgs];
        [arrTemp removeObjectAtIndex:0];
        NSString *tempString = [arrTemp componentsJoinedByString:@";"];
        [arrTemp release];
        arrArgs = [tempString componentsSeparatedByString:@","];
    }
    NSMutableDictionary* dicKwargs = [NSMutableDictionary dictionary];
    [dicKwargs setObject:@(timeout) forKey:@"timeout_ms"];
    NSLog(@"[rpc_client] method: %@, args: %@, kwargs: nil,timeout_ms: %d",method,arrArgs,timeout);
    if(CPubliser::m_socket)
    {
        NSString *timeLog = [NSString stringWithFormat:@"[rpc_client] method:%@, args:%@, kwargs:nil, timeout_ms:%d",method,strArgs,timeout];
        Pulish((void *)[timeLog UTF8String], [timeLog length]);  //Publish out data to suberscriber.
    }
    if ([[arrArgs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] )
    {
        arrArgs = nil;
    }
    
    LockSendCmd("rpc_send_command");
    id rtn = [m_Client rpc:method args:arrArgs kwargs:dicKwargs];
    UnLockSendCmd("rpc_send_command");
    
    NSString* receiver = [NSString stringWithFormat:@"%@",rtn];
    if(CPubliser::m_socket)
    {
        NSString * ret = [NSString stringWithFormat:@"[result] %@\r\n",receiver];
        Pulish((void *)[ret UTF8String], [ret length]);  //Publish out data to suberscriber.
    }
    return [receiver UTF8String];
}


int RPC_Client_G_1::sendFile(const char* srcFile, const char* Folder, int timeout)
{
    if ((nullptr==srcFile)||(nullptr==Folder)) {
        NSLog(@"RPC_CLIENT: (sendFile：invalid parameter!) \n");
        return -1;
    }
    
    int iTime = (timeout < 0) ? 0 : timeout;
    NSString* receive = [m_Client sendFile:[NSString stringWithUTF8String:srcFile] intoFolder:[NSString stringWithUTF8String:Folder] withTimeoutInMS:iTime];
    
    NSRange range = [receive rangeOfString:@"PASS"];
    if (range.location!=NSNotFound)
    {
        NSLog(@"RPC server sendFile should be PASS, but actually is %@",receive);
        return -1;
    }
    
    return 0;
}


const char* RPC_Client_G_1::getFile(const char* target, int timeout)
{
    if (nullptr==target) {
        NSLog(@"RPC_CLIENT: (getFile：invalid parameter!) \n");
        return "RPC_CLIENT: (getFile：invalid parameter!)";
    }
    
    int iTime = (timeout < 0) ? 0 : timeout;
    NSData* data = [m_Client getFile:[NSString stringWithUTF8String:target] withTimeoutInMS:iTime];
    if (nil == data) {
        NSLog(@"RPC_CLIENT: (getFile：data is nil!) \n");
        return "RPC_CLIENT: (getFile：data is nil!)";
    }
    
    NSString* fileContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [fileContent UTF8String];
}


int RPC_Client_G_1::getAndWriteFile(const char* target, const char* dest, int timeout)
{
    if ((nullptr==target)||(nullptr==dest)) {
        NSLog(@"RPC_CLIENT: (getFile：invalid parameter!) \n");
        return -1;
    }
    
    int iTime = (timeout < 0) ? 0 : timeout;
    NSString* fileDest = [NSString stringWithUTF8String:dest];
    NSString* filePath = [fileDest stringByDeletingPathExtension];
    if (![[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager]createFileAtPath:fileDest contents:nil attributes:nil];
    }
    
    NSString* receive = [m_Client getAndWriteFile:[NSString stringWithUTF8String:target] intoDestFile:fileDest withTimeoutInMS:iTime];
    
    NSRange range = [receive rangeOfString:@"PASS"];
    if (range.location!=NSNotFound)
    {
        NSLog(@"RPC server getAndWriteFile should be PASS, but actually is %@",receive);
        return -1;
    }
    
    return 0;
}

void *RPC_Client_G_1::OnRequest(void *pdata, long len)
{
    NSString * args = [[NSString alloc] initWithBytes:pdata length:len encoding:NSUTF8StringEncoding];
    if (args != nil || args != NULL)
    {
        rpc_client([args UTF8String],3000);
    }
    CReplier::SendStrig("OK");
    [args release];
    return nullptr;
}

int RPC_Client_G_1::LockSendCmd(const char * szLockName)
{
    NSLog(@"Lock send cmd : %s", szLockName);
    NSString * lockName = [NSString stringWithUTF8String:szLockName];
    if([lockName length]<=0)
    {
        NSLog(@"Lock send cmd : %s Invalide Lock Name", szLockName);
        return -999;
    }
    NSString * path = [NSString stringWithFormat:@"/vault/.%@.lock", lockName];
    if(![[NSFileManager defaultManager]fileExistsAtPath:path])
        [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    if((fp=fopen([path UTF8String], "r+w")) == NULL)
    {
        NSLog(@"Lock File Open error");
        return -1;
    }
    if(flock(fp->_file, LOCK_EX) != 0)
    {
        NSLog(@"File Locked error");
        return -2;
    }
    NSLog(@"Lock send cmd : %s Success", szLockName);
    return 0;
}

int RPC_Client_G_1::UnLockSendCmd(const char * szLockName)
{
    NSLog(@"unLock send cmd : %s", szLockName);
    NSString * lockName = [NSString stringWithUTF8String:szLockName];
    if([lockName length]<=0) return -999;
    if(fp)
    {
        fclose(fp);
        flock(fp->_file, LOCK_UN);
        fp = NULL;
    }
    NSLog(@"Lock send cmd : %s Success", szLockName);
    return 0;
}

int RPC_Client_G_1::UnLockSendCmd()
{
    UnLockSendCmd("rpc_send_command");
    NSLog(@"Lock send cmd : rpc_send_command.lock Success");
    return 0;
}

BOOL isPureInt(NSString *string)
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}
BOOL isPureFloat(NSString *string)
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    float val;
    return [scan scanFloat:&val] && [scan isAtEnd];
}

void writeSipFixtureLogs(NSString *str)
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY_MM_dd"];
    NSDate *datenow = [NSDate date];
    NSString *currentTimeString = [formatter stringFromDate:datenow];
    NSString *filePath=[NSString stringWithFormat:@"/vault/Suncode_log/SunCode_Fixture_%@.txt",currentTimeString];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fh)
    {
        NSFileManager *fm=[NSFileManager defaultManager];
        [fm createFileAtPath:filePath contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *datenow2 = [NSDate date];
    NSString *currentTimeString2 = [formatter stringFromDate:datenow2];
    
    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@ \t%@\r\n",currentTimeString2,str]  dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
    [formatter release];
}
void * ZmqEntry_automation(void * arg)
{
    RPC_Client_G_1 * pThis = (RPC_Client_G_1 *)arg;
    void * zmq_rep = pThis->m_SocketReply_automation;
    char buf[512];
    memset(buf, 512, 0);
    while (true)
    {
        memset(buf, 0, sizeof(buf));
        int ret = zmq_recv(zmq_rep, buf, sizeof(buf), 0);
        if (ret>0)
        {
            NSString * cmd = [NSString stringWithFormat:@"%s",buf];
            //writeSipFixtureLogs([NSString stringWithFormat:@"< Send > : %@",cmd]);
            const char * result = pThis->rpc_client([cmd UTF8String],3000);
            NSString *rult = [NSString stringWithUTF8String:result];
            //writeSipFixtureLogs([NSString stringWithFormat:@"< Result > : %@",rult]);
            zmq_send(zmq_rep, [rult UTF8String], [rult length], 0);
        }
    }
    return NULL;
}


void * ZmqEntry(void * arg)
{
    RPC_Client_G_1 * pThis = (RPC_Client_G_1 *)arg;
    void * zmq = pThis->m_SocketReply;
    char buf[512];
    memset(buf, 512, 0);
    
    while (true)
    {
        int ret = zmq_recv(zmq, buf, 512, 0);
        
        if (ret>0)
        {
            NSString * cmd = [NSString stringWithFormat:@"%s",buf ];
            NSString *strFixtureCtl = [NSString stringWithContentsOfFile:kFixtureControl encoding:NSUTF8StringEncoding error:nil];
            NSLog(@"< Rep Receive > : %s\n",[cmd UTF8String]);
            if ([strFixtureCtl containsString:@"NO"])
            {
                writeSipFixtureLogs([NSString stringWithFormat:@"Not Control Fixture.  receive msg: %@",[NSString stringWithFormat:@"%s",buf]]);
                NSString *str = @"return ok";
                writeSipFixtureLogs([NSString stringWithFormat:@"< Result > : %s",[str UTF8String]]);
                zmq_send(zmq, [str UTF8String], [str length], 0);
            }
            
            else
            {
                writeSipFixtureLogs([NSString stringWithFormat:@"< Send > : %@",cmd]);
                const char *str = pThis->rpc_client([cmd UTF8String],3000);
                writeSipFixtureLogs([NSString stringWithFormat:@"< Result > : %s",str]);
                NSString *str2 = [NSString stringWithFormat:@"%s",str];
                zmq_send(zmq, [str2 UTF8String],[str2 length], 0);
            }
            
        }
    }
    return NULL;
}



int RPC_Client_G_1::CreateREP_automation(const char *reply)
{
    m_ContextReply_automation = zmq_ctx_new();
    
    if (!m_ContextReply_automation) {
        NSLog(@"[reply] DeviceHost::failed to create ContextReply_automation! with error : %s\n",zmq_strerror(zmq_errno()));
    }
    
    m_SocketReply_automation = zmq_socket(m_ContextReply_automation, ZMQ_REP);
    
    if (!m_SocketReply_automation) {
        NSLog(@"[reply] DeviceHost::failed to create reply SocketReply_automation! with error : %s\n",zmq_strerror(zmq_errno()));
    }
    
    usleep(1000*500);   //sleep some time
    
    int ret = zmq_bind(m_SocketReply_automation, reply);
    if (ret <0) {
        NSLog(@"[reply] DeviceHost::Reply socket automation failed to bind port number : %s\n",zmq_strerror(zmq_errno()));
    }
    else
    {
        NSLog(@"[reply] DeviceHost::Create REPLY automation server,bind with address : %s\n",reply);
    }
    
    pthread_create(&m_thread, NULL, ZmqEntry_automation, this);
    return 0;
}

int RPC_Client_G_1::CreateRepPubPort(const char *rep, const char *pub, int channel)
{
    if (channel ==0) {
        m_ContextPublisher = zmq_ctx_new();
        if (!m_ContextPublisher) {
            NSLog(@"[publisher] DeviceHost::failed to create context! with error : %s\n",zmq_strerror(zmq_errno()));
        }
        
        m_ContextReply = zmq_ctx_new();
        
        if (!m_ContextReply) {
            NSLog(@"[reply] DeviceHost::failed to create context! with error : %s\n",zmq_strerror(zmq_errno()));
        }
        
        m_SocketPublisher = zmq_socket(m_ContextPublisher, ZMQ_PUB);
        
        if (!m_SocketPublisher) {
            NSLog(@"[publisher] DeviceHost::failed to create publiser socket! with error  : %s\n",zmq_strerror(zmq_errno()));
        }
        
        m_SocketReply = zmq_socket(m_ContextReply, ZMQ_REP);
        
        if (!m_SocketReply) {
            NSLog(@"[reply] DeviceHost::failed to create reply socket! with error : %s\n",zmq_strerror(zmq_errno()));
        }
        
        usleep(1000*500);   //sleep some time
        
        int ret = zmq_bind(m_SocketPublisher, pub);
        if (ret <0) {
            NSLog(@"[publisher] DeviceHost::Publiser socket,failed to bind port number : %s\n",zmq_strerror(zmq_errno()));
        }
        else
        {
            NSLog(@"[publisher] DeviceHost::Create PUBLISER server,bind with address : %s\n", pub);
        }
        
        ret = zmq_bind(m_SocketReply, rep);
        if (ret <0) {
            NSLog(@"[reply] DeviceHost::Reply socket failed to bind port number : %s\n",zmq_strerror(zmq_errno()));
        }
        else
        {
            NSLog(@"[reply] DeviceHost::Create REPLY server,bind with address : %s\n",rep);
        }
        
        pthread_create(&m_thread, NULL, ZmqEntry, this);
        CreateREP_automation(PEP_AUTOMATION_ADDRESS);
        return 0;
    }
    else
    {
        return -1;
    }
}




