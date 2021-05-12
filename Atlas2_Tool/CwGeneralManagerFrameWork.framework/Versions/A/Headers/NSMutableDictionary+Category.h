//
//  NSMutableDictionary+Category.h
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/5/4.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (Category)
- (void)cw_safetySetObject:(NSString *)strVaule forKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
