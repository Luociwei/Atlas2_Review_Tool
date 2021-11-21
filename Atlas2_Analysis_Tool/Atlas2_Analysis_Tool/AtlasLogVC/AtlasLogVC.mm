//
//  ViewController.m
//  SC_Eowyn
//
//  Created by ciwei luo on 2020/3/31.
//  Copyright © 2020 ciwei luo. All rights reserved.
//

#import "AtlasLogVC.h"
#import "ItemMode.h"
#import "FailOnlyItems.h"
//#import "RedisInterface.hpp"
#import "ProgressBarVC.h"

@interface AtlasLogVC ()
//@property (unsafe_unretained) IBOutlet NSTextView *logview;
//@property (strong) IBOutlet NSMenuItem *editMenu;
//@property (weak) IBOutlet NSButton *showSlot;
@property (weak) IBOutlet NSButton *btnGenerate;

//@property (nonatomic,strong) NSArray<NSDictionary *> *items_datas;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *testTimeSort_items_data;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *fail_items_data;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *startTimeSort_items_data;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *timeSort_items_data;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *slotSort_items_data;
//@property (nonatomic,strong) NSMutableArray<SnVauleMode *> *sn_datas;
@property (weak) IBOutlet NSTableView *itemsTableView;
//@property (weak) IBOutlet NSTableView *snTableView;
@property (weak) IBOutlet NSTextField *labelPath;
//@property (nonatomic, strong) FMDatabase *db;
@property (weak) IBOutlet FileDragView *logDropView;
@property (weak) IBOutlet NSTextField *labelCount;
@property (strong,nonatomic)FailOnlyItems *failOnlyItems;
@property(nonatomic,strong)TableDataDelegate *tableDataDelegate;
@property(nonatomic,strong)ProgressBarVC *progressBarVC;


@end

@implementation AtlasLogVC{
    NSString *dfuLogPath;
//    RedisInterface *myRedis;
 
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.labelCount.stringValue = @"Test Total Count:0   Fail Count:0   Pass Count:0   rate:0";
    NSString *deskPath = [NSString cw_getUserPath];
    dfuLogPath =[deskPath stringByAppendingPathComponent:@"DFU_Tool_Log"];
    [FileManager cw_createFile:dfuLogPath isDirectory:YES];
    
//    self.items_datas = [[NSMutableArray alloc]init];
    self.testTimeSort_items_data = [[NSMutableArray alloc]init];
    self.fail_items_data = [[NSMutableArray alloc]init];
    self.startTimeSort_items_data = [[NSMutableArray alloc]init];
    self.slotSort_items_data = [[NSMutableArray alloc]init];
    
    [self.itemsTableView setDoubleAction:@selector(doubleClick:)];
    self.tableDataDelegate.owner = self.itemsTableView;
    

}

-(void)removeAllItemsData{
    [self.fail_items_data removeAllObjects];
    [self.testTimeSort_items_data removeAllObjects];
    [self.startTimeSort_items_data removeAllObjects];
    [self.slotSort_items_data removeAllObjects];
}

-(void)updateAllIWithtemsData:(NSMutableArray *)item_dict_arr{
    [self removeAllItemsData];
    
    self.testTimeSort_items_data = [self getTestTimeSortItemsData:item_dict_arr];
    self.fail_items_data = [self getFailListSortItemsData:item_dict_arr];
    self.startTimeSort_items_data = [self getStartTimeSortItemsData:item_dict_arr];
    self.slotSort_items_data = [self getSotSortItemsData:item_dict_arr];
}

