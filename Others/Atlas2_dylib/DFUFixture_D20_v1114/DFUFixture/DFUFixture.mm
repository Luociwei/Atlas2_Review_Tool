//
//  DFUFixture.m
//  DFUFixture
//
//  Created by IvanGan on 16/10/17.
//  Copyright © 2016年 IvanGan. All rights reserved.
//

#import "DFUFixture.h"
#import <Foundation/Foundation.h>
#import "plistParse.h"
#import "CRS232.h"
#import "ErrorCode.h"
#import "USBDevice.h"
#import <mix_rpc_client_framework/mix_rpc_client_framework.h>

#define kRPCClientRequester           @"requester"
#define kRPCClientReceiver            @"receiver"
#define PEP_AUTOMATION_ADDRESS          "tcp://127.0.0.1:3100"
#define kFixtureControl               @"/Users/gdlocal/Config/fixtureControl.txt"
int g_SLOTS = 0;
extern ErrorCode * g_errcode;

NSMutableDictionary * cmd;
NSMutableArray * ENDPOINTS;

//CRS232 * rs232_1 = new CRS232();
//CRS232 * rs232_2 = new CRS232();
//CRS232 * rs232_3 = new CRS232();
//CRS232 * rs232_4 = new CRS232();
//CRS232 * rs232_5 = new CRS232();
//CRS232 * rs232_6 = new CRS232();
//CRS232 * rs232_7 = new CRS232();
//CRS232 * rs232_8 = new CRS232();

//CRS232 * rs232Arr[] = {rs232_1,rs232_2,rs232_3,rs232_4,rs232_5,rs232_6,rs232_7,rs232_8};
//CRS232 * rs232Arr_Fixture1[] = {rs232_1,rs232_2,rs232_3,rs232_4};
//CRS232 * rs232Arr_Fixture2[] = {rs232_5,rs232_6,rs232_7,rs232_8};
//NSMutableDictionary * m_Clients = [[NSMutableDictionary alloc]init];
NSMutableArray * m_Clients;
RPCClientWrapper* m_Client1;

NSDictionary* ENDPOINT = @{@"requester":@"tcp://127.0.0.1:5556", @"receiver":@"tcp://127.0.0.1:15556"};
NSString *supportFilesPath =@"/Users/gdlocal/Library/Atlas/supportFiles/";
NSString *DFUFixtureLogPath =[supportFilesPath stringByAppendingPathComponent:@"DFUFixtureLog.txt"];
NSString *rpc_commandPath =[supportFilesPath stringByAppendingPathComponent:@"rpc_command.plist"];
NSString *DFUFixtureCmdPath =[supportFilesPath stringByAppendingPathComponent:@"DFUFixtureCmd.plist"];
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

void writeToLogFile(NSString *log){
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:DFUFixtureLogPath]) {
        
        [fileManager createFileAtPath:DFUFixtureLogPath contents:nil attributes:nil];
    }
    
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:DFUFixtureLogPath];
    
    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@\n",log]  dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
    
}

//void printFuncName(){
//    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
//    writeToLogFile(funcName);
//
//}

