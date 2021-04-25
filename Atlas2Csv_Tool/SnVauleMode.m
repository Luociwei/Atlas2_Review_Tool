//
//  SnVauleMode.m
//  OPP_Tool
//
//  Created by ciwei luo on 2020/5/27.
//  Copyright © 2020 macdev. All rights reserved.
//

#import "SnVauleMode.h"

@implementation SnVauleMode

-(NSString *)getVauleWithKey:(NSString *)key{
    NSString *value = @"";
    if ([key isEqualToString:@"name"]) {
        value = self.name;
    }else if ([key isEqualToString:@"command"]) {
        value = self.command;
    }
    return value;
}



@end
