//
//  NSButton+Category.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import "NSButton+Category.h"
#import "TableColumnItem.h"
@implementation NSButton (Category)

- (instancetype)initCheckBoxWithItem:(TableColumnItem*)item {
    
    self = [super init];
    [self setButtonType:NSSwitchButton];
    [self setBezelStyle:NSRegularSquareBezelStyle];
    [self setTitle:@""];
    [[self cell] setBordered:NO];
    self.identifier = item.identifier;
    return self;
}

- (instancetype)initButtonWithItem:(TableColumnItem*)item {
    
    self = [super init];
    [self setButtonType:NSButtonTypeMomentaryPushIn];
    [self setBezelStyle:NSBezelStyleRegularSquare];
    [self setTitle:@""];
    [[self cell] setBordered:NO];
    self.identifier = item.identifier;
    return self;
}

@end
