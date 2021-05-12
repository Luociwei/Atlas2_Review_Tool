//
//  NSTableView+Category.h
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import <Cocoa/Cocoa.h>
@class TableColumnItem;
@interface NSTableView (Category)

- (void)cw_removeAllColumns;

- (void)cw_updateColumnsWithItems:(NSArray*)items;

- (void)cw_setEditFoucusAtColumn:(NSInteger)columnIndex;

- (void)cw_setEditFoucusAtColumn:(NSInteger)columnIndex atRow:(NSInteger)rowIndex;

- (void)cw_setLostEditFoucus;

- (void)cw_setSelectionAtRow:(NSInteger)rowIndex;


- (TableColumnItem*)cw_columnItemAtIndex:(NSInteger)colIndex;

- (TableColumnItem*)cw_columnItemWithIdentifier:(NSString*)identifier;
@end