const char* rpc_client(const char* command,int timeout,RPCClientWrapper *m_Client)
{
    
    NSString *cmd = [NSString stringWithUTF8String:command];
    writeToLogFile([NSString stringWithFormat:@"send:%@",cmd]);
    
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
    //    if ([arrCmd count]<2)
    //    {
    //        NSString *err = @"command format error\r\n";
    //        if(CPubliser::m_socket)
    //        {
    //            Pulish((void *)[err UTF8String], [err length]);
    //        }
    //        return [err UTF8String];
    //    }
    //    NSString *file=@"/Users/gdlocal/Library/Atlas/supportFiles/rpc_command.plist";
    //    NSString *file =[supportFilesPath stringByAppendingPathComponent:@"rpc_command.plist"];
    ////    NSString *file = [[NSBundle mainBundle]pathForResource:@"rpc_command.plist" ofType:nil];
    NSMutableDictionary *dic_rpcCommand = [[NSMutableDictionary alloc] initWithContentsOfFile:rpc_commandPath];
    
    if (!dic_rpcCommand[arrCmd[0]])
    {
        NSString *err = @"command error, not define in rpc_command.plist\r\n";
        
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
    //    if(CPubliser::m_socket)
    //    {
    //        NSString *timeLog = [NSString stringWithFormat:@"[rpc_client] method:%@, args:%@, kwargs:nil, timeout_ms:%d",method,strArgs,timeout];
    //        Pulish((void *)[timeLog UTF8String], [timeLog length]);  //Publish out data to suberscriber.
    //    }
    if ([[arrArgs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]
        )
    {
        arrArgs = nil;
    }
    
    id rtn = [m_Client rpc:method args:arrArgs kwargs:dicKwargs];
    
    
    NSString* receiver = [NSString stringWithFormat:@"%@",rtn];
    
    NSLog(@"receiver:%@",receiver);
    writeToLogFile(receiver);
    //    if(CPubliser::m_socket)
    //    {
    //        NSString * ret = [NSString stringWithFormat:@"[result] %@\r\n",receiver];
    //        Pulish((void *)[ret UTF8String], [ret length]);  //Publish out data to suberscriber.
    //    }
    return [receiver UTF8String];
}

int executeAction(void *controller,NSString * key, int site)
{
    
    if(site<1)
        return -1;
    
    id list = [cmd objectForKey:key];
    RPCClientWrapper * r = nil;//rs232Arr[site-1];
    if (controller==m_Clients) {
        r=m_Clients[site-1];
    }
    
    if (r==nil) {
        return -1;
    }
    
    NSArray * arr = (__bridge NSArray*)list;
    for (int j=0; j<[arr count]; j++) {
        if ([[[arr objectAtIndex:j]uppercaseString] containsString:@"DELAY:"]) {
            NSArray *arryDelay=[[arr objectAtIndex:j] componentsSeparatedByString:@":"];
            if ([[arryDelay[0] uppercaseString] isEqual:@"DELAY"]) {
                [NSThread sleepForTimeInterval:[arryDelay[1] doubleValue]];
            }
        }
        else
        {
            for (int i=0; i<1; i++) {
                // const char * u1= r->WriteReadString([[arr objectAtIndex:j]UTF8String], 1000);
                const char * u1=  rpc_client([[arr objectAtIndex:j]UTF8String], 1000, r);
                NSString *u2=[NSString stringWithUTF8String:u1];
                if ([u2.uppercaseString containsString:@"DONE"]) {
                    break;
                }
                [NSThread sleepForTimeInterval:0.1];
            }
        }
        
    }
    return 0;
}

/////////////////////////////////////////////////////
int executeAllAction(void *controller,NSString * key)
{
    for(int i=0; i<g_SLOTS; i++)
    {
        executeAction(controller,key, i+1);
    }
    
    return 0;
}
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

void* create_fixture_controller1(int index){
    [[NSFileManager defaultManager] removeItemAtPath:DFUFixtureLogPath error:nil];
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    
    if(!cmd){
        cmd = [[NSMutableDictionary alloc]init];
        [cmd setDictionary:[plistParse readAllCmdsWithFile:DFUFixtureCmdPath]];
        if([cmd count]>0)
            g_SLOTS = [[cmd objectForKey:kFIXTURESLOTS]intValue];
    }
    NSDictionary *ENDPOINT1 = @{@"requester":@"tcp://169.254.1.32:7805", @"receiver":@"tcp://169.254.1.32:17805"};
    RPCClientWrapper *m_Client = [RPCClientWrapper initWithEndpoint:ENDPOINT1];
    
    m_Client1 = m_Client;
    //    reset(m_Client1);
    //    NSString *reply = [m_Client isServerReady];
    //    writeToLogFile([NSString stringWithFormat:@"slot:%d---isServerReady:%@",1,reply]);
    return nil;
    
}


void* create_fixture_controller(int index){
    
    
    //DFUFixtureLogPath
    [[NSFileManager defaultManager] removeItemAtPath:DFUFixtureLogPath error:nil];
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    if(!cmd){
        cmd = [[NSMutableDictionary alloc]init];
        [cmd setDictionary:[plistParse readAllCmdsWithFile:[supportFilesPath stringByAppendingPathComponent:@"DFUFixtureCmd.plist"]]];
        if([cmd count]>0)
            g_SLOTS = [[cmd objectForKey:kFIXTURESLOTS]intValue];
    }
    
    //    cmd setObject:(nonnull id) forKey:(nonnull id<NSCopying>)
    // [cmd setDictionary:[plistParse parsePlist:@"/usr/local/lib/DFUFixtureCmd.plist"]];
    //[cmd setDictionary:dic];
    
    if (!ENDPOINTS) {
        NSString *ip = @"169.254.1.32";
        NSString *port = @"7801";
        //        NSString *path =[[NSBundle mainBundle]pathForResource:@"EndPoints.plist" ofType:nil];
        //        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:path];
        //
        //        if (dic) {
        //            if ([dic objectForKey:@"ip"]) {
        //                ip = [dic objectForKey:@"ip"];
        //            }
        //
        //            if ([dic objectForKey:@"port"]) {
        //                port = [dic objectForKey:@"port"];
        //            }
        //        }
        ENDPOINTS = [[NSMutableArray alloc] init];
        //        m_Clients = [[NSMutableArray alloc]init];
        for (int i =0; i<4; i++) {
            
            NSString *requester = [NSString stringWithFormat:@"tcp://%@:%ld",ip,port.integerValue+i];
            NSString *receiver = [NSString stringWithFormat:@"tcp://%@:1%ld",ip,port.integerValue+i];
            NSMutableDictionary *ENDPOINT = [[NSMutableDictionary alloc] init];
            [ENDPOINT setObject:requester forKey:@"requester"];
            [ENDPOINT setObject:receiver forKey:@"receiver"];
            [ENDPOINTS addObject:ENDPOINT];
            //            RPCClientWrapper *m_Client = [RPCClientWrapper initWithEndpoint:ENDPOINT];
            //            [m_Clients addObject:m_Client];
            
        }
        
    }
    
    if (!m_Clients) {
        m_Clients = [[NSMutableArray alloc]init];
        for (int j =0; j<g_SLOTS; j++) {
            RPCClientWrapper *m_Client = [RPCClientWrapper initWithEndpoint:ENDPOINTS[j]];
            
            //            NSString *reply = [m_Client isServerReady];
            //            NSLog(@"slot:%d---isServerReady:%@",j+1,reply);
            //            writeToLogFile([NSString stringWithFormat:@"slot:%d---isServerReady:%@",j+1,reply]);
            
            [m_Clients addObject:m_Client];
        }
        
    }
    
    
    if (m_Clients.count ==4) {
        return m_Clients;
    }
    
    return nil;
    
}

void release_fixture_controller(void* controller)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    [m_Clients removeAllObjects];
    m_Clients = nil;
    //    m_Client = nil;
    //    if(cmd)
    //        [cmd removeAllObjects];
    //
    //    if (controller==rs232Arr_Fixture1)
    //    {
    //        for (int i=0; i<4; i++) {
    //            rs232Arr_Fixture1[i]->Close();
    //        }
    //    }
    //    else if(controller==rs232Arr_Fixture2)
    //    {
    //        for (int i=0; i<4; i++) {
    //            rs232Arr_Fixture2[i]->Close();
    //        }
    //    }
    
    //for (int i=0; i<g_SLOTS; i++) {
    /*for (int i=0; i<4; i++) {
     rs232Arr[i]->Close();
     }*/
}



const char * const get_vendor()
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    id obj = [cmd objectForKey:kVENDER];
    if(obj)
        return [obj UTF8String];
    else
        return "Suncode";
    //    return "Suncode";
}


