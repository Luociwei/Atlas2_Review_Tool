//
//  CWRedis.h
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/12/11.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CWRedis : NSObject
+(void)shutDown;
-(BOOL)connect;
-(BOOL)setString:(NSString *)key value:(NSString *)value;
-(NSString *)get:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
