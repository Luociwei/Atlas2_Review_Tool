//
//  NSComboBox+Category.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import "NSComboBox+Category.h"
#import "TableColumnItem.h"
@implementation NSComboBox (Category)
- (instancetype)initComboBoxWithItem:(TableColumnItem*)item {
    self = [super init];
    if (self) {
        // Initialization code here.
        [self setEditable:item.editable];
        [self setBordered:NO];
        [self setBezeled:NO];
        [self setBezelStyle:NSTextFieldRoundedBezel];
         //self.controlSize = NSSmallControlSize;
         self.identifier = item.identifier;
         //self.itemHeight = 24;
        //self.hasVerticalScroller =NO;
        //[self setAutoresizingMask:NSViewWidthSizable];
    }
    return self;
}

@end