const char * const get_serial_number(void* controller)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    id obj = [cmd objectForKey:kSERIAL];
    if(obj)
        return [obj UTF8String];
    else
        return "TBD";
    //    return "TBD";
}

const char * const get_carrier_serial_number(void* controller, int site)
{
    
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    NSString *str=[NSString stringWithFormat:@"fixture1_%d",site];
    return [str UTF8String];
    //    NSString *str=@"";
    //    if (controller==rs232Arr_Fixture1) {
    //        str=[NSString stringWithFormat:@"fixture1_%d",site];
    //        return [str UTF8String];
    //    }
    //    else if (controller==rs232Arr_Fixture2) {
    //        str=[NSString stringWithFormat:@"fixture2_%d",site];
    //        return [str UTF8String];
    //    }
    
}

const char* const get_error_message(int status)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    if(g_errcode)
        return [g_errcode getErrorMsg:status];
    else
        return "Invalide ErroCode center";
}

const char* const get_version(void* controller)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    
    id obj = [cmd objectForKey:kVERSION];
    
    if(obj)
        return [obj UTF8String];
    else
        return "0.1";
}

int init(void* controller)
{
    
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return executeAllAction(controller,kINIT);
}

int reset(void* controller)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return executeAllAction(controller,kRESET);
}

int get_site_count(void* controller)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return 4;//g_SLOTS;
}

