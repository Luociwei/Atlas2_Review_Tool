//
//  TextView.h
//  MyBase
//
//  Created by Louis Luo on 2020/12/24.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextView : NSView
+(instancetype)cw_allocInitWithFrame:(NSRect)frame;
-(void)showLog:(NSString *)log;
-(void)setPingIpAddress:(NSString *)ip;
-(void)clean;
-(void)searchIpFrom:(NSString *)ip to:(NSInteger)ipRangeCount;
- (void)addItemsToView;
@end

NS_ASSUME_NONNULL_END
