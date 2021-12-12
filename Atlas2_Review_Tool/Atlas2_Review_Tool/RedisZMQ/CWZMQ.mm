//
//  CWZMQ.m
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/12/11.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "CWZMQ.h"
#import "Client.h"
#define  cpk_zmq_addr           @"tcp://127.0.0.1:3100"
@interface CWZMQ ()

@end


@implementation CWZMQ{
    Client *zmqClient;
//    NSString *f
}


-(instancetype)initWithURL:(NSString *)url{
    if (self == [super init]) {
        zmqClient = [[Client alloc] init];   // connect CPK zmq for PythonTest.py
        [zmqClient CreateRPC:url withSubscriber:nil];
        [zmqClient setTimeout:20*1000];
    }
    
    return self;
    
}


-(void)shutdown{
    NSString *logCmd = @"ps -ef |grep -i python |grep -i main.py |grep -v grep|awk '{print $2}' | xargs kill -9";
    system([logCmd UTF8String]); //杀掉PythonTest.py 进程
}



-(void)lanuchPythonFile:(NSString *)filePath{
    
    system("/usr/bin/ulimit -n 8192");
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString * launchPath = [resourcePath stringByAppendingString:@"/Python/NewEnv/pythonProject/bin/python3.10"];
    
    NSString * arg = [resourcePath stringByAppendingPathComponent:@"/Python/pythonProject/main.py"];
    NSString *logCmd = @"ps -ef |grep -i python |grep -i main.py |grep -v grep|awk '{print $2}' | xargs kill -9";
    system([logCmd UTF8String]); //杀掉PythonTest.py 进程
    [self execute_withTask:launchPath withPython:arg];
    
}



-(int)execute_withTask:(NSString*) szcmd withPython:(NSString *)arg{
    
    if (!szcmd) return -1;
    NSTask * task = [[NSTask alloc] init];
    [task setLaunchPath:szcmd];
    [task setArguments:[NSArray arrayWithObjects:arg, nil]];
    [task launch];
    return 0;
}



@end
