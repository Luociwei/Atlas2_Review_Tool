//
//  ViewController.m
//  SC_Eowyn
//
//  Created by ciwei luo on 2020/3/31.
//  Copyright © 2020 ciwei luo. All rights reserved.
//

#import "AtlasScritVC.h"
#import "ScritItemMode.h"
#import "FailOnlyItems.h"


@interface AtlasScritVC ()
@property (unsafe_unretained) IBOutlet NSTextView *logview;

@property (nonatomic,strong) NSMutableArray<NSDictionary *> *origin_items_datas;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *fail_items_datas;

@property (weak) IBOutlet NSTableView *itemsTableView;

@property (weak) IBOutlet NSTextField *labelPath;
//@property (nonatomic, strong) FMDatabase *db;
@property (weak) IBOutlet FileDragView *logDropView;
//@property (weak) IBOutlet NSTextField *labelCount;
//@property (strong,nonatomic)FailOnlyItems *failOnlyItems;
@property(nonatomic,strong)TableDataDelegate *tableDataDelegate;


@end

@implementation AtlasScritVC{
    NSString *dfuLogPath;
  
}


- (void)viewDidLoad {
    [super viewDidLoad];

//    self.labelCount.stringValue = @"Test Total Count:0   Fail Count:0   Pass Count:0   rate:0";
    NSString *userPath = [NSString cw_getUserPath];
    dfuLogPath =[userPath stringByAppendingPathComponent:@"DFU_Tool_Log"];
    [FileManager cw_createFile:dfuLogPath isDirectory:YES];
    
//    self.items_datas = [[NSMutableArray alloc]init];
    self.origin_items_datas = [[NSMutableArray alloc]init];
//    self.fail_items_datas = [[NSMutableArray alloc]init];
    [self.itemsTableView setDoubleAction:@selector(doubleClick:)];
    self.tableDataDelegate.owner = self.itemsTableView;
    

}

-(NSArray *)getArrWithPath:(NSString *)path{
    CSVParser *csv = [[CSVParser alloc]init];
    NSMutableArray *csvArray = nil;
    if ([csv openFile:path]) {
        csvArray = [csv parseFile];
    }else{
        return csvArray;
    }
    
//    for (int j = 1; j<csvArray.count; j++) {
//        NSArray *arr = csvArray[j];
//
//        }
    NSString *last_subTestName = @"";
//    NSMutableArray *newCsvArr = [[NSMutableArray alloc]init];
    for (NSMutableArray *arr in csvArray) {
//        NSMutableArray *mutArr = [[NSMutableArray alloc]initWithArray:arr];
        NSString *subTestName = arr[0];
        if (subTestName.length) {
            last_subTestName = subTestName;
        }else{
            arr[0] = last_subTestName;
        }
//        [newCsvArr addObject:mutArr];
    }
    
    return csvArray;
}

- (IBAction)add_csv_click:(NSButton *)sender
{
    //    [FileManager openPanel:^(NSString * _Nonnull path) {
    NSString *path =self.logDropView.stringValue;
    
   
    [self.origin_items_datas removeAllObjects];

//    self.labelCount.stringValue = @"";//@"Test Total Count:0 Fail Count:0 Pass Count:0"
    if (!path.length) {
        [self.tableDataDelegate setData:nil];
        [self.itemsTableView reloadData];
        return;
    }
//    NSString *path = @"/Users/ciweiluo/Desktop/atlas_log/unit-archive";
//    NSLog(@"%@", [NSString stringWithFormat:@"CW+++++path:%@",path]);
//    CSVParser *csv = [[CSVParser alloc]init];
//    NSMutableArray *mutArray = nil;
//    NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        [self.tableDataDelegate setData:nil];
        [self.itemsTableView reloadData];
        return;
    }
    NSString *mainCsvPath = [path stringByAppendingPathComponent:@"Main.csv"];
    if (![manager fileExistsAtPath:mainCsvPath]) {
        [self.tableDataDelegate setData:nil];
        [self.itemsTableView reloadData];
        return;
    }
    
    NSString *limitCsvPath = [path stringByAppendingPathComponent:@"Limits.csv"];
    NSString *limitsContent = [FileManager cw_readFromFile:limitCsvPath];

    NSArray *csvMainArray =[self getArrWithPath:mainCsvPath];
    NSMutableArray *item_mode_arr = [[NSMutableArray alloc]init];
    NSMutableDictionary *techCsvPathDic =[[NSMutableDictionary alloc]init];
    for (int i =1; i<csvMainArray.count; i++) {
//        ScritItemMode *scritItemMode = [[ScritItemMode alloc]init];
        NSString *testName = csvMainArray[i][1];
        NSString *subTestName = csvMainArray[i][0];
//        scritItemMode.index = i;
        
        NSArray *techCsvArr = nil;

        NSString *techCsvPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"Tech/%@.csv",testName]];
        if (![manager fileExistsAtPath:techCsvPath]) {
            continue;
        }
        if (![techCsvPathDic.allKeys containsObject:techCsvPath]) {
            techCsvArr = [self getArrWithPath:techCsvPath];
            [techCsvPathDic setObject:techCsvArr forKey:techCsvPath];
        }else{
            techCsvArr = [techCsvPathDic objectForKey:techCsvPath];
        }
        
        for (int j = 1; j<techCsvArr.count; j++) {
            NSArray *arr = techCsvArr[j];
            if ([arr[0] isEqualToString:subTestName]) {
                ScritItemMode *scritItemMode = [[ScritItemMode alloc]init];
                scritItemMode.testName = csvMainArray[i][1];
                scritItemMode.subTestName = csvMainArray[i][0];
                scritItemMode.index = item_mode_arr.count+1;
                scritItemMode.subSubTestName = arr[7];
                scritItemMode.params = arr[7];
                scritItemMode.function = arr[1];
                scritItemMode.command = arr[10];
                NSArray *limitArr = [self getLimitWithSubTestName:scritItemMode.subTestName subSubTestName:scritItemMode.subSubTestName limitsContent:limitsContent];
                scritItemMode.lowLimit = limitArr[0];
                scritItemMode.upperLimit = limitArr[1];
                scritItemMode.unit =limitArr[2];
//                scritItemMode.function = arr[1];
                [item_mode_arr addObject:scritItemMode];
            }
        }
        
    }
    
    NSArray *item_dict_arr = [ScritItemMode getDicArrayWithScritItemModeArr:item_mode_arr];
    [self.origin_items_datas addObjectsFromArray:item_dict_arr];

    [self.tableDataDelegate setData:item_dict_arr];
    [self.itemsTableView reloadData];

}

