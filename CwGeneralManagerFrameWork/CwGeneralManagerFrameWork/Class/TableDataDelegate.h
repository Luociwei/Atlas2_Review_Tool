//
//  TableDataDelegate.h
//  TableDataNavigationViewController
//
//  Created by MacDev on 16/6/4.
//  Copyright © 2016年 http://www.macdev.io All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface TableDataDelegate : NSObject<NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate,NSComboBoxDelegate>

//Row Selection Changed Callback.
typedef void(^SelectionChangedCallbackBlock)(NSInteger index,  id obj);
typedef void(^TableViewRowDoubleClickCallbackBlock)(NSInteger index,  id obj);

typedef void(^ButtonClickCallbackBlock)(NSInteger row,  id obj);
//didClickTableColumn
//
typedef void(^TableViewdidClickColumnCallbackBlock)(NSString *identifier,NSInteger clickIndex);
//Row Drag Callback.
typedef void(^TableViewRowDragCallbackBlock)(NSInteger sourceRow,NSInteger targetRow);
typedef void(^TableViewForTableColumnCallbackBlock)(id view,NSInteger row,NSDictionary *item_data,NSString *identifier);
//Row Edit Object Changed Callback.
typedef void(^RowObjectValueChangedCallbackBlock)(id obj,id oldObj,NSInteger row,NSString *fieldName);
-(id)initWithTaleView:(NSTableView *)tableView;
-(id)initWithTaleView:(NSTableView *)tableView isDargData:(BOOL)isDargData;
@property(nonatomic,weak)NSTableView *owner;
//
@property(nonatomic,copy)TableViewdidClickColumnCallbackBlock tableViewdidClickColumnCallback;

@property(nonatomic,copy)ButtonClickCallbackBlock buttonClickCallback;//didClickTableColumn

@property(nonatomic,copy)TableViewForTableColumnCallbackBlock tableViewForTableColumnCallback;

@property(nonatomic,copy)SelectionChangedCallbackBlock selectionChangedCallback;

@property(nonatomic,copy)TableViewRowDoubleClickCallbackBlock tableViewRowDoubleClickCallback;

@property(nonatomic,copy)TableViewRowDragCallbackBlock rowDragCallback;

@property(nonatomic,copy)RowObjectValueChangedCallbackBlock rowObjectValueChangedCallback;

//rowObjectValueChangedCallback
- (void)reloadTableViewWithData:(id)data;

- (void)setData:(id)data;

- (id)getData;

- (void)updateData:(id)item row:(NSInteger)row;

- (void)addData:(id)data;

- (void)deleteData:(id)data;

- (void)deleteDataAtIndex:(NSUInteger)index;

- (void)deleteDataIndexes:(NSIndexSet*)indexSet;

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;

- (void)clearData;

- (NSInteger)itemCount;

- (id)itemOfRow:(NSInteger)row;

- (NSArray*)itemsOfIndexSet:(NSIndexSet*)indexSet;

@end
