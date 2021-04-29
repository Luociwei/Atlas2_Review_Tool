//
//  Image.m
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/1/17.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "Image.h"

@implementation Image

+(NSImage *)getMyBundleImage:(NSString *)imageName{
    NSString *resorcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString *pic_path = [resorcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"CwGeneralManagerBundle.bundle/Contents/Resources/%@",imageName]];
    NSImage *image = [[NSImage alloc]initWithContentsOfFile:pic_path];
    return image;
}




//+(NSImage *)cw_getRecycleImage{
//
//    NSImage *image = [self getMyBundleImage:@"recycle.png"];
//    return image;
//}

+(NSImage *)cw_getRecycleImage{

    NSImage *image = [self getMyBundleImage:@"recycle.png"];
    return image;
}

+(NSImage *)cw_getRedCircleImage{
    
    NSImage *image = [NSImage imageNamed:@"NSStatusNone"];
    return image;
}
+(NSImage *)cw_getGrayCircleImage{
    
    NSImage *image = [NSImage imageNamed:@"NSStatusNone"];
    
    return image;
}
+(NSImage *)cw_getGreenCircleImage{
    
    NSImage *image = [NSImage imageNamed:@"NSStatusAvailable"];
    return image;
}

@end
