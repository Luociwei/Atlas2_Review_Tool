//
//  NSImageView+Category.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/30.
//  Copyright © 2021 Suncode. All rights reserved.

#import "NSImageView+Category.h"
#import "TableColumnItem.h"
@implementation NSImageView(Category)

- (instancetype)initImageViewWithItem:(TableColumnItem*)item {
    self = [super init];
    if (self) {
        self.identifier = item.identifier;
    }
    return self;
}

@end
