//
//  LuaFunction.h
//  My_Review_Tool
//
//  Created by ciwei luo on 2021/5/11.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ExtensionConst.h"
NS_ASSUME_NONNULL_BEGIN

@interface LuaFunction : PresentViewController
@property(nonatomic,strong)NSString *luaFunctionPath;
@property(nonatomic,strong)NSString *luaFunctionName;
@end

NS_ASSUME_NONNULL_END
