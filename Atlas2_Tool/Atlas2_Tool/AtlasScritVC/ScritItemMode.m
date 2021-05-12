//
//  ScritItemMode.m
//  OPP_Tool
//
//  Created by ciwei luo on 2020/5/26.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import "ScritItemMode.h"
#import "ExtensionConst.h"

@implementation ScritItemMode

-(instancetype)init{
    if (self == [super init]) {
        
//        self.SnVauleArray = [[NSMutableArray alloc]init];
    }
    return self;
}

-(void)setSubSubTestName:(NSString *)subSubTestName{
    if (subSubTestName.length && [subSubTestName containsString:@"subsubtestname"]) {
        NSDictionary *dict = [FileManager cw_serializationWithJsonString:subSubTestName];
        
        if ([dict objectForKey:@"subsubtestname"]) {
            _subSubTestName =[dict objectForKey:@"subsubtestname"];
        }
        
    }else{
        _subSubTestName = @"";
    }
    
}



+(NSMutableArray *)getDicArrayWithScritItemModeArr:(NSArray *)item_mode_arr{
    NSMutableArray *tableData_dic = [[NSMutableArray alloc]init];
 
    for (ScritItemMode *mode in item_mode_arr) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict cw_safetySetObject:[NSString stringWithFormat:@"%ld",(long)mode.index] forKey:id_index];
        [dict cw_safetySetObject:mode.testName forKey:id_TestName];
        [dict cw_safetySetObject:mode.subTestName forKey:id_SubTestName];
        [dict cw_safetySetObject:mode.subSubTestName forKey:id_SubSubTestName];
        [dict cw_safetySetObject:mode.subSubTestName forKey:id_SubSubTestName];
        [dict setObject:mode.params forKey:id_AdditionalParameters];
        [dict cw_safetySetObject:mode.function forKey:id_Function];
        [dict cw_safetySetObject:mode.command forKey:id_Command];
        [dict cw_safetySetObject:mode.lowLimit forKey:id_LowLimit];
        [dict cw_safetySetObject:mode.upperLimit forKey:id_UpperLimit];
        [dict cw_safetySetObject:mode.unit forKey:id_Unit];
        [dict cw_safetySetObject:mode.searchKeyWord forKey:key_IsSearch];
        
        [dict cw_safetySetObject:mode.Disable forKey:id_Disable];
        [dict cw_safetySetObject:mode.Input forKey:id_Input];
        [dict cw_safetySetObject:mode.Output forKey:id_Output];
        [dict cw_safetySetObject:mode.Timeout forKey:id_Timeout];
        [dict cw_safetySetObject:mode.Retries forKey:id_Retries];
        [dict cw_safetySetObject:mode.ExitEarly forKey:id_ExitEarly];
        [dict cw_safetySetObject:mode.SetPoison forKey:id_SetPoison];
        [dict cw_safetySetObject:mode.FA forKey:id_FA];
        [dict cw_safetySetObject:mode.Condition forKey:id_Condition];
        
        
        [dict cw_safetySetObject:mode.mainDisable forKey:id_Main_Disable];
        [dict cw_safetySetObject:mode.production forKey:id_Production];
        [dict cw_safetySetObject:mode.audit forKey:id_Audit];
        [dict cw_safetySetObject:mode.thread forKey:id_Thread];
        [dict cw_safetySetObject:mode.loop forKey:id_Loop];
        [dict cw_safetySetObject:mode.sample forKey:id_Sample];
        
        [dict cw_safetySetObject:mode.cof forKey:id_CoF];
        [dict cw_safetySetObject:mode.mainCondition forKey:id_Main_Condition];
        
        [tableData_dic addObject:dict];
        
    }
    return tableData_dic;
}

@end