- (IBAction)add_csv_click:(NSButton *)sender {
    //    [FileManager openPanel:^(NSString * _Nonnull path) {
//    [self redis_set];
    [self removeAllItemsData];
    
    NSString *path =self.logDropView.stringValue;
    
    self.labelCount.stringValue = @"";//@"Test Total Count:0 Fail Count:0 Pass Count:0"
    if (!path.length || ![FileManager cw_isFileExistAtPath:path]) {

        [self.tableDataDelegate reloadTableViewWithData:nil];
        [Alert cw_messageBox:@"Error!" Information:@"Not found the file path,pls check!!!"];
        return;
    }

    [self.progressBarVC showViewOnViewController:self];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:path]) {
            
            [self.tableDataDelegate reloadTableViewWithData:nil];
            return;
        }
        //    NSString *home = [@"~" stringByExpandingTildeInPath];
        NSMutableArray *files = [[NSMutableArray alloc] init];
        
        for (NSString *filename in [manager enumeratorAtPath:path]) {
            
            if ([filename containsString:@"system/records.csv"]) {
                [files addObject:filename];
            }
        }
        //[FileManager cw_findPathWithfFileName:@"system/records.csv" dirPath:path deepFind:YES];
        if (files.count < 1) {
            [self.itemsTableView reloadData];
            return;
        }
        
        NSMutableArray *item_mode_arr = [[NSMutableArray alloc]init];
        NSMutableArray *item_mode_pass_arr=[[NSMutableArray alloc]init];
        NSMutableArray *item_mode_fail_arr=[[NSMutableArray alloc]init];
        NSInteger i = 1;
        CSVParser *csv = [[CSVParser alloc]init];
        NSInteger count_files = files.count;
        for (NSString *filename in files) {
            @autoreleasepool {
                ItemMode *item_mode = [[ItemMode alloc]init];
                NSArray *pathArr = [filename cw_componentsSeparatedByString:@"/"];
                item_mode.sn = pathArr[0];

                item_mode.recordPath = [NSString stringWithFormat:@"%@/%@",path,filename];
                //        ItemMode.s
                NSString *userFile = [item_mode.recordPath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"user"];
                
                NSString*device_path =[NSString stringWithFormat:@"%@/device.log",item_mode.recordPath.stringByDeletingLastPathComponent];
                item_mode.slot = @"Unkonw";
                //        if (self.showSlot.state) {
                NSString *device_content = [FileManager cw_readFromFile:device_path];
                if ([device_content containsString:@"group0.G=1:S=slot1]"]||[device_content containsString:@"group0.Device_slot1"]) {
                    item_mode.slot = @"1";
                }else if ([device_content containsString:@"group0.G=1:S=slot2]"]||[device_content containsString:@"group0.Device_slot2"]) {
                    item_mode.slot = @"2";
                }else if ([device_content containsString:@"group0.G=1:S=slot3]"]||[device_content containsString:@"group0.Device_slot3"]) {
                    item_mode.slot = @"3";
                }else if ([device_content containsString:@"group0.G=1:S=slot4]"]||[device_content containsString:@"group0.Device_slot4"]) {
                    item_mode.slot = @"4";
                }else{
                    
                    if ([FileManager cw_isFileExistAtPath:[userFile stringByAppendingPathComponent:@"RPC_CH1"]]) {
                        item_mode.slot = @"1";
                    }else if ([FileManager cw_isFileExistAtPath:[userFile stringByAppendingPathComponent:@"RPC_CH2"]]){
                        item_mode.slot = @"2";
                    }else if ([FileManager cw_isFileExistAtPath:[userFile stringByAppendingPathComponent:@"RPC_CH3"]]){
                        item_mode.slot = @"3";
                    }else if ([FileManager cw_isFileExistAtPath:[userFile stringByAppendingPathComponent:@"RPC_CH4"]]){
                        item_mode.slot = @"4";
                    }
                }
                
                
                item_mode.cfg = @"Unkonw";
                item_mode.broadType = @"Unkonw";
                NSArray *uartLogFiles = [FileManager cw_findPathWithfFileName:@".log" dirPath:userFile deepFind:NO];
                if (uartLogFiles.count) {
                    NSString *uartLogPath = uartLogFiles[0];
                    NSString *uartLogContent = [FileManager cw_readFromFile:uartLogPath];
                    NSArray *typeArr = [uartLogContent cw_regularWithPattern:@"boot, Board\\s+(.+\\))"];
                    NSArray *cfgArr = [uartLogContent cw_regularWithPattern:@"CFG#[\\sValue]*:\\s+(.+)"];
                    if (cfgArr.count) {
                        if ([cfgArr[0] count]>=2) {
                            item_mode.cfg = cfgArr[0][1];
                        }
                        
                    }
                    if (typeArr.count) {
                        if ([typeArr[0] count]>=2) {
                            item_mode.broadType = typeArr[0][1];
                        }
                        
                    }
                    
                    
                }
                
                
                
                //        item_mode.sn = pathArr[0];
                //        item_mode.startTime = pathArr[1];
                NSString *recordPath = [path stringByAppendingPathComponent:filename];
                //        NSString *recordContent = [FileManager cw_readFromFile:recordPath];
                
                NSArray *csvArray = nil;
                if ([csv openFile:recordPath]) {
                    csvArray = [csv parseFile];
                }
                NSMutableString *failList = [NSMutableString stringWithString:@""];
                NSEnumerator *enumer=[csvArray objectEnumerator];
                NSArray *itemInfo;
                while (itemInfo=[enumer nextObject]) {
                    //            NSLog(@"%@----%@",itemInfo,[NSThread currentThread]);
                    if (itemInfo.count<=12) {
                        continue;
                    }
                    if ([itemInfo[12] isEqualToString:@"FAIL"]) {
                        NSString *fail_item = [NSString stringWithFormat:@"%@-%@-%@;",itemInfo[2],itemInfo[3],itemInfo[4]];
                        [failList appendString:fail_item];
                        
                    }
                    
                }
                
                item_mode.failList = failList;
                if (failList.length) {
                    [item_mode_fail_arr addObject:item_mode];
                }else{
                    [item_mode_pass_arr addObject:item_mode];
                }
                item_mode.index=i;
                
                //        NSLog(@"%@",filename);
                [item_mode_arr addObject:item_mode];
//                BOOL S =self.progressBarVC.isViewLoaded;
                if (self.progressBarVC.isActive) {
                    double v =i*1.0/count_files*100.0;
                    [self.progressBarVC setProgressBarDoubleValue:v info:item_mode.sn];
                }else{
                    return;
                }

                i = i + 1;
            }
        }
        

        NSInteger total_count = item_mode_arr.count ? item_mode_arr.count : 0;
        NSInteger fail_count = item_mode_fail_arr.count ? item_mode_fail_arr.count : 0;
        NSInteger pass_count = item_mode_pass_arr.count ? item_mode_pass_arr.count : 0;
        NSInteger rate = 0;
        if (total_count>0 ) {
            rate = 100*pass_count/total_count;
        }
        

        NSMutableArray *item_dict_arr =[ItemMode getDicArrayWithItemModeArr:item_mode_arr];
        
        [self updateAllIWithtemsData:item_dict_arr];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressBarVC dismisssViewOnViewController:self];
            
            self.labelCount.stringValue = [NSString stringWithFormat:@"Test Total Count:%ld   Fail Count:%ld   Pass Count:%ld   rate:%ld%%",(long)total_count,(long)fail_count,(long)pass_count,(long)rate];//@"Test Total Count:0 Fail Count:0 Pass Count:0"
            