int get_actuator_count(void* controller)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return 4;//g_SLOTS;
}

const char* get_usb_location(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return "site should be from 1";
    //    if(site<1)
    //        return "site should be from 1";
    //
    ////    if (controller==rs232Arr_Fixture2) {
    ////        site+=4;
    ////    }
    //
    //    id usb = [cmd objectForKey:kUSBLOCATION];
    //    if(usb)
    //    {
    //        id str = [(NSDictionary*)usb objectForKey:[NSString stringWithFormat:@"UUT%d",site-1] ];
    //        if(str)
    //            return [str UTF8String];
    //        return nil;
    //    }
    //    return nil;
}

const char* get_uart_path(void* controller, int site){
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return "get_uart_path";
}
//{
//    if(site<1)
//        return "site should be from 1";
//    [NSThread sleepForTimeInterval:3];
//    NSMutableArray* uartSerialArray = [NSMutableArray array];
//    NSMutableArray* uartSerialArray_sub1 = [NSMutableArray array];
//    NSMutableArray* uartSerialArray_sub2 = [NSMutableArray array];
//    NSMutableArray* uartSerialLocation = [NSMutableArray array];
//
////    if (controller==rs232Arr_Fixture2) {
////        site+=4;
////    }
//
//    NSArray *array=[USBDevice getAllAttachedDevices];
//    for (id myindex in [array valueForKey:@"DeviceFriendlyName"]) {
//        //if ([myindex[0] containsString:@"Serial Converter"]) {
//        if ([myindex[0] containsString:@"RS232-HS"]) {
//            int j=[myindex[1] intValue];
//            [uartSerialArray addObject:array[j]];
//            NSString *str=[[array[j] valueForKey:@"LocationID"][0] substringWithRange:NSMakeRange(0,6)];
//            [uartSerialLocation addObject:str];
//        }
//    }
//    //remove duplicate
//
//    NSSet *set = [NSSet setWithArray:uartSerialLocation];
//    [uartSerialLocation addObject:[set allObjects]];
//    NSArray *uartSerialLocationArray =[set allObjects];
//
//
//
//
//    for (id usbSerialArray_sub in uartSerialArray) {
//        NSString *str=[usbSerialArray_sub valueForKey:@"LocationID"][0];
//        if ([str containsString:uartSerialLocationArray[0]]) {
//            [uartSerialArray_sub1 addObject:[usbSerialArray_sub valueForKey:@"SerialNumber"]];
//        }
//    }
//    for (id usbSerialArray_sub in uartSerialArray) {
//        NSString *str=[usbSerialArray_sub valueForKey:@"LocationID"][0];
//        if ([str containsString:uartSerialLocationArray[1]]) {
//            [uartSerialArray_sub2 addObject:[usbSerialArray_sub valueForKey:@"SerialNumber"]];
//        }
//    }
//
//
//    //sort K->A
//    [uartSerialArray_sub1 sortUsingComparator:^NSComparisonResult(__strong id obj1,__strong id obj2){
//        NSString *str1=(NSString *)obj1;
//        NSString *str2=(NSString *)obj2;
//        return [str2 compare:str1];
//    }];
//
//    [uartSerialArray_sub2 sortUsingComparator:^NSComparisonResult(__strong id obj1,__strong id obj2){
//        NSString *str1=(NSString *)obj1;
//        NSString *str2=(NSString *)obj2;
//        return [str2 compare:str1];
//    }];
//
//    NSString *uartPath=@"";
//    NSString *pp=@"";
//    switch (site)
//    {
//        case 1:
//            pp =@"A";break;
//        case 2:
//            pp =@"B";break;
//        case 3:
//            pp =@"C";break;
//        case 4:
//            pp =@"D";break;
//        case 5:
//            pp =@"A";break;
//        case 6:
//            pp =@"B";break;
//        case 7:
//            pp =@"C";break;
//        case 8:
//            pp =@"D";break;
//        default:
//            break;
//
//    }
//
//
//    if ([uartSerialArray_sub1[0] containsString:@"MCUA"]) {
//        if ([@"1234" containsString:[NSString stringWithFormat:@"%d", site]])
//        {
//            if ([uartSerialArray_sub1 count]<2) {
//                return nil;
//            }
//            uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub1[1],pp];
//        }
//
//    }
//
//    if ([uartSerialArray_sub1[0] containsString:@"MCUB"]) {
//        if ([@"5678" containsString:[NSString stringWithFormat:@"%d", site]])
//        {
//            if ([uartSerialArray_sub1 count]<2) {
//                return nil;
//            }
//            uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub1[1],pp];
//        }
//    }
//
//    if ([uartSerialArray_sub2[0] containsString:@"MCUA"]) {
//        if ([@"1234" containsString:[NSString stringWithFormat:@"%d", site]])
//        {
//            if ([uartSerialArray_sub2 count]<2) {
//                return nil;
//            }
//            uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub2[1],pp];
//        }
//    }
//    if ([uartSerialArray_sub2[0] containsString:@"MCUB"]) {
//        if ([@"5678" containsString:[NSString stringWithFormat:@"%d", site]])
//        {
//            if ([uartSerialArray_sub2 count]<2) {
//                return nil;
//            }
//            uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub2[1],pp];
//        }
//    }
//
//    return [uartPath UTF8String];
//
//
//}

