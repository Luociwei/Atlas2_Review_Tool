//
//  WindowController.h
//  SC_CPK
//
//  Created by Louis Luo on 2021/4/5.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface WindowController : NSWindowController

-(void)cw_addViewController:(NSViewController *)testVC;
-(void)cw_addViewController:(NSViewController *)testVC logVC:(NSViewController *)logVC;
-(void)cw_addViewControllers:(NSArray <NSViewController *> *)testVCs;
-(void)cw_addViewControllers:(NSArray <NSViewController *> *)testVCs logVC:(NSViewController *)logVC;
- (void)windowWillClose:(NSNotification *)notification;
@end

NS_ASSUME_NONNULL_END
