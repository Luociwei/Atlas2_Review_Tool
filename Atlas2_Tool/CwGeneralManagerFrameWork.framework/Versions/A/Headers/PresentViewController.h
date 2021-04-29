//
//  ModalViewController.h
//  CPK_Tool
//
//  Created by Louis Luo on 2020/6/24.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PresentViewController : NSViewController
-(void)showViewOnViewController:(NSViewController *)vc;
-(void)dismisssViewOnViewController:(NSViewController *)vc;
-(void)showViewAsSheetOnViewController:(NSViewController *)vc;
-(void)close;

@end

NS_ASSUME_NONNULL_END
