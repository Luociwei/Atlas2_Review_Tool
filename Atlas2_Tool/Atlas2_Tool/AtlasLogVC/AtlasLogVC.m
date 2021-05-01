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
#import "TableDataDelegate.h"

@interface AtlasLogVC ()
@property (unsafe_unretained) IBOutlet NSTextView *logview;
    
@property (nonatomic,strong) NSArray<ItemMode *> *items_datas;
@property (nonatomic,strong) NSMutableArray<ItemMode *> *origin_items_datas;
@property (nonatomic,strong) NSMutableArray<ItemMode *> *fail_items_datas;
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
    NSInteger clickIndexTableColumn;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    clickIndexTableColumn = 0;
    self.labelCount.stringValue = @"Test Total Count:0   Fail Count:0   Pass Count:0   rate:0";
    NSString *deskPath = [NSString cw_getUserPath];
    dfuLogPath =[deskPath stringByAppendingPathComponent:@"DFU_Tool_Log"];
    [FileManager cw_createFile:dfuLogPath isDirectory:YES];
    
//    self.items_datas = [[NSMutableArray alloc]init];
    self.origin_items_datas = [[NSMutableArray alloc]init];
    self.fail_items_datas = [[NSMutableArray alloc]init];
    [self initTableView:self.itemsTableView];

}

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
-(void)initTableView:(NSTableView *)tableView{
    
    self.tableDataDelegate = [[TableDataDelegate alloc]initWithTaleView:tableView];
//    tableView.dataSource =self.tableDataDelegate;
//    tableView.delegate = self.tableDataDelegate;
//    [tableView setDoubleAction:@selector(doubleClick:)];
    tableView.headerView.hidden=NO;
    tableView.usesAlternatingRowBackgroundColors=YES;
    tableView.rowHeight = 20;
    tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask |NSTableViewSolidVerticalGridLineMask ;
    
}



- (IBAction)add_csv_click:(NSButton *)sender {
    //    [FileManager openPanel:^(NSString * _Nonnull path) {
    NSString *path =self.logDropView.stringValue;
    [self.fail_items_datas removeAllObjects];
    [self.origin_items_datas removeAllObjects];
    self.items_datas =nil;
    self.labelCount.stringValue = @"";//@"Test Total Count:0 Fail Count:0 Pass Count:0"
    if (!path.length) {
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
        [self.itemsTableView reloadData];
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
    
    [self.origin_items_datas addObjectsFromArray:item_mode_arr];
    
    
    self.items_datas =item_mode_arr;
    
    
    [self.fail_items_datas addObjectsFromArray:item_mode_fail_arr];
//    [self.fail_items_datas addObjectsFromArray:item_mode_pass_arr];
    NSInteger total_count = item_mode_arr.count ? item_mode_arr.count : 0;
    NSInteger fail_count = item_mode_fail_arr.count ? item_mode_fail_arr.count : 0;
    NSInteger pass_count = item_mode_pass_arr.count ? item_mode_pass_arr.count : 0;
    NSInteger rate = 0;
    if (total_count>0 ) {
        rate = 100*pass_count/total_count;
    }
    self.labelCount.stringValue = [NSString stringWithFormat:@"Test Total Count:%ld   Fail Count:%ld   Pass Count:%ld   rate:%ld%%",(long)total_count,(long)fail_count,(long)pass_count,(long)rate];//@"Test Total Count:0 Fail Count:0 Pass Count:0"
    
    
    NSMutableArray *tableData = [[NSMutableArray alloc]init];
    for (ItemMode *mode in self.items_datas) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[NSString stringWithFormat:@"%ld",(long)mode.index] forKey:id_index];
        [dict setObject:mode.startTime forKey:id_start_time];
        [dict setObject:mode.sn forKey:id_sn];
        [dict setObject:mode.failList forKey:id_fail_list];
        [dict setObject:[NSImage imageNamed:NSImageNameFolder] forKey:id_record];
        [tableData addObject:dict];

    }
    [self.tableDataDelegate setData:tableData];
    [self.itemsTableView reloadData];
    //    }];
    
//    [self save:nil];
}



#pragma mark-  NSTableViewDataSource

