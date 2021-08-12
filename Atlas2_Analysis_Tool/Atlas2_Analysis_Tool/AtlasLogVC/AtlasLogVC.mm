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


@interface AtlasLogVC ()
@property (unsafe_unretained) IBOutlet NSTextView *logview;
    
//@property (nonatomic,strong) NSArray<NSDictionary *> *items_datas;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *origin_items_data;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *fail_items_data;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *timeSort_items_data;
//@property (nonatomic,strong) NSMutableArray<SnVauleMode *> *sn_datas;
@property (weak) IBOutlet NSTableView *itemsTableView;
//@property (weak) IBOutlet NSTableView *snTableView;
@property (weak) IBOutlet NSTextField *labelPath;
//@property (nonatomic, strong) FMDatabase *db;
@property (weak) IBOutlet FileDragView *logDropView;
@property (weak) IBOutlet NSTextField *labelCount;
@property (strong,nonatomic)FailOnlyItems *failOnlyItems;
@property(nonatomic,strong)TableDataDelegate *tableDataDelegate;


@end

@implementation AtlasLogVC{
    NSString *dfuLogPath;
//    RedisInterface *myRedis;
 
}
//- (void)redis_set
//{
//    myRedis->SetString("csv_all", "0.01,0.03\n0.02,0.05,0.8\n");
//    myRedis->SetString("Audio HP_MIC_China_Mode_Loopback China_Mode_HP_Left_Loopback_@-5dB_Frequency", "0.01,0.03");
//    myRedis->SetString("row1", "0.01,0.03,0.02");
//    myRedis->SetString("row2", "0.01,0.03,0.02");
//    myRedis->SetString("one_item", "0.01,0.03,0.02");
//
//    myRedis->SetString("Audio HP_MIC_China_Mode_Loopback China_Mode_HP_Left_Loopback_@-5dB_Peak_Power", "0.05,0.04,0.06");
//    myRedis->SetString("test_item_3", "350");
//
//    myRedis->SetString("test_item_1", "0.01,0.03,0.02");
//    myRedis->SetString("test_item_2", "1.01,1.03,0.02");
//    myRedis->SetString("test_item_3", "2.01,3.03,0.02");
//}

//- (void)redis_get
//{
//
//    const char *str_char = myRedis->GetString("csv_all");
////    NSString *str = [NSString stringWithUTF8String:str_char];
//    NSString *string = [[NSString alloc] initWithCString:str_char encoding:NSUTF8StringEncoding];
//    NSLog(@"1");
//
//}
//-(BOOL)OpenRedisServer
//{
//    NSString *killRedis = @"ps -ef |grep -i redis-server |grep -v grep|awk '{print $2}' |xargs kill -9";
//    system([killRedis UTF8String]);
//
//    NSString *file = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"redis-server&"] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
//
//    system([file UTF8String]);
//    return true;
//}
- (void)viewDidLoad {
    [super viewDidLoad];
    
//    clickIndexTableColumn = 0;
//    system("/usr/bin/ulimit -n 8192");
//    [self OpenRedisServer];
//    myRedis = new RedisInterface;  // redis client connect
//    myRedis->Connect();
    
   
    self.labelCount.stringValue = @"Test Total Count:0   Fail Count:0   Pass Count:0   rate:0";
    NSString *deskPath = [NSString cw_getUserPath];
    dfuLogPath =[deskPath stringByAppendingPathComponent:@"DFU_Tool_Log"];
    [FileManager cw_createFile:dfuLogPath isDirectory:YES];
    
//    self.items_datas = [[NSMutableArray alloc]init];
    self.origin_items_data = [[NSMutableArray alloc]init];
    self.fail_items_data = [[NSMutableArray alloc]init];
    self.timeSort_items_data = [[NSMutableArray alloc]init];
    [self.itemsTableView setDoubleAction:@selector(doubleClick:)];
    self.tableDataDelegate.owner = self.itemsTableView;
    

}

- (IBAction)add_csv_click:(NSButton *)sender {
    //    [FileManager openPanel:^(NSString * _Nonnull path) {
//    [self redis_set];
    
    
    NSString *path =self.logDropView.stringValue;
    [self.fail_items_data removeAllObjects];
    [self.origin_items_data removeAllObjects];
    [self.timeSort_items_data removeAllObjects];

    self.labelCount.stringValue = @"";//@"Test Total Count:0 Fail Count:0 Pass Count:0"
    if (!path.length) {

        [self.tableDataDelegate reloadTableViewWithData:nil];
        return;
    }
//    NSString *path = @"/Users/ciweiluo/Desktop/atlas_log/unit-archive";
//    NSLog(@"%@", [NSString stringWithFormat:@"CW+++++path:%@",path]);
//    CSVParser *csv = [[CSVParser alloc]init];
//    NSMutableArray *mutArray = nil;
//    NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        
        [self.tableDataDelegate reloadTableViewWithData:nil];
        return;
    }
