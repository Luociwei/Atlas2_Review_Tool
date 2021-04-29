//
//  AtlasMode.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/4/19.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "AtlasMode.h"

@implementation AtlasMode
-(NSString *)getVauleWithKey:(NSString *)key{
    NSString *value = @"";
    if ([key isEqualToString:@"sn"]) {
        value = self.sn;
    }else if ([key isEqualToString:@"value"]) {
        value = self.value;
    }
    return value;
}

@end