int actuator_for_site(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    if(site<1)
        return -1;
    return site-1;
}

int fixture_engage(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    if(actuator_index<0)
        return -1;
    return 0;
}

int fixture_disengage(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    if(actuator_index<0)
        return -1;
    return 0;
}

int fixture_open(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    // if(actuator_index<0)
    // return -1;
    return 0;
}

int fixture_close(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //return executeAllAction(kINIT);
    // if(actuator_index<0)
    //  return -1;
    return 0;
}


int set_usb_power(void* controller, POWER_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kUSBPOWERON : kUSBPOWEROFF),site);;
    return 1;
}

int set_battery_power(void* controller, POWER_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kBATTERYPOWERON : kBATTERYPOWEROFF),site);
    return 1;
}

int set_usb_signal(void* controller, RELAY_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kUSBSIGNALON : kUSBSIGNALOFF),site);
    return 1;
}

int set_uart_signal(void* controller, RELAY_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kUARTSIGNALON : kUARTSIGNALOFF),site);
    return 1;
}

int set_apple_id(void* controller, RELAY_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kAPPLEIDON : kAPPLEIDOFF),site);
    return 1;
}

int set_conn_det_grounded(void* controller, RELAY_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kCONNDETGNDON : kCONNDETGNDOFF),site);
    return 1;
}

int set_hi5_bs_grounded(void* controller, RELAY_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kHI5ON : kHI5OFF),site);
    return 1;
}

int set_dut_power(void* controller, POWER_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kDUTPOWERON : kDUTPOWEROFF),site);
    return 1;
}

int set_dut_power_all(void* controller, POWER_STATE action)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAllAction(controller,(action==0 ? kDUTPOWERON : kDUTPOWEROFF));
    return 1;
}

int set_force_dfu(void* controller, POWER_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kFORCEDFUON : kFORCEDFUOFF), site);
    return 1;
}

