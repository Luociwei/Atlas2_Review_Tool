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
extern NSString *const id_sub_dir_name;
extern NSString *const id_end_time;
extern NSString *const id_start_time;
extern NSString *const id_test_time;
extern NSString *const key_test_time_s;
extern NSString *const id_index;
extern NSString *const id_sn;
extern NSString *const id_slot;
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
extern NSString *const key_IsSearch;


extern NSString *const id_Disable;
extern NSString *const id_Input;
extern NSString *const id_Output;
extern NSString *const id_Timeout;
extern NSString *const id_Retries;
extern NSString *const id_ExitEarly;
extern NSString *const id_SetPoison;
extern NSString *const id_FA;
extern NSString *const id_Condition;

//extern NSString *const id_TestName;
extern NSString *const id_Main_Disable;
extern NSString *const id_Production;
extern NSString *const id_Audit;
extern NSString *const id_Thread;
extern NSString *const id_Loop;
extern NSString *const id_Sample;
extern NSString *const id_CoF;
extern NSString *const id_Main_Condition;


@end

NS_ASSUME_NONNULL_END
