//
//  NSMutableDictionary+Category.m
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/5/4.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "NSMutableDictionary+Category.h"

@implementation NSMutableDictionary (Category)
- (void)cw_safetySetObject:(NSString *)strVaule forKey:(NSString *)key{
    if (strVaule!=nil) {
        NSString *new_str = [self addDoubleQuotationWithString:strVaule];
        [self setObject:new_str forKey:key];
    }else{
        [self setObject:@"" forKey:key];
    }
}

-(NSString *)addDoubleQuotationWithString:(NSString *)str{
    if ([str containsString:@","]&& ![str hasSuffix:@"\""]) {
        if (![str hasPrefix:@"\""]) {
            str = [NSString stringWithFormat:@"\"%@",str];
        }
        if (![str hasSuffix:@"\""]) {
            str = [NSString stringWithFormat:@"%@\"",str];
        }
        return str;
    }else{
        return str;
    }
}
@end
