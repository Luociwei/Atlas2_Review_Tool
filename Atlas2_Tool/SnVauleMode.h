//
//  SnVauleMode.h
//  OPP_Tool
//
//  Created by ciwei luo on 2020/5/27.
//  Copyright © 2020 macdev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SnVauleMode : NSObject
@property (nonatomic,copy)NSString *name;
@property (nonatomic,copy)NSString *command;
-(NSString *)getVauleWithKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