-(NSArray *)getLimitWithSubTestName:(NSString *)subTestName subSubTestName:(NSString *)subSubTestName limitsContent:(NSString *)limitsContent{
    NSMutableArray *limitsArr = [[NSMutableArray alloc]initWithObjects:@"",@"",@"", nil];
    if (!limitsContent.length || !subTestName.length || !subSubTestName.length) {
        return limitsArr;
    }else{
        NSArray *limitsContentArr = [limitsContent cw_componentsSeparatedByString:@"\n"];
        [limitsContentArr enumerateObjectsUsingBlock:^(NSString *row_str, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([row_str containsString:subTestName]&&[row_str containsString:subSubTestName]) {
                NSArray *row_Arr = [row_str cw_componentsSeparatedByString:@","];
                if (row_Arr.count>5) {
                    limitsArr[0] = row_Arr[3];
                    limitsArr[1] = row_Arr[4];
                    limitsArr[2] = row_Arr[2];
                }
                *stop = YES;
                
            }
        }];
    }
    
    
    return limitsArr;
}

- (IBAction)save:(id)sender {

    NSArray *dataArr = [self.tableDataDelegate getData];
    if (!dataArr.count) {
        return;
    }
    NSString *path = [dfuLogPath stringByAppendingPathComponent:@"Atlas2_Script.csv"];
    NSMutableString *text = [[NSMutableString alloc] init];
    NSArray *columns = self.itemsTableView.tableColumns;
    for (NSTableColumn *column in columns) {
        [text appendString:column.identifier];
        [text appendString:@","];
    }
    [text appendString:@"\n"];
    
    for (int m =0;m<dataArr.count;m++) {
        
        NSDictionary *item_dic = dataArr[m];
        //        NSString *key = [columns[m] identifier];
        //        [text appendString:[item_mode getVauleWithKey:key]];
        
        for (int i =0; i<columns.count; i++) {
            
            NSString *key = [columns[i] identifier];
            NSString *str= [item_dic objectForKey:key];
            if ([key isEqualToString:id_AdditionalParameters]) {
               str = [str stringByReplacingOccurrencesOfString:@"," withString:@";"];
            }
            [text appendString:str];
            
            if (i!=columns.count-1) {
                [text appendString:@","];
            }else{
                [text appendString:@"\n"];
            }
        }
        
    }
    
    NSError *error;
//    [FileManager cw_writeToFile:path content:text];
    [text writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&error];
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
//-(FailOnlyItems *)failOnlyItems{
//    if (!_failOnlyItems) {
//        _failOnlyItems =[[FailOnlyItems alloc]init];
//    }
//    return _failOnlyItems;
//}

-(TableDataDelegate *)tableDataDelegate{
    if (!_tableDataDelegate) {
        __weak __typeof(self)weakSelf = self;
        _tableDataDelegate = [[TableDataDelegate alloc]initWithTaleView:_itemsTableView isDargData:YES];
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
        
        _tableDataDelegate.tableViewdidClickColumnCallback = ^(NSString *identifier, NSInteger clickIndex) {
            NSArray *dataArr = [weakSelf.tableDataDelegate getData];
            
        };
        
//        _tableDataDelegate.tableViewRowDoubleClickCallback = ^(NSInteger index, NSDictionary *item_data) {
//
//
//        };
//
        
        
    }
    return _tableDataDelegate;
}


-(void)doubleClick:(NSTableView *)tableview{
    NSInteger row = [tableview selectedRow];

}
//

//
//- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
//
//    NSString *identifier = tableColumn.identifier;
//    if (!self.fail_items_datas.count) {
//        return;
//    }
//    if ([identifier isEqualToString:@"FailList"]) {
//        clickIndexTableColumn = clickIndexTableColumn + 1;
//        self.items_datas = nil;
//        if (clickIndexTableColumn % 2 == 1) {
//
//            self.items_datas = self.fail_items_datas;
//        }else{
//
//            self.items_datas = self.origin_items_datas;
//        }
//        [self.itemsTableView reloadData];
////        self.data
//
//    }
//}
//- (IBAction)recordBtnClick:(NSButton *)btn {
//
//    NSInteger row =btn.tag;
//    if (row == -1 || !self.fail_items_datas.count)
//    {
//        return;
//    }
//    ScritItemMode *mode = self.items_datas[row];
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
//            ScritItemMode *item = self.items_datas[index];
////            [self.sn_datas removeAllObjects];
////            [self.sn_datas addObjectsFromArray:item.SnVauleArray];
////            [self.snTableView reloadData];
//        }
//
//    }
//}
//

//- (void)tableViewColumnConfig {
//    NSArray *items =[self tableColumnItems];
//    if(items){
//        [self.itemsTableView.tableView cw_updateColumnsWithItems:items];
//    }
//}
//- (NSArray*)tableColumnItems {
//
//    TableColumnItem *field_index = [[TableColumnItem alloc]init];
//    field_index.title      = @"Index";
//    field_index.identifier = id_index;
//    field_index.width      = 35;
//    field_index.minWidth   = 25;
//    field_index.maxWidth   = 60;
//    field_index.editable   = NO;
//    field_index.headerAlignment = NSLeftTextAlignment;
//    field_index.cellType = TableColumnCellTypeTextField;
//
//    TableColumnItem *field_sn = [[TableColumnItem alloc]init];
//    field_sn.title      = @"Sn";
//    field_sn.identifier = id_sn;
//    field_sn.width      = 150;
//    field_sn.minWidth   = 100;
//    field_sn.maxWidth   = 220;
//    field_sn.editable   = NO;
//    field_sn.headerAlignment = NSLeftTextAlignment;
//    field_sn.cellType = TableColumnCellTypeTextField;
//
//
//    TableColumnItem *field_startTime = [[TableColumnItem alloc]init];
//    field_startTime.title      = @"StartTime";
//    field_startTime.identifier = id_start_time;
//    field_startTime.width      = 220;
//    field_startTime.minWidth   = 160;
//    field_startTime.maxWidth   = 260;
//    field_startTime.editable   = NO;
//    field_startTime.headerAlignment = NSLeftTextAlignment;
//    field_startTime.cellType = TableColumnCellTypeTextField;
//
//
////    TableColumnItem *type = [[TableColumnItem alloc]init];
////    type.title      = @"Type";
////    type.identifier = @"type";
////    type.width      = 120;
////    type.minWidth   = 120;
////    type.maxWidth   = 160;
////    type.editable   = YES;
////    type.headerAlignment = NSLeftTextAlignment;
////    type.cellType = TableColumnCellTypeComboBox;
////    type.items = @[@"int",@"varchar",@"bool"];
//
//
////    TableColumnItem *length = [[TableColumnItem alloc]init];
////    length.title      = @"Size";
////    length.identifier = @"size";
////    length.width      = 120;
////    length.minWidth   = 120;
////    length.maxWidth   = 120;
////    length.editable   = YES;
////    length.headerAlignment = NSLeftTextAlignment;
////    length.cellType = TableColumnCellTypeTextField;
//
//
////    TableColumnItem *primary = [[TableColumnItem alloc]init];
////    primary.title      = @"Primary";
////    primary.identifier = @"primary";
////    primary.width      = 80;
////    primary.minWidth   = 80;
////    primary.maxWidth   = 120;
////    primary.editable   = YES;
////    primary.headerAlignment = NSLeftTextAlignment;
////    primary.cellType = TableColumnCellTypeCheckBox;
//
//
//    TableColumnItem *btn_record = [[TableColumnItem alloc]init];
//    btn_record.title      = @"Record";
//    btn_record.identifier = id_record;
//    btn_record.width      = 40;
//    btn_record.minWidth   = 30;
//    btn_record.maxWidth   = 60;
//    btn_record.cellType = TableColumnCellTypeImageView;
//
//    TableColumnItem *field_failList = [[TableColumnItem alloc]init];
//    field_failList.title      = @"FailList ↑↓";
//    field_failList.identifier = id_fail_list;
//    field_failList.width      = 2000;
//    field_failList.minWidth   = 300;
//    field_failList.maxWidth   = 8000;
//    field_failList.editable   = YES;
//    field_failList.headerAlignment = NSLeftTextAlignment;
//    field_failList.cellType = TableColumnCellTypeTextField;
//
//    return @[field_index,field_sn,field_startTime,btn_record,field_failList];
//}


@end
