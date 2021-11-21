//
//  ModalViewController.h
//  CPK_Tool
//
//  Created by Louis Luo on 2021/6/24.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PresentViewController : NSViewController
-(void)showViewOnViewController:(NSViewController *)vc;
-(void)dismisssViewOnViewController:(NSViewController *)vc;
-(void)showViewAsSheetOnViewController:(NSViewController *)vc;
-(void)close;
@property BOOL isActive;
@end

NS_ASSUME_NONNULL_END
