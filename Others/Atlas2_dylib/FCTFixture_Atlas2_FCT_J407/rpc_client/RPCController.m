//
//  RPCController.m
//  FCTFixture
//
//  Created by RyanGao on 2020/10/6.
//  Copyright © 2020 RyanGao. All rights reserved.
//

#import "RPCController.h"
#import "GeneralConfig.h"

#define kRPCClientRequester           @"requester"
#define kRPCClientReceiver            @"receiver"


@implementation RPCController
@synthesize m_Clients = _m_Clients;

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        ENDPOINT = [[NSMutableDictionary alloc] init];
        NON_EXISTING_ENDPOINT = [[NSMutableDictionary alloc] init];
        [ENDPOINT setValue:@"tcp://127.0.0.1:5556" forKey:kRPCClientRequester];
        [ENDPOINT setValue:@"tcp://127.0.0.1:15556" forKey:kRPCClientReceiver];
        [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:5555" forKey:kRPCClientRequester];
        [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:15555" forKey:kRPCClientReceiver];
        //m_status = -1;
        
        regular = [[NSRegularExpression alloc] initWithPattern:@"[+-]?\\d+[.]?\\d*" options:NSRegularExpressionCaseInsensitive error:nil];
        
    }
    return self;
    
}

-(instancetype)initWithSlots:(int)slots withAddr:(NSArray *)devAddrArr
{
    self = [super init];
    if (self)
    {
        ENDPOINT = [[NSMutableDictionary alloc] init];
        NON_EXISTING_ENDPOINT = [[NSMutableDictionary alloc] init];
        [ENDPOINT setValue:@"tcp://127.0.0.1:5556" forKey:kRPCClientRequester];
        [ENDPOINT setValue:@"tcp://127.0.0.1:15556" forKey:kRPCClientReceiver];
        [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:5555" forKey:kRPCClientRequester];
        [NON_EXISTING_ENDPOINT setValue:@"tcp://127.0.0.1:15555" forKey:kRPCClientReceiver];
        //m_status = -1;
        NSLog(@"Slot and addr%d====%@", slots,devAddrArr);
        regular = [[NSRegularExpression alloc] initWithPattern:@"[+-]?\\d+[.]?\\d*" options:NSRegularExpressionCaseInsensitive error:nil];
        int ret = [self Open:devAddrArr withSlot:slots];
        if (ret == -1)
        {
            return nil;
        }
    }
    return self;
}

//-(int)Open:(NSString *)devAddr
//{
//    if (self.m_Clients)
//    {
//        [self.m_Clients removeAllObjects];
//    }
//    else
//    {
//        self.m_Clients = [[NSMutableArray alloc] init];
//    }
//    int retries = 4;
//    int interval_ms = 1000;
//    for (int i=0; i<= retries; i++)
//    {
//        RPCClientWrapper *m_Client = [RPCClientWrapper initWithStringEndpoint:[NSString stringWithFormat:@"tcp://%@",devAddr]];
//        
//        /*[ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%@",devAddr] forKey:kRPCClientRequester];
//        NSArray *tmpArr = [devAddr componentsSeparatedByString:@":"];
//        NSString *receiver = [NSString stringWithFormat:@"%@:1%@",tmpArr[0],tmpArr[1]];
//        [ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%@",receiver] forKey:kRPCClientReceiver];
//        RPCClientWrapper *m_Client = [RPCClientWrapper initWithEndpoint:ENDPOINT];
//        */
//        
//        if (m_Client)
//        {
//            m_status = 0;
//            [self.m_Clients addObject:m_Client];
//            [self syncXavierClock];
//            return 0;
//        }
//        usleep(1000*interval_ms);
//    }
//    NSLog(@"RPCClientWrapper cannot initial successful, retry: %d times", retries);
//    m_status = -1;
//    [self syncXavierClock];
//    return m_status;
//}

-(NSString *)executePingCommand:(NSString *)ip
{
    //NSLog(@"ping: %@",ip);
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/sbin/ping"];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"-c1", @"-W1",ip,nil];
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //[task release];
    [file closeFile];
    return string;
}

-(int)Open:(NSArray *)devAddrArr withSlot:(int) slots
{
    if (self.m_Clients)
    {
        [self.m_Clients removeAllObjects];
    }
    else
    {
        self.m_Clients = [[NSMutableDictionary alloc] init];
    }
    
//    NSString *ipAdd = devAddrArr[0];
//    NSArray * strArray = [ipAdd componentsSeparatedByString:@":"];
//    NSString *retPing = [self executePingCommand:strArray[0]];
//    if ([retPing rangeOfString:@"100.0% packet loss"].location != NSNotFound)
//    {
//        NSLog(@"%@",retPing);
//        m_status = -1;
//        return m_status;
//    }
    
    int retries = 4;
    int interval_ms = 1000;
    
    //int m_status = 0;

    for (int i=0; i<slots; i++)
    {
        NSString *ipAdd = devAddrArr[i];
        NSArray * strArray = [ipAdd componentsSeparatedByString:@":"];
        NSString *retPing = [self executePingCommand:strArray[0]];
        if ([retPing rangeOfString:@"100.0% packet loss"].location != NSNotFound)
        {
            NSLog(@"%@",retPing);
            //m_status = -1;
            //[self.m_Clients setObject:@"null" forKey:[NSString stringWithFormat:@"slot%d",i]];
            //continue;
            return -1;
        }
        
        for (int j=0; j<= retries; j++)
        {
            RPCClientWrapper *m_Client = [RPCClientWrapper initWithStringEndpoint:[NSString stringWithFormat:@"tcp://%@",devAddrArr[i]]];
            
            /*[ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%@",devAddrArr[i]] forKey:kRPCClientRequester];
            NSArray *tmpArr = [devAddrArr[i] componentsSeparatedByString:@":"];
            NSString *receiver = [NSString stringWithFormat:@"%@:1%@",tmpArr[0],tmpArr[1]];
            [ENDPOINT setValue:[NSString stringWithFormat:@"tcp://%@",receiver] forKey:kRPCClientReceiver];
            RPCClientWrapper *m_Client = [RPCClientWrapper initWithEndpoint:ENDPOINT];
             */
            if (m_Client)
            {
                //m_status ++;
                //[self.m_Clients addObject:m_Client];
                [self.m_Clients setObject:m_Client forKey:[NSString stringWithFormat:@"slot%d",i]];
                break;
            }
            else
            {
                 [self.m_Clients setObject:@"null" forKey:[NSString stringWithFormat:@"slot%d",i]];
            }
            usleep(1000*interval_ms);
        }
    }

    //[self uartShutdown:1];
    [self syncXavierClock];
    //return m_status;
    return 0;
}

-(NSString *)stringMatch:(NSString *)str withCount:(int)count
{
    NSArray *results = [regular matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSString * val = @"0";
    int i= 0;
    for(NSTextCheckingResult *result in results)
    {
        val = [str substringWithRange:result.range];
        if (i == count)
        {
            break;
        }
        i++;
    }
    return val;
}

- (void)syncXavierClock
{
    NSString *expPath = @"/Users/gdlocal/Library/Atlas2/supportFiles/syncXavierClock.exp";
     if ([[NSFileManager defaultManager] fileExistsAtPath:expPath])
     {
         system("/usr/bin/expect /Users/gdlocal/Library/Atlas2/supportFiles/syncXavierClock.exp");
            sleep(0.5);
         
     }
   
}

-(BOOL)isPureInt:(NSString *)string
{
    NSScanner *scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val]&&[scan isAtEnd];
}

-(BOOL)isPureFloat:(NSString *)string
{
    NSScanner *scan = [NSScanner scannerWithString:string];
    float val;
    return [scan scanFloat:&val]&&[scan isAtEnd];
}

-(NSString *)WriteReadString:(NSString *)cmd atSite:(int)site timeOut:(int)timeout
{

    if (![self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",site]] || [[self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",site]] isEqualTo:@"null"])
    {
        return @"init error";
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
        return @"command format error\r\n";
    }
    
    NSString *method = arrCmd[0];
    NSString * strArgs = [arrCmd[1] stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSArray *arrArgs = [strArgs componentsSeparatedByString:@","];
  
    NSMutableDictionary* dicKwargs = [NSMutableDictionary dictionary];
    [dicKwargs setObject:@(timeout) forKey:@"timeout_ms"];
    NSString *rpc_args = [arrArgs componentsJoinedByString:@" "];
    NSLog(@"[rpc_client] %@ %@  . Method: %@, args: %@, kwargs: nil,timeout_ms: %d",method,rpc_args,method,strArgs,timeout);
    
    NSError *error = nil;
    id rtn = nil;
    
    if ([[arrArgs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] )
    {
        arrArgs = nil;
        rtn = [[self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",site]] rpc:method args:arrArgs kwargs:dicKwargs error:&error];
    }
    else
    {
        
        NSMutableArray *args = [NSMutableArray array];
        for (NSString *str in arrArgs)
        {
            if ([self isPureInt:str])
            {
                [args addObject:[NSNumber numberWithInt:[str intValue]]];
            }
            else if ([self isPureFloat:str])
            {
                [args addObject:[NSNumber numberWithFloat:[str floatValue]]];
            }
            else
            {
                [args addObject:str];
            }
            
        }
        
        rtn = [[self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",site]] rpc:method args:args kwargs:dicKwargs error:&error];

    }
    /*id rtn = [self.m_Clients[site] rpc:method args:arrArgs kwargs:dicKwargs];
    NSString* receiver = [NSString stringWithFormat:@"%@",rtn];
     */
    
    NSString* receiver = [NSString stringWithFormat:@"%@",rtn];
    if (error)
    {
        receiver = [NSString stringWithFormat:@"%@\r\nError:%@",receiver,error];
    }
    return receiver;
}

-(int)getCylinderStatus:(NSString *)cmd
{
    NSString *ret = [self WriteReadString:cmd atSite:0 timeOut:3000];
    if ([ret containsString:@"down"])
    {
        return 0;
    }
    return -1;
}
-(void)uartShutdown:(int)site
{
    NSString *ret = [self WriteReadString:@"uart_SoC.shutdown_all()" atSite:site timeOut:3000];
    NSLog(@"uartShutdown,[cmd]: uart_SoC.shutdown_all, [result]: %@",ret);
    
}

-(int)Close
{

     for (int i=0; i<4; i++)
     {
         if (![self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",i]] || [[self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",i]] isEqualTo:@"null"])
         {
             
         }
         else
         {
             [[self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",i]] shutdown];
         }
     }
         
    return 0;
}

-(NSString*)getHostModel
{
    return [[GeneralConfig instance] macmini_hardware_version];
}

-(NSString*)usb_locationID:(int)index
{
    return [[GeneralConfig instance] locationID:index];
}

- (NSString *)uartPath:(int)index
{
    NSString *devicePath = @"";
    devicePath = [[GeneralConfig instance] uartPath:index];
    return devicePath;
}

-(NSString *)getAndWriteFile:(NSString*)target dest:(NSString*) dest atSite:(int)site timeout:(int) timeout
{
//    if(m_status<0)
//    {
//        return @"init error";
//    }
    
    if (![self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",site]] || [[self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",site]] isEqualTo:@"null"])
    {
        return @"init error";
    }
    
    if ((NULL==target)||(NULL==dest)) {

        return @"Error:not define target or destination";
    }
    int iTime = (timeout < 0) ? 0 : timeout;
    NSString* filePath = [dest stringByDeletingPathExtension];
    if (![[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager]createFileAtPath:dest contents:nil attributes:nil];
    }

    NSError *error = nil;
    [[self.m_Clients valueForKey:[NSString stringWithFormat:@"slot%d",site]] getAndWriteFile:target intoDestFile:dest withTimeoutInMS:iTime error:&error];
    NSString *receiver = @"PASS";
    if (error)
    {
        receiver = [NSString stringWithFormat:@"%@\r\n..Error:%@",receiver,error];
    }
    return receiver;
}

//-(void)dealloc
//{
//    [ENDPOINT release];
//    [NON_EXISTING_ENDPOINT release];
//    [super dealloc];
//}

@end
