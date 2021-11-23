//
//  TabViewController.h
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TabViewController : NSTabViewController

-(void)addViewControllers:(NSArray<NSViewController *> *)viewControllerArr;
-(void)removeAllChildViewController;

-(void)showViewOnViewController:(NSViewController *)vc;
-(void)dismisssViewOnViewController:(NSViewController *)vc;
-(void)showViewAsSheetOnViewController:(NSViewController *)vc;
-(void)close;
@property BOOL isActive;

@end

NS_ASSUME_NONNULL_END
