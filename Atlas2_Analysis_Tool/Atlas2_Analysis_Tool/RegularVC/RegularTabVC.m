//
//  RegularTabVC.m
//  Atlas2_Analysis_Tool
//
//  Created by ciwei luo on 2021/8/12.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "RegularTabVC.h"
#import "RegularVC.h"
#import "ExtensionConst.h"
#import "CycleTimeModel.h"
@interface RegularTabVC ()

@end

@implementation RegularTabVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    RegularVC *ocRegularVC = [[RegularVC alloc]init];
    ocRegularVC.title = @"Objective-C";
    RegularVC *luaRegularVC = [[RegularVC alloc]init];
    luaRegularVC.title = @"Lua";
    [self addChildViewController:ocRegularVC];
    [self addChildViewController:luaRegularVC];
    
    
//    [self cycleTimeCompare];
}

-(void)cycleTimeCompare{
    NSString *sc_cycle_time_path = @"/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/cycle_time/J407_SC_FCT_Cycle_Time.csv";
    NSString *atlas2_cycle_time_path = @"/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/cycle_time/J407_SC_Atlas2_Cycle_Time.csv";
    CSVParser *parser1 = [[CSVParser alloc]init];
    NSMutableArray *scArr =nil;
    
    NSMutableArray *compareArr =[[NSMutableArray alloc]init];;
    if ([parser1 openFile:sc_cycle_time_path]) {
        scArr = [parser1 parseFile];
        
        for (int i =0; i<scArr.count; i++) {
            NSArray *subArr = scArr[i];
            if (subArr.count != [scArr[0] count]) {
                continue;
            }
            CycleTimeModel *model = [[CycleTimeModel alloc]init];
            model.sc_TestName = subArr[0];
            model.sc_SubItem = subArr[1];
            model.sc_SubSubItem = subArr[2];
            model.sc_test_time = subArr[3];
            model.atlas2_Item = @"";
            model.atlas2_SubItem = @"";
            model.atlas2_test_time = @"";
            model.isFind = NO;
            [compareArr addObject:model];
        }
        
    }
    
//    NSString *atlas2_cycle_time_content = [FileManager cw_readFromFile:atlas2_cycle_time_path];
    
//    NSArray *atlas2Arr =[atlas2_cycle_time_content componentsSeparatedByString:@"\n"];
    
    for (int i = 0; i<compareArr.count; i++) {
        CycleTimeModel *model = compareArr[i];
        NSString *fullName = [NSString stringWithFormat:@",%@ %@ %@,",model.sc_TestName,model.sc_SubItem,model.sc_SubSubItem];
        NSString *cmd = [NSString stringWithFormat:@"grep \"%@\" %@",fullName,atlas2_cycle_time_path];
        NSString *log = [Task cw_termialWithCmd:cmd];
        if (log.length) {
            NSArray *logArr = [log componentsSeparatedByString:@"\n"];
            if (logArr.count==1 || (logArr.count==2 && [logArr[1] length] ==0)){
                NSArray *sub_log_arr = [log componentsSeparatedByString:@","];
                if (sub_log_arr.count == 9) {
                    model.atlas2_test_time = sub_log_arr[4];
                    model.atlas2_SubItem = sub_log_arr[5];
                    model.atlas2_Item = sub_log_arr[6];
                    model.isFind = YES;
                }
                
            }else{
                NSLog(@"%@ not found!!!count = %lu",fullName,(unsigned long)logArr.count);
            }
        }
 
    }
    
    NSLog(@"1111");

    if (compareArr.count) {
        NSString *title = [NSString stringWithFormat:@"TestName,SubItem,SubSubItem,test time(s),Atlas_test_time(s),Atlas_SubItem,Atlas_Item,isFind\n"];
        NSMutableString *compareString = [NSMutableString stringWithString:title];

        for (int i =0; i<compareArr.count; i++) {
            CycleTimeModel *model = compareArr[i];
//            model.sc_TestName = subArr[0];
//            model.sc_SubItem = subArr[1];
//            model.sc_SubSubItem = subArr[2];
//            model.sc_test_time = subArr[3];
//            model.atlas2_Item = @"";
//            model.atlas2_SubItem = @"";
//            model.atlas2_test_time = @"";
//            model.isFind = NO;
            [compareString appendString:[NSString stringWithFormat:@"%@,",model.sc_TestName]];
            [compareString appendString:[NSString stringWithFormat:@"%@,",model.sc_SubItem]];
            [compareString appendString:[NSString stringWithFormat:@"%@,",model.sc_SubSubItem]];
            [compareString appendString:[NSString stringWithFormat:@"%@,",model.sc_test_time]];
            [compareString appendString:[NSString stringWithFormat:@"%@,",model.atlas2_test_time]];
            [compareString appendString:[NSString stringWithFormat:@"%@,",model.atlas2_SubItem]];
            [compareString appendString:[NSString stringWithFormat:@"%@,",model.atlas2_Item]];
            if (model.isFind) {
                [compareString appendString:@"Y\n"];
            }else{
                [compareString appendString:@"N\n"];
            }
        }
        
        NSError *error;
        NSString *compare_path =[NSString stringWithFormat:@"%@/FCT_Cycle_Time_Compare.csv",sc_cycle_time_path.stringByDeletingLastPathComponent];
        [compareString writeToFile:compare_path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
//    parser parseFile
    
    
    
}

@end
