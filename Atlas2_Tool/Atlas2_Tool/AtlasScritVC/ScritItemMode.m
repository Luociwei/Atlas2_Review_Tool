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
        [dict setObject:[NSString stringWithFormat:@"%ld",(long)mode.index] forKey:id_index];
        [dict setObject:mode.testName forKey:id_TestName];
        [dict setObject:mode.subTestName forKey:id_SubTestName];
        [dict setObject:mode.subSubTestName forKey:id_SubSubTestName];
        [dict setObject:mode.subSubTestName forKey:id_SubSubTestName];
        [dict setObject:mode.params forKey:id_AdditionalParameters];
        [dict setObject:mode.function forKey:id_Function];
        [dict setObject:mode.command forKey:id_Command];
        [dict setObject:mode.lowLimit forKey:id_LowLimit];
        [dict setObject:mode.upperLimit forKey:id_UpperLimit];
        [dict setObject:mode.unit forKey:id_Unit];
        [tableData_dic addObject:dict];
        
    }
    return tableData_dic;
}

@end
