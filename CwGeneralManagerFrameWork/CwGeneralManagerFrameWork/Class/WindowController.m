//
//  WindowController.m
//  SC_CPK
//
//  Created by Louis Luo on 2021/4/5.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "WindowController.h"
#import "TabViewController.h"
#import "Alert.h"
@interface WindowController ()

@end

@implementation WindowController

-(void)cw_addViewController:(NSViewController *)testVC{
    self.contentViewController = testVC;
    
}

-(void)cw_addViewController:(NSViewController *)testVC logVC:(NSViewController *)logVC{
    if (logVC) {
        NSSplitViewController *splitVC = [[NSSplitViewController alloc]init];
        [splitVC.splitView setVertical:YES];
        splitVC.splitView .dividerStyle=3;
        
        NSSplitViewItem *item1 = [NSSplitViewItem splitViewItemWithViewController:testVC];
        
        NSSplitViewItem *item2 = [NSSplitViewItem splitViewItemWithViewController:logVC];
        [item2 setCollapsed:NO];
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
//NSDate * buildTime       = (NSDate *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CustomBundleTime"];
//
//NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
//
//// 2014年10月15日 16:35:42
//// stringFromDate 将日期类型格式化，转为NSString 类型
//return [formatter stringFromDate:buildTime];
-(void)awakeFromNib{
    NSDate *date = [NSDate date];
    NSDate * buildTime = (NSDate *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CustomBundleTime"];
//    NSTimeInterval timeInterval = [date timeIntervalSinceDate:buildTime];
//    if (timeInterval > 3600*24*30*10) {
//        [Alert cw_RemindException:@"Warning!!!" Information:@"The version has expired. Please use the latest version!"];
//    }
    if (!([date.description containsString:@"2021"] || [date.description containsString:@"2022"])) {
        [NSApp terminate:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    
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
