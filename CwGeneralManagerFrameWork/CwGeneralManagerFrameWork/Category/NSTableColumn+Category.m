//
//  NSTableColumn+Category.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import "NSTableColumn+Category.h"

@implementation NSTableColumn (Category)

+ (id)cw_tableColumnWithItem:(TableColumnItem*)item {
    NSTableColumn *column = [[NSTableColumn alloc]init];
    [column columnWithItem:item];
    return column;
}

- (void)columnWithItem:(TableColumnItem*)item {
    self.identifier = item.identifier;
    [self setWidth:item.width];
    [self setMinWidth:item.minWidth];
    [self setMaxWidth:item.maxWidth];
    
    [self setEditable:YES];
    [self setResizingMask:NSTableColumnUserResizingMask];
    
   
    [self updateHeaderCellWithItem:item];
}

- (void)updateHeaderCellWithItem:(TableColumnItem*)item{
    if(item.title){
        [[self headerCell] setStringValue:item.title];
    }
    [[self headerCell] setAlignment:item.headerAlignment];
    if([[self headerCell]  isKindOfClass:[NSCell class]]){
        [[self headerCell] setLineBreakMode: NSLineBreakByTruncatingMiddle];
    }
}
@end