//    NSString *home = [@"~" stringByExpandingTildeInPath];
    NSMutableArray *files = [[NSMutableArray alloc] init];
    NSString *filename;
    
    for (filename in [manager enumeratorAtPath:path]) {
        
        if ([filename containsString:@"records.csv"]) {
            [files addObject:filename];
        }
    }
    if (files.count < 1) {
        [self.itemsTableView reloadData];
        return;
    }
    NSMutableArray *item_mode_arr = [[NSMutableArray alloc]init];
    NSMutableArray *item_mode_pass_arr=[[NSMutableArray alloc]init];
    NSMutableArray *item_mode_fail_arr=[[NSMutableArray alloc]init];
    int i = 1;
    for (filename in files) {
        ItemMode *item_mode = [[ItemMode alloc]init];
        NSArray *pathArr = [filename cw_componentsSeparatedByString:@"/"];
        if (pathArr.count<2) {
            [self.itemsTableView reloadData];
            return;
        }
        item_mode.recordPath = [NSString stringWithFormat:@"%@/%@",path,filename];
        NSString*user_path =[NSString stringWithFormat:@"%@/user",item_mode.recordPath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent];
        item_mode.slot = @"Unkonw";
        for (NSString *ch_name in [manager enumeratorAtPath:user_path]) {
            NSString *ch_name1 = [ch_name stringByReplacingOccurrencesOfString:@"/server.log" withString:@""];
            if ([ch_name containsString:@"RPC_CH"]) {
                item_mode.slot = [ch_name1 stringByReplacingOccurrencesOfString:@"RPC_CH" withString:@"Slot"];
                
            }
        }
        item_mode.sn = pathArr[0];
        item_mode.startTime = pathArr[1];
        NSString *recordPath = [path stringByAppendingPathComponent:filename];
//        NSString *recordContent = [FileManager cw_readFromFile:recordPath];
        CSVParser *csv = [[CSVParser alloc]init];
        NSArray *csvArray = nil;
        if ([csv openFile:recordPath]) {
            csvArray = [csv parseFile];
        }
        NSMutableString *failList = [NSMutableString stringWithString:@""];
        NSEnumerator *enumer=[csvArray objectEnumerator];
        NSArray *itemInfo;
        while (itemInfo=[enumer nextObject]) {
//            NSLog(@"%@----%@",itemInfo,[NSThread currentThread]);
            if (itemInfo.count<12) {
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
        i = i + 1;
        NSLog(@"%@",filename);
        [item_mode_arr addObject:item_mode];
    }
    
//    [self.origin_items_data addObjectsFromArray:item_mode_arr];
//
//
//    self.items_datas =item_mode_arr;
    
    
//    [self.fail_items_data addObjectsFromArray:item_mode_fail_arr];
//    [self.fail_items_data addObjectsFromArray:item_mode_pass_arr];
    NSInteger total_count = item_mode_arr.count ? item_mode_arr.count : 0;
    NSInteger fail_count = item_mode_fail_arr.count ? item_mode_fail_arr.count : 0;
    NSInteger pass_count = item_mode_pass_arr.count ? item_mode_pass_arr.count : 0;
    NSInteger rate = 0;
    if (total_count>0 ) {
        rate = 100*pass_count/total_count;
    }
    self.labelCount.stringValue = [NSString stringWithFormat:@"Test Total Count:%ld   Fail Count:%ld   Pass Count:%ld   rate:%ld%%",(long)total_count,(long)fail_count,(long)pass_count,(long)rate];//@"Test Total Count:0 Fail Count:0 Pass Count:0"
    
    
//    NSMutableArray *tableData_dic = [[NSMutableArray alloc]init];
//    for (ItemMode *mode in item_mode_arr) {
//        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//        [dict setObject:[NSString stringWithFormat:@"%ld",(long)mode.index] forKey:id_index];
//        [dict setObject:mode.startTime forKey:id_start_time];
//        [dict setObject:mode.sn forKey:id_sn];
//        [dict setObject:mode.failList forKey:id_fail_list];
//        [dict setObject:@(mode.isFail) forKey:key_is_fail];
//        [dict setObject:mode.recordPath forKey:key_record_path];
//        [dict setObject:[NSImage imageNamed:NSImageNameFolder] forKey:id_record];
//        [self.origin_items_data addObject:dict];
//
//    }
    
    self.origin_items_data = [ItemMode getDicArrayWithItemModeArr:item_mode_arr];
    self.fail_items_data = [ItemMode getDicArrayWithItemModeArr:item_mode_fail_arr];
    self.timeSort_items_data = [self getTimeSortItemsData:self.origin_items_data];
    
//    [self.timeSort_items_data removeAllObjects];
//    for (ItemMode *mode in item_mode_fail_arr) {
//        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//        [dict setObject:[NSString stringWithFormat:@"%ld",(long)mode.index] forKey:id_index];
//        [dict setObject:mode.startTime forKey:id_start_time];
//        [dict setObject:mode.sn forKey:id_sn];
//        [dict setObject:mode.failList forKey:id_fail_list];
//        [dict setObject:@(mode.isFail) forKey:key_is_fail];
//        [dict setObject:mode.recordPath forKey:key_record_path];
//        [dict setObject:[NSImage imageNamed:NSImageNameFolder] forKey:id_record];
//        [self.fail_items_data addObject:dict];
//
//    }
//
    [self.tableDataDelegate reloadTableViewWithData:self.origin_items_data];
    //    }];
    
//    [self save:nil];
}

-(NSMutableArray *)getTimeSortItemsData:(NSMutableArray<NSDictionary *>*)itemsData{
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
    NSArray *arr = [str cw_componentsSeparatedByString:@"."];
    NSString *timeStr = arr[0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //需要设置为和字符串相同的格式
    [dateFormatter setDateFormat:@"yyyyMMdd_H-mm-ss"];
    NSDate *localDate = [dateFormatter dateFromString:timeStr];
    
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
            [Task cw_openFileWithPath:record_path.stringByDeletingLastPathComponent];
        };
        
        _tableDataDelegate.tableViewdidClickColumnCallback = ^(NSString *identifier, NSInteger clickIndex) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([identifier isEqualToString:id_fail_list]) {
                if (strongSelf.fail_items_data.count != strongSelf.origin_items_data.count) {
//                    weakSelf.items_datas = nil;
                    if (clickIndex % 2 == 1) {
                        
//                        weakSelf.items_datas = weakSelf.fail_items_data;
                        [strongSelf.tableDataDelegate setData:strongSelf.fail_items_data];
                    }else{
                        
//                        weakSelf.items_datas = weakSelf.origin_items_data;
                        [strongSelf.tableDataDelegate setData:strongSelf.origin_items_data];
                    }
                    [strongSelf.itemsTableView reloadData];
                }
            }else if ([identifier isEqualToString:id_start_time]){
                
                if (clickIndex % 2 == 1) {
                    
                    //                        weakSelf.items_datas = weakSelf.fail_items_data;
                    [strongSelf.tableDataDelegate setData:strongSelf.timeSort_items_data];
                }else{
                    
                    //                        weakSelf.items_datas = weakSelf.origin_items_data;
                    [strongSelf.tableDataDelegate setData:strongSelf.origin_items_data];
                }
                [strongSelf.itemsTableView reloadData];
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

    NSDictionary *dict = self.origin_items_data[row];

    NSString *recordPath = [dict objectForKey:key_record_path];
    BOOL isFail = [[dict objectForKey:key_is_fail] boolValue];
    if (isFail) {
//        self.failOnlyItems.title =mode.recordPath;
        [self.failOnlyItems showViewOnViewController:self];
        self.failOnlyItems.recordPath = recordPath;
    }

}
//

//
//- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
//
//    NSString *identifier = tableColumn.identifier;
//    if (!self.fail_items_data.count) {
//        return;
//    }
//    if ([identifier isEqualToString:@"FailList"]) {
//        clickIndexTableColumn = clickIndexTableColumn + 1;
//        self.items_datas = nil;
//        if (clickIndexTableColumn % 2 == 1) {
//
//            self.items_datas = self.fail_items_data;
//        }else{
//
//            self.items_datas = self.origin_items_data;
//        }
//        [self.itemsTableView reloadData];
////        self.data
//
//    }
//}
//- (IBAction)recordBtnClick:(NSButton *)btn {
//
//    NSInteger row =btn.tag;
//    if (row == -1 || !self.fail_items_data.count)
//    {
//        return;
//    }
//    ItemMode *mode = self.items_datas[row];
//    NSString *record = mode.recordPath.stringByDeletingLastPathComponent;
//    [Task termialWithCmd:[NSString stringWithFormat:@"open %@",record]];
//
//
////    if (mode.isFail) {
////        //        self.failOnlyItems.title =mode.recordPath;
////        [self.failOnlyItems showViewOnViewController:self];
////        self.failOnlyItems.recordPath = mode.recordPath;
////    }
//
//}
//
//
//- (void)tableViewSelectionDidChange:(NSNotification *)notification{
//
//    NSLog(@"s");
//
//    NSTableView *tableView = notification.object;
//    if (tableView == self.itemsTableView) {
//        NSInteger index = tableView.selectedRow;
//        if (self.items_datas.count) {
//            ItemMode *item = self.items_datas[index];
////            [self.sn_datas removeAllObjects];
////            [self.sn_datas addObjectsFromArray:item.SnVauleArray];
////            [self.snTableView reloadData];
//        }
//
//    }
//}
//


@end
