//
//  TableDataDelegate.m
//  TableDataNavigationViewController
//
//  Created by MacDev on 16/6/4.
//  Copyright © 2016年 http://www.macdev.io All rights reserved.
//

#import "TableDataDelegate.h"


#import <Cocoa/Cocoa.h>

NSString * const TableViewDragDataTypeName  = @"TableViewDragDataTypeName";

@interface TableDataDelegate ()
@property(nonatomic,strong)NSMutableArray *items;
@end

@implementation TableDataDelegate{
    
    BOOL _isDargData;
    NSInteger _clickColumnIndex;
}

- (void)dealloc {
    if (self.owner && _isDargData) {
        [self.owner unregisterDraggedTypes];
    }
    
    NSLog(@"TableDataDelegate dealloc");
}

-(id)initWithTaleView:(NSTableView *)tableView{
    return [self initWithTaleView:tableView isDargData:NO];

}

-(id)initWithTaleView:(NSTableView *)tableView isDargData:(BOOL)isDargData{
    self = [super init];
    if(self){
        _clickColumnIndex = 0;
        _isDargData = isDargData;
        _items = [[NSMutableArray alloc]initWithCapacity:4];
        if (tableView!=nil) {
            tableView.delegate = self;
            tableView.dataSource = self;
            tableView.headerView.hidden=NO;
            tableView.usesAlternatingRowBackgroundColors=YES;
            tableView.rowHeight = 20;
            tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask |NSTableViewSolidVerticalGridLineMask ;
//            [tableView setDoubleAction:@selector(doubleClick:)];
            if (_isDargData) {
                [tableView registerForDraggedTypes:[NSArray arrayWithObject:TableViewDragDataTypeName]];
            }

            self.owner = tableView;
        }

      
    }
    return  self;
}

- (id)init {
    self = [super init];
    if(self){
        _clickColumnIndex = 0;
        _items = [[NSMutableArray alloc]initWithCapacity:4];
    }
    return  self;
}

- (void)setData:(id)data {
    if(!data){
        [self clearData];
        return;
    }
    assert([data isKindOfClass:[NSArray class]]);
    self.items = [NSMutableArray arrayWithArray:data];
}

- (void)updateData:(id)item row:(NSInteger)row {
    if(row<=(_items.count-1)){
        self.items[row] = item;
    }
}

- (void)addData:(id)data {
    if(!data){
        return ;
    }
    if([data isKindOfClass:[NSArray class]]){
        [self.items addObjectsFromArray:data];
    }
    else{
        [self.items addObject:data];
    }
}
- (void)addData:(id)data atIndex:(NSInteger)index {
    if(!data){
        return ;
    }
    [self.items insertObject:data atIndex:index];
}

- (void)deleteData:(id)data {
    if([data isKindOfClass:[NSIndexSet class]]){
        [self.items removeObjectsAtIndexes:data];
    }
    else if([data isKindOfClass:[NSArray class]]){
        NSArray *array = data;
        for(id obj in array){
            [self.items removeObject:obj];
        }
    }
    else{
        [self.items removeObject:data];
    }
}

- (void)deleteDataAtIndex:(NSUInteger)index {
    assert(index<=(self.items.count-1));
    [self.items removeObjectAtIndex:index];
}