int set_force_diags(void* controller, POWER_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kFORCEDIAGSON : kFORCEDIAGSOFF), site);
    return 1;
}

int set_force_iboot(void* controller, POWER_STATE action, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    return executeAction(controller,(action==0 ? kFORCEIBOOTON : kFORCEIBOOTOFF), site);
    return 1;
}

int set_led_state(void* controller, LED_STATE action, int site){
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return 1;
}
//{
//    if (site<1)
//        return -1;
//
//    NSString * key = kOFF;
//    switch (action) {
//        case PASS:
//            key = kPASS;
//            break;
//        case FAIL:
//            key = kFAIL;
//            break;
//        case INPROGRESS:
//            key = kINPROCESS;
//            break;
//        case FAIL_GOTO_FA:
//            key = kFAILGOTOFA;
//            break;
//        case PANIC:
//            key = kPANIC;
//            break;
//        default:
//            break;
//    }
//    id list = [cmd objectForKey:kLEDSTATE];
//    if(list)
//    {
//        id cmdArr = [(NSDictionary*)list objectForKey:key];
//
//
//
//        if(cmdArr)
//        {
//            NSArray * arr = (NSArray*)cmdArr;
//
//            CRS232 * r = nil;//rs232Arr[site-1];
//            if (controller==rs232Arr_Fixture1) {
//                r=rs232Arr_Fixture1[site-1];
//            }
//            else if (controller==rs232Arr_Fixture2)
//            {
//                r=rs232Arr_Fixture2[site-1];
//            }
//            if (r==nil) {
//                return -1;
//            }
//
//            for (int j=0; j<[arr count]; j++)
//                r->WriteReadString([[arr objectAtIndex:j]UTF8String], 1000);
//        }
//    }
//    return 0;
//}
int set_led_state_all(void* controller, LED_STATE action)
{
    //for (int i=0; i<g_SLOTS; i++) {
    //    for (int i=0; i<4; i++) {
    //        set_led_state(controller, action, i+1);
    //    }
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return 0;
}

//************* section:status functions *******************
//when the actuator is in motion and not yet settled, neither is_engage nor is_disengage should return true
bool is_fixture_engaged(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return YES;
}

bool is_fixture_disengaged(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return YES;
}

bool is_fixture_closed(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return YES;
}

bool is_fixture_open(void* controller, int actuator_index)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return YES;
}

POWER_STATE usb_power(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return TURN_ON;
}
POWER_STATE battery_power(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return TURN_ON;
}

POWER_STATE force_dfu(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return TURN_ON;
}

RELAY_STATE usb_signal(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return CLOSE_RELAY;
}

RELAY_STATE uart_signal(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return CLOSE_RELAY;
}

RELAY_STATE apple_id(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return CLOSE_RELAY;
}

RELAY_STATE conn_det_grounded(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return CLOSE_RELAY;
}

RELAY_STATE hi5_bs_grounded(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return CLOSE_RELAY;
}

POWER_STATE dut_power(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    return TURN_ON;
}

bool is_board_detected(void* controller, int site)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //    CRS232 * r = rs232Arr[site-1];
    //    const char *u=r->WriteReadString("READ INPUT:A", 1000);
    //    NSString *str=[NSString stringWithCString:u encoding:NSUTF8StringEncoding];
    //    if ([str containsString:@"Read Input A:0"]) {
    //        return YES;
    //    }
    //
    //    return NO;
    return YES;
    
}


