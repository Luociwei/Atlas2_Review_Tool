//
//  WindowVC.h
//  Atlas2_Review_Tool
//
//  Created by Louis Luo on 2020/3/31.
//  Copyright © 2020 Suncode. All rights reserved.
//


#import "AppDelegate.h"
#import "WindowVC.h"
//#define  cpk_zmq_addr           @"tcp://127.0.0.1:3100"
#import "CWZMQ.h"
#import "CWRedis.h"
@interface AppDelegate ()

@end

@implementation AppDelegate{

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.test = @"sss";

    AppDelegate * appDelegate = (AppDelegate*)[NSApplication sharedApplication].delegate;
    NSString *log =appDelegate.test;
    NSLog(@"-----%@",log);
//    NSApp.windows.firstObject.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    // Insert code here to initialize your application
//    NSString * record_path = @"/Users/ciweiluo/Downloads/ALL_LOG/DLX1383000K1KXX11/20210922_18-40-16.651-D0E083/system/device.log";
//    NSString *logPath = record_path.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
//    NSLog(@"11");
    
    
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
//    NSApp.windows.firstObject.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    // Insert code here to initialize your application
//    NSString * record_path = @"/Users/ciweiluo/Downloads/ALL_LOG/DLX1383000K1KXX11/20210922_18-40-16.651-D0E083/system/device.log";
//    NSString *logPath = record_path.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
//    NSLog(@"11");
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
    // Insert code here to tear down your application
    [CWRedis shutDown];
    [CWZMQ shutdown];

}



@end
