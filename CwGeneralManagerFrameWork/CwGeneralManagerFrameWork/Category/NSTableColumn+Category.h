//
//  NSTableColumn+Category.h
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import <Cocoa/Cocoa.h>
#import "TableColumnItem.h"
@interface NSTableColumn (Category)
+ (id)cw_tableColumnWithItem:(TableColumnItem*)item;
@end