//[_dataList count]?[[[_dataList objectAtIndex:section] objectForKey:@"subs"] count]:0;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    //返回表格共有多少行数据

    return [self.items_datas count];
}
-(void)doubleClick:(NSTableView *)tableview{
    NSInteger row = [tableview selectedRow];
    if (row == -1 || !self.fail_items_datas.count)
    {
        return;
    }

    ItemMode *mode = self.items_datas[row];
    if (mode.isFail) {
//        self.failOnlyItems.title =mode.recordPath;
        [self.failOnlyItems showViewOnViewController:self];
        self.failOnlyItems.recordPath = mode.recordPath;
    }

}
//
//#pragma mark-  NSTableViewDelegate
//- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//
//
//    NSString *identifier = tableColumn.identifier;
//    NSString *value = @"";
////    id textField;
//
//
//        ItemMode *item_data = self.items_datas[row];
//        item_data= self.items_datas[row];
////        item_data.index = row +1;
//        value=[item_data getVauleWithKey:identifier];
//
//
//
//
//    id view = [tableView makeViewWithIdentifier:identifier owner:self];
//
//    if(!view){
//
//
//        if ([[view class] isKindOfClass:[NSTextField class]]) {
//            NSTextField *textField =  [[NSTextField alloc]init];
//
//            textField.identifier = identifier;
//            textField = (NSTextField *)textField;
//            textField.wantsLayer=YES;
//            [textField setBezeled:NO];
//            [textField setDrawsBackground:NO];
//            view = textField ;
//
//        }else{
//            NSButton *checkBoxField =  [[NSButton alloc]init];
//            checkBoxField = (NSButton*)view;
//            checkBoxField.tag=row;
//            [checkBoxField setTarget:self];
//            [checkBoxField setAction:@selector(recordBtnClick:)];
//        }
//
//
//
//    }
//    else{
//
////        textField = (NSTextField*)view;
//        NSArray *subviews = [view subviews];
//
//        view = subviews[0];
//        if ([identifier isEqualToString:@"record"]){
//            NSButton *btn= subviews[0];
//            btn.tag=row;
//            btn.wantsLayer=YES;
//
//            if (item_data.isFail) {
//
//                btn.layer.backgroundColor = [NSColor systemRedColor].CGColor;
//            }else{
//                btn.layer.backgroundColor = [NSColor systemGreenColor].CGColor;
//            }
//        }else{
//            NSTextField *textf= subviews[0];
//            if(value.length){
////                textf.wantsLayer=YES;
////                if ([identifier isEqualToString:@"FailList"]) {
//////                    [textf setTextColor:[NSColor blueColor]];
////
////                    textf.layer.backgroundColor = [NSColor systemRedColor].CGColor;
////                }
//                //更新单元格的文本
//                [textf setStringValue: value];
//            }else{
////                if ([identifier isEqualToString:@"FailList"]) {
////                textf.layer.backgroundColor = [NSColor clearColor].CGColor;
////                }
//            }
//            textf.wantsLayer=YES;
//
////            if (item_data.isFail) {
////
////                textf.layer.backgroundColor = [NSColor systemRedColor].CGColor;
////            }else{
////                textf.layer.backgroundColor = [NSColor clearColor].CGColor;
////            }
//
//
//
//        }
//
//
//
//    }
//
//    return view;
//}
//
//
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
//-(FailOnlyItems *)failOnlyItems{
//    if (!_failOnlyItems) {
//        _failOnlyItems =[[FailOnlyItems alloc]init];
//    }
//    return _failOnlyItems;
//}
//
//-(TableDataDelegate *)tableDataDelegate{
//    if (!_tableDataDelegate) {
//        _tableDataDelegate =[[TableDataDelegate alloc]init];
//    }
//    return _tableDataDelegate;
//}
//-(void)test{
//    //    self.sn_datas =[[NSMutableArray alloc]init];
//    //    for (int i =0; i<5; i++) {
//    //        ItemMode *mode = [[ItemMode alloc]init];
//    //        mode.sn= [NSString stringWithFormat:@"item_%d",i];
//    //        mode.startTime = [NSString stringWithFormat:@"%d",i+5];
//    //        mode.failList = [NSString stringWithFormat:@"%d",i-5];
//    //        [self.items_datas addObject:mode];
//    //    }
//
//    //    for (int i =0; i<5; i++) {
//    //        SnVauleMode *mode = [[SnVauleMode alloc]init];
//    //        mode.sn= [NSString stringWithFormat:@"sn_%d",i];
//    //        mode.value = [NSString stringWithFormat:@"%d",i+5];
//    //        [self.sn_datas addObject:mode];
//    //    }
//    //
//
//    //    [self initTableView:self.snTableView];
//}

@end