- (void)deleteDataIndexes:(NSIndexSet*)indexSet {
    [self deleteData:indexSet];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index {
    assert(index<=(self.items.count-1));
    [self addData:anObject atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    assert(index<=(self.items.count-1));
    [self deleteDataAtIndex:index];
}
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2 {
    assert(idx1<=(self.items.count-1));
    assert(idx2<=(self.items.count-1));
    [self.items exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

- (void)clearData {
    self.items =  [[NSMutableArray alloc]initWithCapacity:4];
}

- (id)itemOfRow:(NSInteger)row {
    if(row<=(_items.count-1)){
        return _items[row];
    }
    return nil;
}

- (NSArray*)itemsOfIndexSet:(NSIndexSet*)indexSet {
    NSInteger count = indexSet.count;
    if(count<=0){
        return nil;
    }
    NSMutableArray *array =[[NSMutableArray alloc]initWithCapacity:count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id obj = [self itemOfRow:idx];
        [array addObject:obj];
    }
     ];
    return array;
}


- (NSInteger)itemCount{
    return [self.items count];
}

#pragma  mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.items count];
}
- (IBAction)doubleClick:(id)sender{

    NSInteger row = [self.owner selectedRow];
    if(row>=self.items.count){
        return;
    }
    id data = [self.items objectAtIndex:row];
    NSLog(@"tableViewRow double click data=%@",data);
    if(self.tableViewRowDoubleClickCallback){
        self.tableViewRowDoubleClickCallback(row,data);
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [notification.object selectedRow];
    if(row>=self.items.count){
        return;
    }
    id data = [self.items objectAtIndex:row];
    NSLog(@"select row notification.object=%@",data);
    if(self.selectionChangedCallback){
        self.selectionChangedCallback(row,data);
    }
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{

    NSString *identifier = tableColumn.identifier;
    if (!self.items.count) {
        return;
    }
    _clickColumnIndex = _clickColumnIndex + 1;
    if(self.tableViewdidClickColumnCallback){
        self.tableViewdidClickColumnCallback(identifier,_clickColumnIndex);
    }

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
//        self.data

    
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    NSArray *sortDescriptors = [aTableView sortDescriptors];
    self.items =[NSMutableArray arrayWithArray:[self.items sortedArrayUsingDescriptors:sortDescriptors]];
    [aTableView reloadData];
}


#pragma mark - NSTableViewDelegate


-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    //获取row数据
    id data = [self itemOfRow:row];
    //表格列的标识
    NSString *identifier = tableColumn.identifier;
    //单元格数据
    NSString *value = [data valueForKey:identifier];
    
    //根据表格列的标识,创建单元视图
    NSView *view = [tableView makeViewWithIdentifier:identifier owner:self];
    
    TableColumnItem *tableColumnItem = [tableView cw_columnItemWithIdentifier:identifier];
    
    switch (tableColumnItem.cellType) {
        case TableColumnCellTypeCheckBox:
        {
            NSButton *checkBoxField;
            if(!view){
                checkBoxField =  [[NSButton alloc]initCheckBoxWithItem:tableColumnItem];
                view = checkBoxField ;
            }
            else{
                checkBoxField = (NSButton*)view;
            }
            [checkBoxField setTarget:self];
            [checkBoxField setAction:@selector(checkBoxChick:)];
            if(value){
                checkBoxField.state = [value integerValue];
                
            }
            
        }
            break;
        case TableColumnCellTypeButton:
        {
            NSButton *button;
            if(!view){
                button =  [[NSButton alloc]initButtonWithItem:tableColumnItem];
                view = button ;
            }
            else{
                button = (NSButton*)view;
            }
            [button setTarget:self];
            [button setAction:@selector(buttonChick:)];
            if(value){
//                button.state = [value integerValue];
                button.image = (NSImage*)value;
            }

        }
            break;
        case TableColumnCellTypeComboBox:
        {
            
            NSComboBox *comboBoxField;
            if(!view){
                view = [[NSTableCellView alloc]init];
                comboBoxField =  [[NSComboBox alloc]initComboBoxWithItem:tableColumnItem];
                comboBoxField.delegate = self;
                [view addSubview:comboBoxField];
                [comboBoxField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(view.mas_left).with.offset(2);
                    make.right.equalTo(view.mas_right).with.offset(-2);
                    make.centerY.equalTo(view.mas_centerY).with.offset(0);
                    
                }];
            }
            else{
                comboBoxField = (NSComboBox*)view.subviews[0];
            }
            
            NSArray *items = tableColumnItem.items;
            if(items){
                [comboBoxField addItemsWithObjectValues:items];
            }
            if(value) {
                comboBoxField.stringValue = value;
            }
        }
            break;
            
        case TableColumnCellTypeImageView:
        {
            
            NSImageView *imageField;
            //如果不存在,创建新的textField
            if(!view){
                imageField =  [[NSImageView alloc]initImageViewWithItem:tableColumnItem];
                
                view = imageField ;
            }
            else{
                imageField = (NSImageView*)view;
            }
            
            if(value){
                //更新单元格的image
                imageField.image = (NSImage*)value;
            }
        }
            break;//
        case TableColumnCellTypeTextField: //默认都是文本控件
        {
            NSTextField *textField;
            //如果不存在,创建新的textField
            if(!view){
                textField =  [[NSTextField alloc]initTextFieldWithItem:tableColumnItem];
                textField.delegate = self;
                view = textField ;
            }
            else{
                textField = (NSTextField*)view;
            }
            
            textField.stringValue  = @"";
            if(value.length){
                //更新单元格的文本
                textField.stringValue = value;
            }
        }
            break;
            
        default: //默认都是文本控件
        {
            
            //        textField = (NSTextField*)view;
            if (!view) {
                NSTextField *textField =  [[NSTextField alloc]init];
                
                textField.identifier = identifier;
                textField = (NSTextField *)textField;
                textField.wantsLayer=YES;
                [textField setBezeled:NO];
                [textField setDrawsBackground:NO];
                view = textField;
            }else{
                
                NSArray *subviews = [view subviews];
                
                view = subviews[0];
                if ([view isKindOfClass:[NSButton class]]){
                    NSButton *btn= subviews[0];
                    btn.tag=row;
                    btn.wantsLayer=YES;
                    [btn setTarget:self];
                    [btn setAction:@selector(buttonChick:)];
                    
                }else if([view isKindOfClass:[NSTextField class]]){
                    NSTextField *textf= subviews[0];
                    if(value.length){
                        //                textf.wantsLayer=YES;
                        //                if ([identifier isEqualToString:@"FailList"]) {
                        ////                    [textf setTextColor:[NSColor blueColor]];
                        //
                        //                    textf.layer.backgroundColor = [NSColor systemRedColor].CGColor;
                        //                }
                        //更新单元格的文本
                        [textf setStringValue: value];
                    }else{
                        //                if ([identifier isEqualToString:@"FailList"]) {
                        //                textf.layer.backgroundColor = [NSColor clearColor].CGColor;
                        //                }
                    }
                    textf.wantsLayer=YES;
                    
                    //            if (item_data.isFail) {
                    //
                    //                textf.layer.backgroundColor = [NSColor systemRedColor].CGColor;
                    //            }else{
                    //                textf.layer.backgroundColor = [NSColor clearColor].CGColor;
                    //            }
                    
                    
                    
                }
                
            }

        }
            break;
    }
    
    if(self.tableViewForTableColumnCallback){
        self.tableViewForTableColumnCallback(view,row,data,identifier);
    }
    
    return view;
}

#pragma mark - Action

//文本输入框变化处理事件
- (void)controlTextDidChange:(NSNotification *)aNotification{
    NSTextField *field = aNotification.object;
    NSString *identifier = field.identifier;
    NSInteger row = [self.owner selectedRow];
    NSLog(@"field text = %@",field.stringValue);
    NSMutableDictionary *data = [self itemOfRow:row];
    NSMutableDictionary *oldData = [data mutableCopy];
    
    if(field.stringValue){
        data[identifier]    = field.stringValue;
    }
    
    if(self.rowObjectValueChangedCallback){
        self.rowObjectValueChangedCallback(data, oldData,row,identifier);
    }
    
}

//comboBox选择框处理事件
- (void)comboBoxSelectionDidChange:(NSNotification *)aNotification {
    NSComboBox *field = aNotification.object;
    NSString *identifier = field.identifier;
    NSInteger row = [self.owner selectedRow];
    NSLog(@"field text = %@",field.stringValue);
    NSMutableDictionary *data = [self itemOfRow:row];
    NSMutableDictionary *oldData = [data mutableCopy];
    if(field.stringValue){
        data[identifier]    = field.stringValue;
    }
    if(self.rowObjectValueChangedCallback){
        self.rowObjectValueChangedCallback(data, oldData,row,identifier);
    }
}

//Check Box 选择处理事件
- (IBAction)checkBoxChick:(id)sender {
    NSButton *button = (NSButton *)sender;
    NSLog(@"Form checkBoxChick=%ld",button.state);
    NSString *identifier = button.identifier;
    NSInteger row = [self.owner selectedRow];
    NSMutableDictionary *data = [self itemOfRow:row];
    NSMutableDictionary *oldData = [data mutableCopy];
    data[identifier]    = @(button.state);
    
    if(self.rowObjectValueChangedCallback){
        self.rowObjectValueChangedCallback(data, oldData,row,identifier);
    }
}

- (IBAction)buttonChick:(id)sender {
    NSButton *button = (NSButton *)sender;
//    NSLog(@"Form checkBoxChick=%ld",button.state);
    NSString *identifier = button.identifier;
    NSInteger row = button.tag;
    NSMutableDictionary *data = [self itemOfRow:row];

    
//    data[identifier]    = @(button.state);
    
    if(self.buttonClickCallback){
        self.buttonClickCallback(row,data);
    }
}

#pragma mark -- Drag/Drop

// drag operation stuff
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // Copy the row numbers to the pasteboard.
    NSData *zNSIndexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:TableViewDragDataTypeName] owner:self];
    [pboard setData:zNSIndexSetData forType:TableViewDragDataTypeName];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {

    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
              row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:TableViewDragDataTypeName];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = [rowIndexes firstIndex];
    
    NSInteger count = [self itemCount];
    if(count<=1){
        return YES;
    }
    NSLog(@"dragRow = %ld row=%ld count=%ld",dragRow,row,count);
    /*drag row inside table cell row*/
    if(row<=count-1){
        [self exchangeObjectAtIndex:dragRow withObjectAtIndex:row];
        [tableView noteNumberOfRowsChanged];
        [tableView reloadData];
        if(self.rowDragCallback){
            self.rowDragCallback(row,dragRow);
        }
        return YES;
    }
    else{
        /*drag row index out of row count*/
        id zData = [[self itemOfRow:dragRow]mutableCopy];
        [self insertObject:zData atIndex:row];
        count = [self itemCount];
        [self deleteDataAtIndex:dragRow];
        count = [self itemCount];
        [tableView noteNumberOfRowsChanged];
        [tableView reloadData];
        if(self.rowDragCallback){
            self.rowDragCallback(row,dragRow);
        }
        return YES;
    }
}


@end
