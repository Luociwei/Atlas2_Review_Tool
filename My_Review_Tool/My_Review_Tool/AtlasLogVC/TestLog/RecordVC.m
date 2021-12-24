//
//  FailOnlyItems.m
//  My_Review_Tool
//
//  Created by ciwei luo on 2021/4/26.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "RecordVC.h"

@interface RecordVC ()
//@property (nonatomic,strong)TextView *textView;
//@property (nonatomic,strong)NSView *textView1;
@property (weak) IBOutlet NSTextField *filePathView;

@property (weak) IBOutlet NSPopUpButton *popBtnSearch;
@property (weak) IBOutlet NSTableView *recordTableView;
@property(nonatomic,strong)TableDataDelegate *tableDataDelegate;
@property (nonatomic,strong) NSMutableArray<NSMutableDictionary *> *origin_items_data;
@property (nonatomic,strong) NSMutableArray<NSMutableDictionary *> *fail_items_data;
@property(nonatomic,strong)CSVParser *csv;

@property (weak) IBOutlet NSButton *btnShowAll;

@end

@implementation RecordVC

-(void)viewWillAppear{
    [super viewWillAppear];
    
    if (_recordPath.length) {
       
        self.filePathView.stringValue = [NSString stringWithFormat:@"FilePath:%@",_recordPath];;
        NSArray *csvArray = nil;
        if ([self.csv openFile:_recordPath]) {
            csvArray = [self.csv parseFile];
        }
        
        if (csvArray.count) {
            [self setRcordTableView:csvArray];
        }
 
    }else{
        self.filePathView.stringValue = [NSString stringWithFormat:@"FilePath:Not found."];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
//    self.textView = [[TextView alloc]init];
//    //    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
//    [self.view addSubview:self.textView];
//    self.textView1.frame = self.view.bounds;
//    [self setupAutolayout];
    
    [self.popBtnSearch cw_addItemsWithTitles:@[@"Filter",@"Search"]];
    self.origin_items_data = [[NSMutableArray alloc]init];
    self.fail_items_data = [[NSMutableArray alloc]init];
    self.csv = [[CSVParser alloc]init];
    self.tableDataDelegate.owner = self.recordTableView;

}
- (IBAction)filePathClick:(NSButton *)btn {
    NSString *file = [self.filePathView.stringValue stringByReplacingOccurrencesOfString:@"FilePath:" withString:@""];
    if ([FileManager cw_isFileExistAtPath:file]) {
        [FileManager cw_openFileWithPath:file.stringByDeletingLastPathComponent];
    }
    
}
- (IBAction)showAllItems:(NSButton *)btn {
    
    if (btn.state == 1) {
        [self.tableDataDelegate reloadTableViewWithData:self.fail_items_data];
    }else{
        [self.tableDataDelegate reloadTableViewWithData:self.origin_items_data];
    }
    
}
//
//-(void)setRecordPath:(NSString *)recordPath{
////    [self.textView clean];
//
//    if (![FileManager cw_isFileExistAtPath:recordPath]) {
//        [Alert cw_messageBox:@"Error!!!" Information:[NSString stringWithFormat:@"Not found the file path:%@,pls check.",recordPath]];
//        return;
//    }
//
//}

-(TableColumnItem *)setIndexTableColumnItem{
    TableColumnItem *tableColum = [[TableColumnItem alloc]init];
    tableColum.title      = @"index";
    tableColum.identifier = @"index";;
    tableColum.width      = 50;
    tableColum.minWidth   = 40;
    tableColum.maxWidth   = 80;
    tableColum.editable   = NO;
    tableColum.headerAlignment = NSLeftTextAlignment;
    tableColum.cellType = TableColumnCellTypeTextField;
    return tableColum;
}

- (void)setRcordTableView:(NSArray *)itemsArray {
    NSArray * itemTitleArr = itemsArray[0];
    NSMutableArray *columns = [[NSMutableArray alloc]init];
    [columns addObject:[self setIndexTableColumnItem]];
    for (int i = 0; i<itemTitleArr.count; i++) {
        TableColumnItem *tableColum = [[TableColumnItem alloc]init];
        tableColum.title      = itemTitleArr[i];
        tableColum.identifier = itemTitleArr[i];
        tableColum.width      = 100;
        tableColum.minWidth   = 60;
        tableColum.maxWidth   = 600;
        
        tableColum.editable   = NO;
        tableColum.headerAlignment = NSLeftTextAlignment;
        tableColum.cellType = TableColumnCellTypeTextField;
        [columns addObject:tableColum];
        
    }
    
    [self.recordTableView cw_updateColumnsWithItems:columns];
    
    [self.origin_items_data removeAllObjects];
    
    for (int i = 1; i<itemsArray.count; i++) {

        NSArray *itemArr = itemsArray[i];
        NSMutableDictionary *itemDict = [[NSMutableDictionary alloc]init];
//        [failItemDict setObject:@"" forKey:key_IsSearch];
        [itemDict setObject:@"" forKey:key_IsSearch];
        [itemDict setObject:@"0" forKey:key_is_fail];
        [itemDict setObject:[NSString stringWithFormat:@"%d",i] forKey:@"index"];
        for (int j =0; j<itemArr.count; j++) {
            if (itemArr.count != itemTitleArr.count) {
                continue;
            }
            NSString *vaule = itemArr[j];
            if (!vaule.length) {
                vaule = @"";
            }
            if ([itemTitleArr[j] isEqualToString:@"status"]&&[vaule.lowercaseString containsString:@"fail"]) {
                [itemDict setObject:@"1" forKey:key_is_fail];
            }
            [itemDict setObject:vaule forKey:itemTitleArr[j]];
            
        }
        if ([[itemDict objectForKey:key_is_fail] isEqualToString:@"1"]) {
            [self.fail_items_data addObject:itemDict];
        }
        [self.origin_items_data addObject:itemDict];
        
    }
    
    if (self.fail_items_data.count) {
        [self.tableDataDelegate reloadTableViewWithData:self.fail_items_data];
    }
}

- (IBAction)search:(NSSearchField *)searchField {
    
    NSString *content = searchField.stringValue.length ? searchField.stringValue : @"";
    [self.origin_items_data enumerateObjectsUsingBlock:^(NSMutableDictionary *itemDict, NSUInteger idx, BOOL * _Nonnull stop) {
        [itemDict setObject:@"" forKey:key_IsSearch];
        
    }];
    [self.btnShowAll setState:0];
    [self showAllItems:_btnShowAll];
    //[self.tableDataDelegate reloadTableViewWithData:self.origin_items_data];
    if (!content.length) {
        return;
    }
    
    NSMutableArray *itemsArr_copy = [[NSMutableArray alloc]initWithArray:self.origin_items_data];
    NSString *popBtnTitle = self.popBtnSearch.title;
    //    NSString *popBtnTitle2 = self.popBtnSearch.titleOfSelectedItem;
    //    @"Filter",@"Search"
    if ([popBtnTitle isEqualToString:@"Search"]) {
        [itemsArr_copy enumerateObjectsUsingBlock:^(NSMutableDictionary *itemDict, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [itemDict setObject:content forKey:key_IsSearch];
            
        }];
        [self.tableDataDelegate reloadTableViewWithData:itemsArr_copy];
    }else{
        
        NSMutableArray *filterArr = [[NSMutableArray alloc]init];
        [itemsArr_copy enumerateObjectsUsingBlock:^(NSMutableDictionary *itemDict, NSUInteger idx, BOOL * _Nonnull stop) {
            for (NSString *vaule in itemDict.allValues) {
                if ([vaule.lowercaseString containsString:content.lowercaseString]) {
                    [itemDict setObject:content forKey:key_IsSearch];
                    [filterArr addObject:itemDict];
                    break;
                }
            }
            
        }];
        
        [self.tableDataDelegate reloadTableViewWithData:filterArr];
        
        
    }
    
    
}



-(TableDataDelegate *)tableDataDelegate{
    if (!_tableDataDelegate) {
        //        __weak __typeof(self)weakSelf = self;
        _tableDataDelegate = [[TableDataDelegate alloc]initWithTaleView:_recordTableView isDargData:YES];
        _tableDataDelegate.tableViewForTableColumnCallback = ^(id view, NSInteger row, NSDictionary *data,NSString *identifier) {
            NSString *value = [data valueForKey:identifier];
            NSString *isFail =[data valueForKey:key_is_fail];
            NSTextField *textField = (NSTextField *)view;
            textField.wantsLayer = YES;
            if ([isFail isEqualToString:@"1"]) {
                textField.layer.backgroundColor = [NSColor systemRedColor].CGColor;
            }else{
                NSString *search_keyword =[data valueForKey:key_IsSearch];
                BOOL is_search = [value.lowercaseString containsString:search_keyword.lowercaseString];

                if (is_search) {

                    textField.layer.backgroundColor = [NSColor systemOrangeColor].CGColor;
                }else{
                    textField.layer.backgroundColor = [NSColor clearColor].CGColor;
                }
                
            }
            
        };
        
        _tableDataDelegate.tableViewdidClickColumnCallback = ^(NSString *identifier, NSInteger clickIndex) {
            
        };
        

    }
    return _tableDataDelegate;
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


@end