//            self.btnGenerate.title = @"Generate";
            [self.tableDataDelegate reloadTableViewWithData:self.startTimeSort_items_data];
        });

    });
}


//-(NSMutableArray *)getSnSortItemsData:(NSMutableArray<NSDictionary *>*)itemsData{
//
//    NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch|NSNumericSearch|
//
//    NSWidthInsensitiveSearch|NSForcedOrderingSearch;
//
//    NSComparator sort = ^(NSDictionary *dict1,NSDictionary *dict2){
//        NSString *obj1 = [dict1 objectForKey:id_sn];
//        NSString *obj2 = [dict1 objectForKey:id_sn];
//        NSRange range = NSMakeRange(0,obj1.length);
//
//        return [obj1 compare:obj2 options:comparisonOptions range:range];
//
//    };
//
//    NSArray *resultArray = [itemsData sortedArrayUsingComparator:sort];
//
//    return [[NSMutableArray alloc]initWithArray:resultArray];
//}


//-(NSInteger)getTestTime:(NSString *)timeStr{
//    NSInteger h = 0;
//    NSInteger m = 0;
//    NSInteger s = 0;
//    if ([timeStr containsString:@"h"]) {
//        
//    }
//}

-(NSMutableArray *)getTestTimeSortItemsData:(NSMutableArray<NSDictionary *>*)itemsData{
    NSArray *sortArray = [itemsData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *dict1 = obj1;
        NSDictionary *dict2 = obj2;
        NSInteger time1 = [[dict1 objectForKey:key_test_time_s] integerValue];
        NSInteger time2 = [[dict2 objectForKey:key_test_time_s] integerValue];

        //        NSDate *date1 = [self getDateFrom:dict1[id_start_time]];
        //        NSDate *date2 = [self getDateFrom:dict2[id_start_time]];
        if (time1 - time2 > 0) {
            return NSOrderedDescending;//降序
        }else if (time1 - time2 < 0){
            return NSOrderedAscending;//升序
        }else {
            return NSOrderedSame;//相等
        }
    }];
    
    return [[NSMutableArray alloc]initWithArray:sortArray];
}

