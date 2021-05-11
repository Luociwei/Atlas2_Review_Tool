//
//  ItemMode.m
//  OPP_Tool
//
//  Created by ciwei luo on 2020/5/26.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import "ItemMode.h"
#import "ExtensionConst.h"

@implementation ItemMode

-(instancetype)init{
    if (self == [super init]) {
        
//        self.SnVauleArray = [[NSMutableArray alloc]init];
    }
    return self;
}

-(NSString *)getVauleWithKey:(NSString *)key{
    NSString *value = @"";
    if ([key.lowercaseString isEqualToString:@"sn"]) {
        value = self.sn;
    }else if ([key.lowercaseString isEqualToString:@"starttime"]) {
        value = self.startTime;
    }else if ([key.lowercaseString isEqualToString:@"faillist"]) {
        value = self.failList;
    }else if ([key.lowercaseString isEqualToString:@"index"]) {
        value = [NSString stringWithFormat:@"%ld",(long)self.index];
    }else if ([key.lowercaseString isEqualToString:@"record"]) {
        value = self.recordPath;
    }
    return value;
}

-(void)setFailList:(NSString *)failList{
    if (failList.length) {
        _failList = failList;
        _isFail = YES;
    }else{
        _failList = @"";
        _isFail = NO;
    }
    
    
    
}

+(NSMutableArray *)getDicArrayWithItemModeArr:(NSArray *)item_mode_arr{
    NSMutableArray *tableData_dic = [[NSMutableArray alloc]init];
 
    for (ItemMode *mode in item_mode_arr) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict cw_safetySetObject:[NSString stringWithFormat:@"%ld",(long)mode.index] forKey:id_index];
        [dict cw_safetySetObject:mode.startTime forKey:id_start_time];
        [dict cw_safetySetObject:mode.sn forKey:id_sn];
        [dict cw_safetySetObject:mode.failList forKey:id_fail_list];
        [dict setObject:@(mode.isFail) forKey:key_is_fail];
        [dict cw_safetySetObject:mode.recordPath forKey:key_record_path];
        [dict setObject:[NSImage imageNamed:NSImageNameFolder] forKey:id_record];
        [tableData_dic addObject:dict];
        
    }
    return tableData_dic;
}

@end
