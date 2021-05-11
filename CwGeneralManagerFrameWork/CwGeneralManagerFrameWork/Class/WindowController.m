//
//  WindowController.m
//  SC_CPK
//
//  Created by Louis Luo on 2020/4/5.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import "WindowController.h"
#import "TabViewController.h"
@interface WindowController ()

@end

@implementation WindowController

-(void)cw_addViewController:(NSViewController *)testVC{
    self.contentViewController = testVC;
    
}

-(void)cw_addViewController:(NSViewController *)testVC logVC:(NSViewController *)logVC{
    if (logVC) {
        NSSplitViewController *splitVC = [[NSSplitViewController alloc]init];
        [splitVC.splitView setVertical:NO];
        splitVC.splitView .dividerStyle=3;
        
        NSSplitViewItem *item1 = [NSSplitViewItem splitViewItemWithViewController:testVC];
        
        NSSplitViewItem *item2 = [NSSplitViewItem splitViewItemWithViewController:logVC];
        [item2 setCollapsed:YES];
        [splitVC addSplitViewItem:item1];
        [splitVC addSplitViewItem:item2];
        
        self.contentViewController = splitVC;
    }else{
        self.contentViewController = testVC;
    }
    
}

-(void)cw_addViewControllers:(NSArray <NSViewController *> *)testVCs{
    [self cw_addViewControllers:testVCs logVC:nil];
    
}

-(void)cw_addViewControllers:(NSArray <NSViewController *> *)testVCs logVC:(NSViewController *)logVC{
    if (logVC != nil) {
        NSSplitViewController *splitVC = [[NSSplitViewController alloc]init];
        [splitVC.splitView setVertical:NO];
        splitVC.splitView .dividerStyle=3;
        if (!testVCs.count) {
            return;
        }
        
        NSTabViewController *tabVC=nil;
        if (testVCs.count==1) {
            self.contentViewController = testVCs[0];
            return;
        }else{
            tabVC = [[NSTabViewController alloc]init];
            for (int i =0; i<testVCs.count; i++) {
                NSViewController *vc = testVCs[i];
                [tabVC addChildViewController:vc];
            }
            
        }
        NSSplitViewItem *item1 = [NSSplitViewItem splitViewItemWithViewController:tabVC];
        
        NSSplitViewItem *item2 = [NSSplitViewItem splitViewItemWithViewController:logVC];
        [splitVC addSplitViewItem:item1];
        [splitVC addSplitViewItem:item2];
        
        self.contentViewController = splitVC;
        
    }else{
        if (!testVCs.count) {
            return;
        }
        if (testVCs.count==1) {
            self.contentViewController = testVCs[0];
        }else{
            TabViewController *tabVC = [[TabViewController alloc]init];
            
            for (int i =0; i<testVCs.count; i++) {

                NSViewController *vc = testVCs[i];

                [tabVC addChildViewController:vc];
                
                if (i==0) {
                    tabVC.view.frame =vc.view.bounds;
                }

            }
            
            NSLog(@"%@",NSStringFromRect(tabVC.view.frame)) ;
            

            
            self.contentViewController = tabVC;
        }
    }
    
}



- (void)windowDidLoad {
    [super windowDidLoad];
    NSDate *date = [NSDate date];
    NSDate * buildTime = (NSDate *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CustomBundleTime"];
    NSTimeInterval timeInterval = [buildTime timeIntervalSinceNow];
    if (!([date.description containsString:@"2021"] || [date.description containsString:@"2022"])) {
        [NSApp terminate:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (void)windowWillClose:(NSNotification *)notification {
    id obj = notification.object;
    NSString *title =[obj title];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    // app名称
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleName"];
    if (obj == [NSApp mainWindow] && [title containsString:app_Name]) {
        [NSApp terminate:nil];
    }
//    if ([title length]) {
//        [NSApp terminate:nil];
//    }
}
@end