-(NSMutableArray *)getFailListSortItemsData:(NSMutableArray<NSDictionary *>*)itemsData{
    NSArray *sortArray = [itemsData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *dict1 = obj1;
        NSDictionary *dict2 = obj2;
        NSString *fail_list1 = [dict1 objectForKey:id_fail_list];
        NSString *fail_list2 = [dict2 objectForKey:id_fail_list];
        NSInteger num1 =fail_list1.length;
        NSInteger num2 =fail_list2.length;

        //        NSDate *date1 = [self getDateFrom:dict1[id_start_time]];
        //        NSDate *date2 = [self getDateFrom:dict2[id_start_time]];
        if (num1 - num2 > 0) {
            return NSOrderedDescending;//降序
        }else if(num1 - num2 < 0){
            return NSOrderedAscending;//升序
        }
        else{
            return NSOrderedSame;//相等
        }
    }];
    
    return [[NSMutableArray alloc]initWithArray:sortArray];
}



-(NSMutableArray *)getSotSortItemsData:(NSMutableArray<NSDictionary *>*)itemsData{
    NSArray *sortArray = [itemsData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *dict1 = obj1;
        NSDictionary *dict2 = obj2;
        NSString *slot1 = [dict1 objectForKey:id_slot];
        NSString *slot2 = [dict2 objectForKey:id_slot];
        int num_slot1 = slot1.intValue;
        int num_slot2 = slot2.intValue;
//        NSDate *date1 = [self getDateFrom:dict1[id_start_time]];
//        NSDate *date2 = [self getDateFrom:dict2[id_start_time]];
        if (num_slot1 - num_slot2 > 0) {
            return NSOrderedDescending;//降序
        }else if (num_slot1 - num_slot2 < 0){
            return NSOrderedAscending;//升序
        }else {
            return NSOrderedSame;//相等
        }
    }];
    
    return [[NSMutableArray alloc]initWithArray:sortArray];
}


-(NSMutableArray *)getStartTimeSortItemsData:(NSMutableArray<NSDictionary *>*)itemsData{
    NSArray *sortArray = [itemsData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *dict1 = obj1;
        NSDictionary *dict2 = obj2;

        NSDate *date1 = [self getDateFrom:dict1[id_start_time]];
        NSDate *date2 = [self getDateFrom:dict2[id_start_time]];
        if ([date1 timeIntervalSinceDate:date2]>0) {
            return NSOrderedDescending;//降序
        }else if ([date1 timeIntervalSinceDate:date2]<0){
            return NSOrderedAscending;//升序
        }else {
            return NSOrderedSame;//相等
        }
    }];
 
    return [[NSMutableArray alloc]initWithArray:sortArray];
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

