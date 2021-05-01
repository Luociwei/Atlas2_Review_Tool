//
//  TableDataView.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "TableDataView.h"
#import "ExtensionConst.h"
NSString * const TableViewDragDataTypeName  = @"TableViewDragDataTypeName";
//extern NSString * const TableViewDragDataTypeName;
@interface TableDataView ()
@property(nonatomic,strong)NSTableView  *tableView;
@property(nonatomic,strong)NSScrollView *tableViewScrollView;
@end


@implementation TableDataView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

#pragma mark - ivars
- (NSScrollView*)tableViewScrollView{
    if(!_tableViewScrollView){
//        _tableViewScrollView = [self tableViewXibScrollView];
//        if(_tableViewScrollView){
//            return _tableViewScrollView;
//        }
        _tableViewScrollView = [[NSScrollView alloc] init];
        [_tableViewScrollView setHasVerticalScroller:NO];
        [_tableViewScrollView setHasHorizontalScroller:NO];
        [_tableViewScrollView setFocusRingType:NSFocusRingTypeNone];
        [_tableViewScrollView setAutohidesScrollers:YES];
        [_tableViewScrollView setBorderType:NSNoBorder];
        [_tableViewScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return _tableViewScrollView;
}

- (NSTableView*)tableView{
    if(!_tableView){
//        _tableView = [self tableXibView];
//        if(_tableView){
//            return _tableView;
//        }
        _tableView = [[NSTableView alloc] init];
        [_tableView setAutoresizesSubviews:YES];
        [_tableView setFocusRingType:NSFocusRingTypeNone];
    }
    return _tableView;
}
- (void)setupAutolayout {

    //关联表视图到滚动条视图
    [self.tableViewScrollView setDocumentView:self.tableView];
    //将滚动条视图添加到父视图
    [self addSubview:self.tableViewScrollView];
    
    //设置表视图约束
    [self.tableViewScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self.mas_left).with.offset(0);
//        make.right.equalTo(self.mas_right).with.offset(0);
//        make.top.equalTo(self.mas_top).with.offset(0);
//        make.bottom.equalTo(self.mas_bottom).with.offset(-30);
        make.left.and.top.and.bottom.and.right.mas_equalTo(0);
    }];
    
  
}
- (void)registerRowDrag {
    
    [self.tableView registerForDraggedTypes:[NSArray arrayWithObject:TableViewDragDataTypeName]];
    
}

- (void)tableViewStyleConfig {
    self.tableView.gridStyleMask =  NSTableViewSolidHorizontalGridLineMask | NSTableViewSolidVerticalGridLineMask;
    self.tableView.usesAlternatingRowBackgroundColors = YES;
}

- (void)tableViewSortColumnsConfig {
    
    for (NSTableColumn *tableColumn in self.tableView.tableColumns ) {
        //  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:tableColumn.identifier ascending:YES selector:@selector(compare:)];
        NSSortDescriptor *sortStates = [NSSortDescriptor sortDescriptorWithKey:tableColumn.identifier
                                                                     ascending:NO
                                                                    comparator:^(id obj1, id obj2) {
                                                                        
                                                                        if (obj1 < obj2) {
                                                                            return  NSOrderedAscending;
                                                                            
                                                                        }
                                                                        if (obj1 > obj2) {
                                                                            
                                                                            return NSOrderedDescending;
                                                                            
                                                                        }
                                                                        
                                                                        return NSOrderedSame;
                                                                    }];
        
        [tableColumn setSortDescriptorPrototype:sortStates];
    }
}


@end
