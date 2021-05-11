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
    if (strVaule.length) {
        [self setObject:strVaule forKey:key];
    }else{
        [self setObject:@"" forKey:key];
    }
}
@end
