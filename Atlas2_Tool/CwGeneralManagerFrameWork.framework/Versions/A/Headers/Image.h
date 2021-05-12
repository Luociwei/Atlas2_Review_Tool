//
//  Image.h
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/1/17.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
NS_ASSUME_NONNULL_BEGIN

@interface Image : NSObject
+(NSImage *)cw_getRecycleImage;
+(NSImage *)cw_getRedCircleImage;
+(NSImage *)cw_getGrayCircleImage;
+(NSImage *)cw_getGreenCircleImage;
@end

NS_ASSUME_NONNULL_END
