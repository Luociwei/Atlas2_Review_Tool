//
//  WindowVC.h
//  Atlas2_Review_Tool
//
//  Created by Louis Luo on 2020/3/31.
//  Copyright © 2020 Suncode. All rights reserved.
//


#import "AppDelegate.h"
#import "WindowVC.h"
#define  cpk_zmq_addr           @"tcp://127.0.0.1:3100"
#import "Client.h"
@interface AppDelegate ()

@end

@implementation AppDelegate{
    Client *cpkClient;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    NSApp.windows.firstObject.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    // Insert code here to initialize your application
//    NSString * record_path = @"/Users/ciweiluo/Downloads/ALL_LOG/DLX1383000K1KXX11/20210922_18-40-16.651-D0E083/system/device.log";
//    NSString *logPath = record_path.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
//    NSLog(@"11");
    
    
}
-(int)execute_withTask:(NSString*) szcmd withPython:(NSString *)arg
{
    if (!szcmd) return -1;
    NSTask * task = [[NSTask alloc] init];
    [task setLaunchPath:szcmd];
    [task setArguments:[NSArray arrayWithObjects:arg, nil]];
    [task launch];
    return 0;
}
-(void)Lanuch_cpk
{
    NSString * cmd = @"/Library/Frameworks/Python.framework/Versions/3.8/bin/python3";
    NSString * arg = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PythonTest.py"];
    NSString *logCmd = @"ps -ef |grep -i python |grep -i PythonTest.py |grep -v grep|awk '{print $2}' | xargs kill -9";
    system([logCmd UTF8String]); //杀掉PythonTest.py 进程
    [self execute_withTask:cmd withPython:arg];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
//    system("/usr/bin/ulimit -n 8192");
//    [self Lanuch_cpk];
//    cpkClient = [[Client alloc] init];   // connect CPK zmq for PythonTest.py
//    [cpkClient CreateRPC:cpk_zmq_addr withSubscriber:nil];
//    [cpkClient setTimeout:20*1000];
   
}



@end
