//
//  ExtensionConst.h
//  OPP_Tool
//
//  Created by Louis Luo on 2020/7/16.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CwGeneralManagerFrameWork/CwGeneralManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExtensionConst : NSObject

extern int const snLength;
extern NSString *const plistName;

extern NSString *const id_start_time;
extern NSString *const id_index;
extern NSString *const id_sn;
extern NSString *const id_record;
extern NSString *const id_fail_list;
extern NSString *const key_is_fail;
extern NSString *const key_record_path;

extern NSString *const id_TestName;
extern NSString *const id_SubTestName;
extern NSString *const id_SubSubTestName;
extern NSString *const id_Command;
extern NSString *const id_AdditionalParameters;
extern NSString *const id_Function;
extern NSString *const id_LowLimit;
extern NSString *const id_UpperLimit;
extern NSString *const id_Unit;//id_Unit
//extern NSString *const id_TestName;

@end

NS_ASSUME_NONNULL_END
