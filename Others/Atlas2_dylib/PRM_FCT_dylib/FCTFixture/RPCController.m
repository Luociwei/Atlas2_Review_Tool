//
//  RPCController.m
//  FCTFixture
//
//  Created by Kim on 2021/8/16.
//  Copyright © 2021 PRM-JinHui.Huang. All rights reserved.
//

#import "RPCController.h"
#import "PlistReader.h"



void checkIfLogFileExist(NSString *filePath)
{
    NSFileManager *fm = [NSFileManager defaultManager];
//    NSError *error = nil;
    BOOL isExist = [fm fileExistsAtPath:filePath];
    if (!isExist)
    {
        BOOL ret = [fm createFileAtPath:filePath contents:nil attributes:nil];
        if (!ret)
        {
//            [fm createDirectoryAtPath:@"/vault/Atlas/FixtureLog/PRM" withIntermediateDirectories:YES attributes:nil error:&error];
            [fm createFileAtPath:filePath contents:nil attributes:nil];
        }
    }
}

void writeLog2File(NSString * filePath,NSString * testTime ,NSString * str)
{
    NSFileHandle* fh=[NSFileHandle fileHandleForWritingAtPath:filePath];
    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@  %@\r\n",testTime,str] dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

void hwLog(NSString *strContent,int site, NSString *pathLogFile)
{
//    NSLog(@"HW Log: %@", strContent);
    NSDateFormatter* DateFomatter = [[NSDateFormatter alloc] init];
    [DateFomatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS "];
    NSString* timeFlag = [DateFomatter stringFromDate:[NSDate date]];
    if (pathLogFile)
    {
        checkIfLogFileExist(pathLogFile);
        writeLog2File(pathLogFile, timeFlag, strContent);
    }
}


@implementation RPCController
@synthesize rpcClients;
@synthesize logPaths;
@synthesize rpcSendRecvLogs;


-(id)init{
    if (self = [super init]) {
        rpcClients = [[NSMutableArray alloc] init];
        logPaths = [[NSMutableArray alloc] init];
        rpcSendRecvLogs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)createRPCClient:(NSString *)inIP andPort:(NSUInteger)inPort andLogPath:(NSString *)inLogPath
{
    NSLog(@"MIXIP IP:%@", inIP);
    NSLog(@"MIXIP Port:%lu",(unsigned long)inPort);
    RPCClientWrapper *client = [RPCClientWrapper initWithIP:inIP withPort:inPort];
    [rpcClients addObject:client];
    [logPaths addObject:inLogPath];
    [rpcSendRecvLogs addObject:@""];

    NSString *msg = [client isServerReady];
    if ([msg isEqualToString:@"PASS"]) {
        NSError *err = nil;
        id response = [client rpc:@"xavier.set_rtc"
                             args:@[[NSNumber numberWithFloat: [[NSDate date] timeIntervalSince1970]]]
                           kwargs:nil
                            error:&err
                       ];
        NSLog(@"set_rtc: %@", response);
        NSLog(@"Connected to RPC server on %@:%lu successfully...", inIP, inPort);
        return YES;
    }
    else{
        NSLog(@"Instrument RPC Server on  %@:%lu is not ready with error message %@.", inIP, inPort, msg);
        return NO;
    }
}



-(id) rpcCall:(NSString *)command atSite:(int)inSite timeOut:(int)inTimeoutms
{
    rpcSendRecvLogs[inSite] = @"";
    NSArray *arrCmd = nil;
    if ([command containsString:@"]"])
    {
        NSArray *arrSub= [command componentsSeparatedByString:@"]"];
        arrCmd = [arrSub[1] componentsSeparatedByString:@"("];
    }
    else
    {
        arrCmd = [command componentsSeparatedByString:@"("];
    }
    if ([arrCmd count]<2)
    {
        return @"command format error\r\n";
    }
    
    NSString *method = arrCmd[0];
    NSString * strArgs = [arrCmd[1] stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSArray *arrArgs = [strArgs componentsSeparatedByString:@","];
  
    NSMutableDictionary* dicKwargs = [NSMutableDictionary dictionary];
    
    [dicKwargs setObject:@(inTimeoutms) forKey:@"timeout_ms"];
    NSString *rpc_args = [arrArgs componentsJoinedByString:@" "];
    NSString *rpcCommand = [NSString stringWithFormat: @"[rpc_send] %@ %@ timeout_ms=%d",method, rpc_args ,inTimeoutms];
    hwLog(rpcCommand, inSite, logPaths[inSite]);
    NSMutableArray *arrFormatArgs = [NSMutableArray array];
    
    if ([[arrArgs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] )
    {
        arrFormatArgs = nil;
        arrArgs = nil;
    }
    else{
        for (NSString *str in arrArgs) {
            if ([self isInt:str]) {
                int value = [str intValue];
                [arrFormatArgs addObject: [NSNumber numberWithInt:value]];
            }
            else if ([self isFloat:str]){
                float value = [str floatValue];
                [arrFormatArgs addObject:[NSNumber numberWithFloat:value]];
            }
            else if ([[str uppercaseString] hasPrefix:@"0X"] && [self isHex:str]){
                unsigned int value;
                NSScanner *scan = [NSScanner scannerWithString:str];
                [scan scanHexInt: &value];
                [arrFormatArgs addObject:[NSNumber numberWithInt:value]];
            }
            else{
                [arrFormatArgs addObject:str];
            }
        }
    }
    NSError *error = nil;
    id receiver = nil;

    id rtn = [[rpcClients objectAtIndex: inSite] rpc:method
                                                args:[arrFormatArgs copy]
                                              kwargs:dicKwargs
                                               error:&error];

    [rpcSendRecvLogs replaceObjectAtIndex:inSite withObject:[NSString stringWithFormat:@"%@\n[rpc_recv] %@\n", rpcCommand, rtn]];
    if (error)
    {
        receiver = [NSString stringWithFormat:@"[rpc_recv] %@\r\nError:%@\n",rtn,error];
        hwLog(receiver, inSite, logPaths[inSite]);
    }
    else{
        // log specific format {"result":'done", "value":1, "commands":["command1","command2"]
        if ([rtn isKindOfClass:[NSDictionary class]] && [rtn objectForKey:@"result"] && [rtn objectForKey:@"value"] && [rtn objectForKey:@"commands"]) {
            for (NSString *ret in [rtn objectForKey:@"commands"]) {
                hwLog([NSString stringWithFormat:@"[rpc_recv] %@", ret], inSite, logPaths[inSite]);
            }
            if ([method isEqualToString:@"relay.relay"]) {
                hwLog(@"\n\n", inSite, logPaths[inSite]);
                receiver = [NSString stringWithFormat:@"%@", [rtn objectForKey:@"commands"]];
            }
            else{
                receiver = [NSString stringWithFormat:@"%@", [rtn objectForKey:@"value"]];
                hwLog([NSString stringWithFormat:@"[rpc_recv] %@\n\n", receiver], inSite, logPaths[inSite]);
            }
        }
        else{
            if ([rtn isKindOfClass:[NSDictionary class]])
                receiver = rtn;
            else{
                receiver = [NSString stringWithFormat:@"%@", rtn];
            }
            hwLog([NSString stringWithFormat:@"[rpc_recv] %@\n", receiver], inSite, logPaths[inSite]);
        }
    }
    return receiver;
}


-(NSString *)getAndWriteFile:(NSString*)target dest:(NSString*) dest atSite:(int)site timeout:(int) timeout
{
    if ((NULL==target)||(NULL==dest)) {
        
        return @"Error:not define target or destination";
    }
    int iTime = (timeout < 0) ? 1000 : timeout;
    NSString* filePath = [dest stringByDeletingPathExtension];
    if (![[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager]createFileAtPath:dest contents:nil attributes:nil];
    }
    hwLog([NSString stringWithFormat:@"get file from %@ to %@", target, dest], site, logPaths[site]);
    NSError *error = nil;
    id response = [rpcClients[site] rpc:[NSString stringWithFormat:@"fixture.get_file"]
                                    args:@[target]
                                    kwargs:@{@"timeout_ms":[NSNumber numberWithInteger:iTime]}
                                    error:&error
                   ];
    NSString *receiver = @"PASS";
    if (error) {
        receiver = [NSString stringWithFormat:@"%@\r\nError:%@",receiver,error];
    }
    else{
        if ([response[0] isEqualToString:@"PASS"]) {
            NSData *base64Data = [[NSData alloc] initWithBase64EncodedString:response[1] options:0];
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:dest]){
                [fm removeItemAtPath:dest error:nil];
            }
//            [fm createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:nil];
            NSArray *arr = [dest componentsSeparatedByString:@"/"];
            NSString *path = [[arr subarrayWithRange:NSMakeRange(0, [arr count] - 1)] componentsJoinedByString:@"/"];
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            BOOL ret = [base64Data writeToFile:dest atomically:YES];
            if (!ret) {
                receiver = @"create file fail";
            }
        }
        else{
            receiver = response[0];
        }
    }
//    [rpcClients[site] getAndWriteFile:target intoDestFile:dest withTimeoutInMS:iTime error:&error];

    hwLog([NSString stringWithFormat:@"%@\n",receiver], site, logPaths[site]);
    return receiver;
}


-(BOOL)isInt: (NSString *)string{
    NSScanner *scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

-(BOOL)isFloat: (NSString *)string{
    NSScanner *scan = [NSScanner scannerWithString:string];
    float val;
    return [scan scanFloat:&val] && [scan isAtEnd];
}

-(BOOL)isHex: (NSString *)string{
    NSScanner *scan = [NSScanner scannerWithString:string];
    uint val;
    return [scan scanHexInt:&val] && [scan isAtEnd];
}

-(int)close
{
    for (int i=0; i<[self.rpcClients count]; i++)
    {
        [self.rpcClients[i] rpcCall:@"reset.reset()" atSite:i timeOut:5000];
        [self.rpcClients[i] shutdown];
        hwLog(@"Shutdown rpc client\n", i, logPaths[i]);
    }
    return 0;
}

-(void)hwlog: (NSString *) message andSite:(int)site{
    hwLog(message, site, logPaths[site]);
}



-(void)uartShutdown:(int)site
{
    [self rpcCall:@"uart_SoC.shutdown_all()" atSite:site timeOut:3000];
    
}

@end
