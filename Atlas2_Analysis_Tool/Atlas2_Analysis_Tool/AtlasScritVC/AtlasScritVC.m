//
//  ViewController.m
//  SC_Eowyn
//
//  Created by ciwei luo on 2020/3/31.
//  Copyright © 2020 ciwei luo. All rights reserved.
//

#import "AtlasScritVC.h"
#import "ScritItemMode.h"
#import "LuaFunction.h"


@interface AtlasScritVC ()
@property (unsafe_unretained) IBOutlet NSTextView *logview;

@property (nonatomic,strong) NSMutableArray<NSDictionary *> *origin_items_data;
@property (nonatomic,strong) NSMutableArray<NSDictionary *> *fail_items_data;

@property (weak) IBOutlet NSTableView *itemsTableView;

@property (weak) IBOutlet NSTextField *labelPath;
//@property (nonatomic, strong) FMDatabase *db;
@property (weak) IBOutlet FileDragView *logDropView;
//@property (weak) IBOutlet NSTextField *labelCount;
//@property (strong,nonatomic)FailOnlyItems *failOnlyItems;
@property(nonatomic,strong)TableDataDelegate *tableDataDelegate;
@property(nonatomic,strong)LuaFunction *luaFunction;

@end

@implementation AtlasScritVC{
    NSString *dfuLogPath;
    NSString *local_path;
  
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSString *str= [FileManager cw_readFromFile:@"/Users/ciweiluo/Desktop/test/test_bk.csv"];
//    NSArray *arr = [str cw_componentsSeparatedByString:@","];
//    NSMutableString *mutstr = [[NSMutableString alloc]init];
//    for (int i=0; i<arr.count; i++) {
//        NSString *s=arr[i];
//        [mutstr appendString:s];
//        [mutstr appendString:@","];
//    }
//    [FileManager cw_writeToFile:@"/Users/ciweiluo/Desktop/test/test.csv" content:mutstr];

//    self.labelCount.stringValue = @"Test Total Count:0   Fail Count:0   Pass Count:0   rate:0";
    NSString *userPath = [NSString cw_getUserPath];
    dfuLogPath =[userPath stringByAppendingPathComponent:@"DFU_Tool_Log"];
    [FileManager cw_createFile:dfuLogPath isDirectory:YES];
    
//    self.items_datas = [[NSMutableArray alloc]init];
    self.origin_items_data = [[NSMutableArray alloc]init];
//    self.fail_items_data = [[NSMutableArray alloc]init];
    [self.itemsTableView setDoubleAction:@selector(doubleClick:)];
    self.tableDataDelegate.owner = self.itemsTableView;
    self.luaFunction = [[LuaFunction alloc]init];

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
    
    local_path = @"";
    [self.origin_items_data removeAllObjects];

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

    NSString *mainCsvPath = [path stringByAppendingPathComponent:@"Assets/Main.csv"];
    if (![manager fileExistsAtPath:mainCsvPath]) {
        [self.tableDataDelegate setData:nil];
        [self.itemsTableView reloadData];
        return;
    }

    local_path =[NSString stringWithFormat:@"%@/Atlas2",dfuLogPath];
    [FileManager cw_copyFlolderFrom:path to:local_path];
    path = local_path;
    
    mainCsvPath =[path stringByAppendingPathComponent:@"Assets/Main.csv"];
    NSString *limitCsvPath = [path stringByAppendingPathComponent:@"Assets/Limits.csv"];
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

        NSString *techCsvPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"Assets/Tech/%@.csv",testName]];
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
            if (arr.count<=12) {
                continue;
            }
