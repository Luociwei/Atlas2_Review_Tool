//
//  Category.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import "NSTextField+Category.h"
#import "TableColumnItem.h"
@implementation NSTextField (Category)

- (instancetype)initTextFieldWithItem:(TableColumnItem*)item; {
    self = [super init];
    [self setBezeled:NO];
    [self setDrawsBackground:NO];
    [self setEditable:item.editable];
    [self setSelectable:item.editable];
    self.identifier = item.identifier;
    return self;
}
@end
