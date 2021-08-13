//
//  NSButton+Category.h
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import <Cocoa/Cocoa.h>
@class TableColumnItem;
@interface NSButton (Category)
- (instancetype)initCheckBoxWithItem:(TableColumnItem*)item;
- (instancetype)initButtonWithItem:(TableColumnItem*)item;
@end