//            NSLog(@"i---%d--j--%d",i,j);
//            if (i==39&&j==25) {
//                NSLog(@"111");
//            }
            if ([arr[0] isEqualToString:subTestName]) {
                ScritItemMode *scritItemMode = [[ScritItemMode alloc]init];
                scritItemMode.testName = csvMainArray[i][1];
                scritItemMode.subTestName = csvMainArray[i][0];
                scritItemMode.mainDisable = csvMainArray[i][2];
                scritItemMode.production = csvMainArray[i][3];
                scritItemMode.audit = csvMainArray[i][4];
                scritItemMode.thread = csvMainArray[i][5];
                scritItemMode.loop = csvMainArray[i][6];
                scritItemMode.sample = csvMainArray[i][7];
                scritItemMode.cof = csvMainArray[i][8];
                scritItemMode.mainCondition = csvMainArray[i][9];
               
                scritItemMode.index = item_mode_arr.count+1;
                scritItemMode.function = arr[1];
                scritItemMode.Disable = arr[2];
                scritItemMode.Input = arr[3];
                scritItemMode.Output = arr[4];
                scritItemMode.Timeout = arr[5];
                scritItemMode.Retries = arr[6];
                scritItemMode.ExitEarly = arr[8];
                scritItemMode.subSubTestName = arr[7];
                NSString *pars = arr[7];
                if (pars.length) {
                    pars = [pars stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
                    pars = [NSString stringWithFormat:@"\"%@\"",pars];
                }
                scritItemMode.params =pars;
                scritItemMode.SetPoison = arr[9];
  
                
                scritItemMode.command = arr[10];
//                if (scritItemMode.command.length) {
//                    scritItemMode.command = [NSString stringWithFormat:@"\"%@\"",arr[10]];
//                }
//                if ([scritItemMode.command containsString:@"smokey --run TouchShortsTest"]) {
//                    NSLog(@"1");
//                }
                scritItemMode.FA = arr[11];
                scritItemMode.Condition = arr[12];
                NSArray *limitArr = [self getLimitWithSubTestName:scritItemMode.subTestName subSubTestName:scritItemMode.subSubTestName limitsContent:limitsContent];
                scritItemMode.lowLimit = limitArr[0];
                scritItemMode.upperLimit = limitArr[1];
                scritItemMode.unit =limitArr[2];
                scritItemMode.searchKeyWord =@"";
//                scritItemMode.function = arr[1];
                [item_mode_arr addObject:scritItemMode];
            }
        }
        
    }
    
    NSArray *item_dict_arr = [ScritItemMode getDicArrayWithScritItemModeArr:item_mode_arr];
    [self.origin_items_data addObjectsFromArray:item_dict_arr];

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

- (IBAction)search:(NSSearchField *)searchField {
    
    NSString *content = searchField.stringValue.length ? searchField.stringValue : @"";
    
    NSMutableArray *itemsArr = [self.tableDataDelegate getData];
    
    NSMutableArray *itemsArr_copy = [itemsArr mutableCopy];
    [itemsArr_copy enumerateObjectsUsingBlock:^(NSMutableDictionary *itemDict, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [itemDict setObject:content forKey:key_IsSearch];
        
    }];
    [self.tableDataDelegate reloadTableViewWithData:itemsArr];
    
    
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
    
    
    [self creatMainCsv:dataArr];
    [self creatTechCsv:dataArr];
    [self creatLimitCsv:dataArr];
    

}
-(void)creatLimitCsv:(NSArray *)dataArr{
    NSString *limitCsvPath =[local_path stringByAppendingPathComponent:@"Assets/Limits.csv"];
    NSMutableString *text = [[NSMutableString alloc] initWithString:@"TestItem,ParameterName,units,upperLimit,lowerLimit,relaxedUpperLimit,relaxedLowerLimit,Condition\n"];

    
    for (int i = 0; i<dataArr.count; i++) {
        NSDictionary *dict = dataArr[i];
        NSString *upper = [dict objectForKey:id_UpperLimit];;
        NSString *low = [dict objectForKey:id_LowLimit];;
        if (!upper.length && !low.length) {
            continue;
        }
        NSString *subTestName = [dict objectForKey:id_SubTestName];
        NSString *subSubTestName = [dict objectForKey:id_SubSubTestName];
      
        
        for (int k = 0; k<8; k++) {
            if (k == 0) {
                [text appendString:subTestName];
            }else if (k == 1){
                
                [text appendString:subSubTestName];
            }else if (k == 2){
                
                [text appendString:[dict objectForKey:id_Unit]];
            }else if (k == 3){

                [text appendString:[dict objectForKey:id_LowLimit]];
            }else if (k == 4){
                
                [text appendString:[dict objectForKey:id_UpperLimit]];
            }else if (k == 5){
                
                [text appendString:@""];
            }else if (k == 6){
                
                [text appendString:@""];
            }else if (k == 7){
                
                [text appendString:@""];
            }
            
            if (k == 7) {
                [text appendString:@"\n"];
            }else{
                [text appendString:@","];
            }
            
        }
        
        NSError *error;
        //    [FileManager cw_writeToFile:path content:text];
        [text writeToFile:limitCsvPath atomically:NO encoding:NSUTF8StringEncoding error:&error];
        
    }

}