- (IBAction)save:(id)sender {
//    [self redis_get];
    
    NSArray *itemsData = [self.tableDataDelegate getData];
    if (!itemsData.count) {
        return;
    }
    
    NSString *path = [dfuLogPath stringByAppendingPathComponent:@"Atlas2_AllLog.csv"];
    NSMutableString *text = [[NSMutableString alloc] init];
    NSArray *columns = self.itemsTableView.tableColumns;
    for (NSTableColumn *column in columns) {
        [text appendString:column.identifier];
        [text appendString:@","];
    }
    [text appendString:@"\n"];
    
    for (int m =0;m<itemsData.count;m++) {
        
        NSDictionary *item_dic = itemsData[m];
        //        NSString *key = [columns[m] identifier];
        //        [text appendString:[item_mode getVauleWithKey:key]];
        
        for (int i =0; i<columns.count; i++) {
            
            NSString *key = [columns[i] identifier];
            if ([key isEqualToString:id_record]) {
                [text appendString:[item_dic objectForKey:key_record_path]];
            }else if ([key isEqualToString:id_index]) {
                [text appendString:[NSString stringWithFormat:@"%d",m+1]];
            }else{
                [text appendString:[item_dic objectForKey:key]];
            }
            
            if (i!=columns.count-1) {
                [text appendString:@","];
            }else{
                [text appendString:@"\n"];
            }
        }
        
    }
    
    NSError *error;
    [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    //[text writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
    //    if (sender==nil) {
    //        return;
    //    }
    if(error){
        NSLog(@"save file error %@",error);
        [Alert cw_RemindException:@"Save Fail" Information:[NSString stringWithFormat:@"Error Info:%@",error]];
        
    }else{
        //        [Alert cw_RemindException:@"Save Success" Information:[NSString stringWithFormat:@"File Path:%@",path]];
        
        [Task cw_openFileWithPath:dfuLogPath];
        
    }
}


#pragma mark-  laze load
-(FailOnlyItems *)failOnlyItems{
    if (!_failOnlyItems) {
        _failOnlyItems =[[FailOnlyItems alloc]init];
    }
    return _failOnlyItems;
}

-(ProgressBarVC *)progressBarVC{
    if (!_progressBarVC) {
        _progressBarVC =[[ProgressBarVC alloc]init];
    }
    return _progressBarVC;
}

-(TableDataDelegate *)tableDataDelegate{
    if (!_tableDataDelegate) {
//        __weak __typeof(self)weakSelf = self;
        __weak __typeof(&*self)weakSelf = self;
        _tableDataDelegate = [[TableDataDelegate alloc]initWithTaleView:_itemsTableView];
        _tableDataDelegate.tableViewForTableColumnCallback = ^(id view, NSInteger row, NSDictionary *data,NSString *idfix) {
            if ([idfix isEqualToString:id_record]) {
                BOOL isfail = [[data objectForKey:key_is_fail] boolValue];
                NSButton *btn = (NSButton *)view;
                if (isfail) {
                    
                    btn.layer.backgroundColor = [NSColor systemRedColor].CGColor;
                }else{
                    btn.layer.backgroundColor = [NSColor systemGreenColor].CGColor;
                }
                
            }else if([idfix isEqualToString:id_index]) {
                NSTextField *textView = (NSTextField *)view;
                textView.stringValue =[ NSString stringWithFormat:@"%ld",row+1];
            }
            
        };
        //        __weak __typeof(self)weakSelf = self;
        //        _tableDataDelegate.selectionChangedCallback = ^(NSInteger index, NSDictionary *item_data) {
        //
        //            //            __strong __typeof(weakSelf)strongSelf = weakSelf;
        //            NSString *record_path = [item_data objectForKey:key_record_path];
        //            BOOL isfail = [[item_data objectForKey:key_is_fail] boolValue];
        //            if (isfail) {
        //
        //                [weakSelf.failOnlyItems showViewOnViewController:weakSelf];
        //                weakSelf.failOnlyItems.recordPath = record_path;
        //            }
        //        };
        
        
        _tableDataDelegate.tableViewRowDoubleClickCallback = ^(NSInteger index, NSDictionary *item_data) {
            
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            NSString *record_path = [item_data objectForKey:key_record_path];
            BOOL isfail = [[item_data objectForKey:key_is_fail] boolValue];
            if (isfail) {
                //        self.failOnlyItems.title =mode.recordPath;
                [strongSelf.failOnlyItems showViewOnViewController:weakSelf];
                strongSelf.failOnlyItems.recordPath = record_path;
            }
        };
        
        
        
        _tableDataDelegate.buttonClickCallback = ^(NSInteger index, NSDictionary *item_data) {
            
            //            __strong __typeof(weakSelf)strongSelf = weakSelf;
            NSString *record_path = [item_data objectForKey:key_record_path];
            if ([FileManager cw_isFileExistAtPath:record_path]) {
                [Task cw_openFileWithPath:record_path.stringByDeletingLastPathComponent];
            }
            
        };
        
        _tableDataDelegate.tableViewdidClickColumnCallback = ^(NSString *identifier, NSInteger clickIndex) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([identifier isEqualToString:id_fail_list]) {
                
                if (strongSelf.fail_items_data.count) {
//                    weakSelf.items_datas = nil;
                    [strongSelf.tableDataDelegate setData:strongSelf.fail_items_data];

                    [strongSelf.itemsTableView reloadData];
                }
            }else if ([identifier isEqualToString:id_slot]){
                if (strongSelf.slotSort_items_data.count) {
                    [strongSelf.tableDataDelegate setData:strongSelf.slotSort_items_data];
                    [strongSelf.itemsTableView reloadData];
                }

            }else if ([identifier isEqualToString:id_test_time]){
                if (strongSelf.testTimeSort_items_data.count) {
                    [strongSelf.tableDataDelegate setData:strongSelf.testTimeSort_items_data];
                    [strongSelf.itemsTableView reloadData];
                }

            }else if ([identifier isEqualToString:id_start_time]){
                if (strongSelf.startTimeSort_items_data.count) {
                    [strongSelf.tableDataDelegate setData:strongSelf.startTimeSort_items_data];
                    [strongSelf.itemsTableView reloadData];
                }

            }
            
            
            
        };
        
    }
    return _tableDataDelegate;
}


