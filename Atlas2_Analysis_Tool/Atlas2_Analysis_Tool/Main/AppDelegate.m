//
//  WindowVC.h
//  Atlas2_Analysis_Tool
//
//  Created by Louis Luo on 2020/3/31.
//  Copyright © 2020 Suncode. All rights reserved.
//


#import "AppDelegate.h"
#import "WindowVC.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSString *systemFile =@"/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/Atlas2_Tool_0504";

    NSArray *pathArr1= [FileManager cw_findPathWithfFileName:@"demo1.jpg" dirPath:systemFile deepFind:YES];
    
        NSArray *pathArr2 = [FileManager cw_findPathWithfFileName:@"demo1.jpg" dirPath:systemFile deepFind:NO];
    
    NSLog(@"11");
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
   
}



@end
