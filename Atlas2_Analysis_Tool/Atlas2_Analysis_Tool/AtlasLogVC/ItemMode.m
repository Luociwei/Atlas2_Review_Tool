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


-(void)setRecordPath:(NSString *)recordPath{
    if (!recordPath.length) {
        recordPath = @"";
    }
    _recordPath = recordPath;
    
    NSString *systemFile = recordPath.stringByDeletingLastPathComponent;
    _subDirName = systemFile.stringByDeletingLastPathComponent.lastPathComponent;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *flow_file = [systemFile stringByAppendingPathComponent:@"device.log"];
    for (NSString *file in [manager enumeratorAtPath:systemFile]) {
  
        if ([file containsString:@"flow.log"]) {
            flow_file = [systemFile stringByAppendingPathComponent:file];
            break;
        }
    }
    NSString *content = [FileManager cw_readFromFile:flow_file];
    NSString *pattern = @"\\d{4}[-/]\\d+[-/]\\d+ \\d+:\\d+:\\d+";
    NSMutableArray *resultsArr = [content cw_regularWithPattern:pattern];
//    @autoreleasepool {
        _startTime = [NSString stringWithFormat:@"%@", resultsArr.firstObject[0]];
        if (!_startTime.length) {
            _startTime = @"";
        }
        _endTime = [NSString stringWithFormat:@"%@", resultsArr.lastObject[0]];
        if (!_endTime.length) {
            _endTime = @"";
        }
        
//    }
    NSDate *date1 = [self getDateFrom:_startTime];
    NSDate *date2 = [self getDateFrom:_endTime];
    NSTimeInterval test_time = [date2 timeIntervalSinceDate:date1];
    _testTime_s = test_time;
    _testTime = [self timeFormatted:test_time];
    
//    NSLog(@"1");
    
//    _startTime = [resultsArr.firstObject[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];;
//    _endTime = [resultsArr.lastObject[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];;;
    //NSString *flowFile = systemFile stringByAppendingPathComponent:@""
}

- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    NSString *str = @"";
//    @autoreleasepool {
        if (hours == 0) {
            if (minutes == 0) {
                str =[NSString stringWithFormat:@"%02ds", seconds];
            }else{
                str =[NSString stringWithFormat:@"%02dm%02ds",minutes, seconds];
            }
            
        }else{
            str =[NSString stringWithFormat:@"%02dh%02dm%02ds",hours,minutes, seconds];
        }
//    }
    return str;
}



-(NSDate *)getDateFrom:(NSString *)str{
    //20210416_15-57-50.001-A772CC
    //    NSArray *arr = [str cw_componentsSeparatedByString:@"."];
    //    NSString *timeStr = arr[0];
    NSString *time_str = [NSString stringWithFormat:@"%@",str];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //需要设置为和字符串相同的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd H:mm:ss"];
    NSDate *localDate = [dateFormatter dateFromString:time_str];
    
    return localDate;
}


-(NSString *)getVauleWithKey:(NSString *)key{
    NSString *value = @"";
    if ([key.lowercaseString isEqualToString:@"sn"]) {
        value = self.sn;
    }else if ([key.lowercaseString isEqualToString:@"slot"]) {
        value = self.slot;
    }else if ([key.lowercaseString isEqualToString:@"cfg"]) {
        value = self.cfg;
    }else if ([key.lowercaseString isEqualToString:@"broadtype"]) {
        value = self.broadType;
    }
    else if ([key.lowercaseString isEqualToString:@"endtime"]) {
        value = self.endTime;
    }else if ([key.lowercaseString isEqualToString:@"starttime"]) {
        value = self.startTime;
    }else if ([key.lowercaseString isEqualToString:@"testtime(s)"]) {
        value = self.testTime;
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

//-(void)ge


+(NSMutableArray *)getDicArrayWithItemModeArr:(NSArray *)item_mode_arr{
    NSMutableArray *tableData_dic = [[NSMutableArray alloc]init];
 
    for (ItemMode *mode in item_mode_arr) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict cw_safetySetObject:[NSString stringWithFormat:@"%ld",(long)mode.index] forKey:id_index];
        [dict setObject:mode.subDirName forKey:id_sub_dir_name];
        [dict setObject:[NSNumber numberWithInteger:mode.testTime_s] forKey:key_test_time_s];
        [dict setObject:mode.startTime forKey:id_start_time];
        [dict setObject:mode.endTime forKey:id_end_time];
        [dict setObject:mode.testTime forKey:id_test_time];
        [dict cw_safetySetObject:mode.broadType forKey:id_broad_type];
        [dict cw_safetySetObject:mode.cfg forKey:id_cfg];
        [dict cw_safetySetObject:mode.sn forKey:id_sn];
        [dict cw_safetySetObject:mode.slot forKey:id_slot];
        [dict cw_safetySetObject:mode.failList forKey:id_fail_list];
        [dict setObject:@(mode.isFail) forKey:key_is_fail];
        [dict setObject:mode.recordPath forKey:key_record_path];
        [dict setObject:[NSImage imageNamed:NSImageNameFolder] forKey:id_record];
        [tableData_dic addObject:dict];
        
    }
    return tableData_dic;
}

@end
