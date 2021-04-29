//
//  AtlasMode.h
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/4/19.
//  Copyright © 2021 macdev. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AtlasMode : NSObject
@property (nonatomic,copy)NSString *sn;
@property (nonatomic,copy)NSString *value;
-(NSString *)getVauleWithKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