-(void)creatTechCsv:(NSArray *)dataArr{

//    NSString *lastName = @"";
    NSMutableSet *testNameSet = [[NSMutableSet alloc] init];
    for (int i = 0; i<dataArr.count; i++) {
        NSDictionary *dict = dataArr[i];
        NSString *TestName = [dict objectForKey:id_TestName];
        [testNameSet addObject:TestName];
    }
    
    NSArray *arr = [testNameSet.objectEnumerator allObjects];
    
    for (int i = 0; i<arr.count; i++) {
        NSString *TestName = arr[i];
        NSString *techCsvPath =[local_path stringByAppendingPathComponent:[NSString stringWithFormat:@"Assets/Tech/%@.csv",TestName]];

        NSMutableString *text = [[NSMutableString alloc] initWithString:@"TestName,TestActions,Disable,Input,Output,Timeout,Retries,AdditionalParameters,ExitEarly,SetPoison,Commands,FA,Condition\n"];
        NSString *lastTestName = @"";
        for (int j = 0; j<dataArr.count; j++) {
            NSDictionary *dict = dataArr[j];
            NSString *dict_testName = [dict objectForKey:id_TestName];
            if (![TestName isEqualToString:dict_testName]) {
                continue;
            }
            
            for (int k = 0; k<13; k++) {
                if (k == 0) {
                    NSString *testName = [dict objectForKey:id_SubTestName];
                    if ([lastTestName isEqualToString:testName]) {
                        testName = @"";
                    }else{
                        lastTestName = testName;
                    }
                    [text appendString:testName];
                }else if (k == 1){
                    NSString *TestActions = [dict objectForKey:id_Function];
                    [text appendString:TestActions];
                }else if (k == 2){
                    NSString *Disable = [dict objectForKey:id_Disable];
                    [text appendString:Disable];
                }else if (k == 3){
                    NSString *input = [dict objectForKey:id_Input];
                    [text appendString:input];
                }else if (k == 4){
                    NSString *output = [dict objectForKey:id_Output];
                    [text appendString:output];
                }else if (k == 5){
                    NSString *timeout = [dict objectForKey:id_Timeout];
                    [text appendString:timeout];
                }else if (k == 6){
                    NSString *retries = [dict objectForKey:id_Retries];
                    [text appendString:retries];
                }else if (k == 7){
                    NSString *pars = [dict objectForKey:id_AdditionalParameters];
                    [text appendString:pars];
                }else if (k == 8){
                    NSString *exitearly = [dict objectForKey:id_ExitEarly];
                    [text appendString:exitearly];
                }else if (k == 9){
                    NSString *setpos = [dict objectForKey:id_SetPoison];
                    [text appendString:setpos];
                }else if (k == 10){
                    NSString *cmds = [dict objectForKey:id_Command];
                    [text appendString:cmds];
//                    [text appendString:[NSString stringWithFormat:@"\"%@\"",cmds]];
                }else if (k ==11){
                    NSString *fa = [dict objectForKey:id_FA];
                    [text appendString:fa];
                }else if (k == 12){
                    NSString *conditon = [dict objectForKey:id_Condition];
                    [text appendString:conditon];
                }
                
                if (k == 12) {
                    [text appendString:@"\n"];
                }else{
                    [text appendString:@","];
                }
                
            }
            
            
            
            NSError *error;
            //    [FileManager cw_writeToFile:path content:text];
            [text writeToFile:techCsvPath atomically:NO encoding:NSUTF8StringEncoding error:&error];

            
        }
        
    }

    
}
-(void)creatMainCsv:(NSArray *)dataArr{
    NSString *mainCsvPath =[local_path stringByAppendingPathComponent:@"Assets/Main.csv"];
    NSMutableString *text = [[NSMutableString alloc] initWithString:@"TestName,Technology,Disable,Production,Audit,Thread,Loop,Sample,CoF,Condition\n"];
    NSString *lastName = @"";
    
    for (int i = 0; i<dataArr.count; i++) {
        NSDictionary *dict = dataArr[i];

        NSString *subTestName = [dict objectForKey:id_SubTestName];
        NSString *TestName = [dict objectForKey:id_TestName];
        NSString *temp_name = [NSString stringWithFormat:@"%@,%@",TestName,subTestName];
    
        if ([lastName isEqualToString:temp_name]) {
            continue;
        }else{
            lastName = temp_name;
        }
        
        for (int k = 0; k<10; k++) {
            if (k == 0) {
                [text appendString:subTestName];
            }else if (k == 1){
                
                [text appendString:TestName];
            }else if (k == 2){
                NSString *main_Disable = [dict objectForKey:id_Main_Disable];
                [text appendString:main_Disable];
            }else if (k == 3){
                NSString *Production = [dict objectForKey:id_Production];
                [text appendString:Production];
            }else if (k == 4){
                NSString *Audit = [dict objectForKey:id_Audit];
                [text appendString:Audit];
            }else if (k == 5){
                NSString *Thread = [dict objectForKey:id_Thread];
                [text appendString:Thread];
            }else if (k == 6){
                NSString *Loop = [dict objectForKey:id_Loop];
                [text appendString:Loop];
            }else if (k == 7){
                NSString *Sample = [dict objectForKey:id_Sample];
                [text appendString:Sample];
            }else if (k == 8){
                NSString *CoF = [dict objectForKey:id_CoF];
                [text appendString:CoF];
            }else if (k == 9){
                NSString *Condition = [dict objectForKey:id_Main_Condition];
                [text appendString:Condition];
            }
            
            if (k == 9) {
                [text appendString:@"\n"];
            }else{
                [text appendString:@","];
            }
            
        }
        
        NSError *error;
        //    [FileManager cw_writeToFile:path content:text];
        [text writeToFile:mainCsvPath atomically:NO encoding:NSUTF8StringEncoding error:&error];
        
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
        _tableDataDelegate.tableViewForTableColumnCallback = ^(id view, NSInteger row, NSDictionary *data,NSString *identifier) {
            NSString *value = [data valueForKey:identifier];
            NSString *search_keyword =[data valueForKey:key_IsSearch];
            BOOL is_search = [value.lowercaseString containsString:search_keyword.lowercaseString];
            NSTextField *textField = (NSTextField *)view;
            if (is_search) {
                
                    textField.layer.backgroundColor = [NSColor systemOrangeColor].CGColor;
                }else{
                    textField.layer.backgroundColor = [NSColor clearColor].CGColor;
                }
            
            
        };
        
        _tableDataDelegate.tableViewdidClickColumnCallback = ^(NSString *identifier, NSInteger clickIndex) {
            
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
    
    NSArray *dataArr = [self.tableDataDelegate getData];
    if (!dataArr.count) {
        return;
    }
    NSInteger row = [self.itemsTableView selectedRow];
    if (row == -1)
    {
        return;
    }
    
    NSDictionary *dict = dataArr[row];
    
    NSString *TestActions = [dict objectForKey:id_Function];
    NSArray *arr = [TestActions cw_componentsSeparatedByString:@":"];
    if (arr.count != 2) {
        return;
    }
    NSString *TestName = [dict objectForKey:id_TestName];
    NSString *fuctionCsvPath =@"";
    NSString *functionName = arr[0];
    if ([functionName isEqualToString:@"Tech"]) {
        fuctionCsvPath = [local_path stringByAppendingPathComponent:[NSString stringWithFormat:@"Modules/Tech/%@.lua",TestName]];
    }else{
        fuctionCsvPath = [local_path stringByAppendingPathComponent:[NSString stringWithFormat:@"Modules/Tech/%@.lua",functionName]];
    }
    
    [self.luaFunction showViewOnViewController:self];
    self.luaFunction.title = fuctionCsvPath.lastPathComponent;
    self.luaFunction.luaFunctionPath = fuctionCsvPath;
    
//    NSDictionary *dict = self.origin_items_data[row];
//
//    NSString *recordPath = [dict objectForKey:key_record_path];
//    BOOL isFail = [[dict objectForKey:key_is_fail] boolValue];
//    if (isFail) {
//        //        self.failOnlyItems.title =mode.recordPath;
//        [self.failOnlyItems showViewOnViewController:self];
//        self.failOnlyItems.recordPath = recordPath;
//    }
    
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