void setup_event_notification(void* controller, void* event_ctx, fixture_event_callback_t on_fixture_event, stop_event_notfication_callback_t on_stop_event_notification)
{
    NSString *funcName = [NSString stringWithFormat:@"-----------%s-----------",__func__];
    writeToLogFile(funcName);
    //NSLog(@"===call back:==");
    
    /*if (controller == NULL || event_ctx == NULL ||
     on_fixture_event == NULL || on_stop_event_notification == NULL)
     {
     NSLog(@"setup_event_notification error: parameter error!");
     return;
     }
     NSLog(@"===call back 2:==");*/
    
    
    //
    //    if (controller==rs232Arr_Fixture1)
    //    {
    //        for (int i=0; i<4; i++) {
    //            NSLog(@"----do callback fixture 1--");
    //            rs232Arr_Fixture1[i]->Set_Event_Callback(on_fixture_event,rs232Arr_Fixture1,event_ctx,i+1);
    //            rs232Arr_Fixture1[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
    //
    //        }
    //    }
    //    if (controller==rs232Arr_Fixture2)
    //    {
    //        for (int i=0; i<4; i++) {
    //            NSLog(@"----do callback fixture 2--");
    //            rs232Arr_Fixture2[i]->Set_Event_Callback(on_fixture_event,rs232Arr_Fixture2,event_ctx,i+1);
    //            rs232Arr_Fixture2[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
    //
    //        }
    //    }
    //
    
    /*dispatch_async(dispatch_get_main_queue(), ^{
     do{
     for (int i=0; i<4; i++) {
     
     NSDictionary *chInfo = @{@"FixtureID":[NSString stringWithFormat:@"%d", 1],
     @"chNum":[NSString stringWithFormat:@"%d", i+1],
     @"EventMsg":[NSString stringWithFormat:@"%s",event_ctx]};
     NSString *eventMsg = (NSString *)[chInfo objectForKey:@"EventMsg"];
     //int fid = [(NSString *)[chInfo objectForKey:@"FixtureID"] intValue];
     if (controller==rs232Arr_Fixture1)
     {
     rs232Arr_Fixture1[i]->Set_Event_Callback(on_fixture_event,event_ctx,i+1);
     rs232Arr_Fixture1[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
     [NSThread sleepForTimeInterval:0.5];
     
     if([rs232Arr_Fixture1[i]->start_flag containsString:@"1"])
     {
     rs232Arr_Fixture1[i]->start_flag=@"0";
     [[NSNotificationCenter defaultCenter] postNotificationName:eventMsg object:chInfo];
     //rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,i+1,0);
     rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,-1,0);
     NSLog(@"----do callback fixture 1--");
     break;
     }
     }
     else if (controller==rs232Arr_Fixture2)
     {
     rs232Arr_Fixture2[i]->Set_Event_Callback(on_fixture_event,event_ctx,i+1);
     rs232Arr_Fixture2[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
     [NSThread sleepForTimeInterval:0.5];
     
     if([rs232Arr_Fixture2[i]->start_flag containsString:@"1"])
     {
     rs232Arr_Fixture2[i]->start_flag=@"0";
     [[NSNotificationCenter defaultCenter] postNotificationName:eventMsg object:chInfo];
     //rs232Arr_Fixture2[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture2[i]->m_event_context,i+1,0);
     rs232Arr_Fixture2[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture2[i]->m_event_context,-1,0);
     NSLog(@"----do callback fixture 2--");
     break;
     }
     
     }
     
     
     }
     }while(1);
     });*/
    
    /*
     if (controller==rs232Arr_Fixture1)
     {
     dispatch_async(dispatch_get_main_queue(), ^{
     do{
     for (int i=0; i<4; i++) {
     
     NSDictionary *chInfo = @{@"FixtureID":[NSString stringWithFormat:@"%d", 1],
     @"chNum":[NSString stringWithFormat:@"%d", i+1],
     @"EventMsg":[NSString stringWithFormat:@"%s",event_ctx]};
     NSString *eventMsg = (NSString *)[chInfo objectForKey:@"EventMsg"];
     //int fid = [(NSString *)[chInfo objectForKey:@"FixtureID"] intValue];
     rs232Arr_Fixture1[i]->Set_Event_Callback(on_fixture_event,event_ctx,i+1);
     rs232Arr_Fixture1[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
     [NSThread sleepForTimeInterval:0.5];
     
     if([rs232Arr_Fixture1[i]->start_flag containsString:@"1"])
     {
     NSLog(@"----do callback fixture 1--");
     rs232Arr_Fixture1[i]->start_flag=@"0";
     [[NSNotificationCenter defaultCenter] postNotificationName:eventMsg object:chInfo];
     //rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,i+1,0);
     rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,-1,0);
     
     break;
     }
     }
     }while(1);
     });
     
     }
     else if (controller==rs232Arr_Fixture2)
     {
     dispatch_async(dispatch_get_main_queue(), ^{
     do{
     for (int i=0; i<4; i++) {
     
     NSDictionary *chInfo = @{@"FixtureID":[NSString stringWithFormat:@"%d", 2],
     @"chNum":[NSString stringWithFormat:@"%d", i+1],
     @"EventMsg":[NSString stringWithFormat:@"%s",event_ctx]};
     NSString *eventMsg = (NSString *)[chInfo objectForKey:@"EventMsg"];
     //int fid = [(NSString *)[chInfo objectForKey:@"FixtureID"] intValue];
     rs232Arr_Fixture2[i]->Set_Event_Callback(on_fixture_event,event_ctx,i+1);
     rs232Arr_Fixture2[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
     [NSThread sleepForTimeInterval:0.5];
     
     if([rs232Arr_Fixture2[i]->start_flag containsString:@"1"])
     {
     NSLog(@"----do callback fixture 2--");
     rs232Arr_Fixture2[i]->start_flag=@"0";
     [[NSNotificationCenter defaultCenter] postNotificationName:eventMsg object:chInfo];
     //rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,i+1,0);
     rs232Arr_Fixture2[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,-1,0);
     
     break;
     }
     }
     }while(1);
     });
     
     }
     */
    /*  dispatch_async(dispatch_get_main_queue(), ^{
     if (controller==rs232Arr_Fixture1)
     {
     
     do{
     for (int i=0; i<4; i++) {
     
     NSDictionary *chInfo = @{@"FixtureID":[NSString stringWithFormat:@"%d", 1],
     @"chNum":[NSString stringWithFormat:@"%d", i+1],
     @"EventMsg":[NSString stringWithFormat:@"%s",event_ctx]};
     NSString *eventMsg = (NSString *)[chInfo objectForKey:@"EventMsg"];
     //int fid = [(NSString *)[chInfo objectForKey:@"FixtureID"] intValue];
     rs232Arr_Fixture1[i]->Set_Event_Callback(on_fixture_event,event_ctx,i+1);
     rs232Arr_Fixture1[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
     [NSThread sleepForTimeInterval:0.5];
     
     if([rs232Arr_Fixture1[i]->start_flag containsString:@"1"])
     {
     NSLog(@"----do callback fixture 1--");
     rs232Arr_Fixture1[i]->start_flag=@"0";
     [[NSNotificationCenter defaultCenter] postNotificationName:eventMsg object:chInfo];
     //rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,i+1,0);
     rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,-1,0);
     
     break;
     }
     }
     }while(1);
     
     
     }
     if (controller==rs232Arr_Fixture2)
     {
     
     do{
     for (int i=0; i<4; i++) {
     
     NSDictionary *chInfo = @{@"FixtureID":[NSString stringWithFormat:@"%d", 2],
     @"chNum":[NSString stringWithFormat:@"%d", i+1],
     @"EventMsg":[NSString stringWithFormat:@"%s",event_ctx]};
     NSString *eventMsg = (NSString *)[chInfo objectForKey:@"EventMsg"];
     //int fid = [(NSString *)[chInfo objectForKey:@"FixtureID"] intValue];
     rs232Arr_Fixture2[i]->Set_Event_Callback(on_fixture_event,event_ctx,i+1);
     rs232Arr_Fixture2[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
     [NSThread sleepForTimeInterval:0.5];
     
     if([rs232Arr_Fixture2[i]->start_flag containsString:@"1"])
     {
     NSLog(@"----do callback fixture 2--");
     rs232Arr_Fixture2[i]->start_flag=@"0";
     [[NSNotificationCenter defaultCenter] postNotificationName:eventMsg object:chInfo];
     //rs232Arr_Fixture1[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,i+1,0);
     rs232Arr_Fixture2[i]->m_event_CallBack("TBD",0,rs232Arr_Fixture1[i]->m_event_context,-1,0);
     
     break;
     }
     }
     }while(1);
     
     
     }
     
     });
     */
    
    
}