-(void)doubleClick:(NSTableView *)tableview{
    NSInteger row = [tableview selectedRow];
    if (row == -1 || !self.fail_items_data.count)
    {
        return;
    }

    NSDictionary *dict = self.tableDataDelegate.getData[row];

    NSString *recordPath = [dict objectForKey:key_record_path];
    BOOL isFail = [[dict objectForKey:key_is_fail] boolValue];
    if (isFail) {
//        self.failOnlyItems.title =mode.recordPath;
        [self.failOnlyItems showViewOnViewController:self];
        self.failOnlyItems.recordPath = recordPath;
    }

}
//


- (void)keyDown:(NSEvent *)event{
    
    if (event.keyCode == 51) {
        [self deleteRows:nil];
    }
    else{
        return;
    }

}



- (IBAction)deleteRows:(NSButton *)sender {
//    NSDate *date = [NSDate date];
    
    NSString *pwd_input = [Alert cw_passwordBox:@"This operation will delete log selected!" defaultValue:@""];
    if (pwd_input==nil) {
        return;
    }
    NSString *pwd = [NSString cw_stringFromDate:[NSDate date] dateFormat:@"yyyyMM"];
    if ([pwd isNotEqualTo:pwd_input]) {
        [Alert cw_messageBox:@"Warning" Information:@"Wrong Password!!!"];
        return;
    }
    if (self.itemsTableView.selectedRowIndexes.count>0) {
        NSMutableArray *dataArr =[[NSMutableArray alloc]initWithArray:self.tableDataDelegate.getData];
        
        NSInteger firstIndex = self.itemsTableView.selectedRowIndexes.firstIndex;
        NSInteger lastIndex = self.itemsTableView.selectedRowIndexes.lastIndex;
        
        
        for (NSInteger i = firstIndex; i<=lastIndex; i++) {
            NSDictionary *dict = dataArr[i];
            NSString * record_path = [NSString stringWithFormat:@"%@",[dict objectForKey:key_record_path]] ;
            NSString *logPath = record_path.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
            [FileManager cw_removeItemAtPath:logPath];
        }
//        [self.itemsTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
////            [newDataArr removeObjectAtIndex:idx];
//            NSDictionary *dict = dataArr[idx];
//            NSString * record_path = [dict objectForKey:id_record];
//            NSString *logPath = record_path.stringByDeletingPathExtension.stringByDeletingLastPathComponent;
//            NSLog(@"1");
//        }];
        [self.tableDataDelegate deleteDataIndexes:self.itemsTableView.selectedRowIndexes];
      
        [self updateAllIWithtemsData:self.tableDataDelegate.getData];
        
        
        [self.itemsTableView reloadData];
        
        
    }else{
        [Alert cw_messageBox:@"Warning" Information:@"table row is not selected!!"];
    }
}


@end
