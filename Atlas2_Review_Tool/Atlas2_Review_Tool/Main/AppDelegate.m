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

@interface AppDelegate ()

@end

@implementation AppDelegate{

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
//    NSApp.windows.firstObject.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    // Insert code here to initialize your application
    
//    self.redis = [[CWRedis alloc] init];
//    [self.redis connect];
//
//    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
//    NSString * pyFile = [resourcePath stringByAppendingPathComponent:@"/Python/pythonProject/main.py"];
//    self.zmqMainPy = [[CWZMQ alloc]initWithURL:@"tcp://127.0.0.1:3100" pythonFile:pyFile];
//
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
    // Insert code here to tear down your application


}



@end
