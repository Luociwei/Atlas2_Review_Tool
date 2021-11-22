//
//  NSPopUpButton+Category.m
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/11/21.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "NSPopUpButton+Category.h"

@implementation NSPopUpButton (Category)
-(void)cw_addItemsWithTitles:(NSArray *)titles{
    [self removeAllItems];
    [self addItemsWithTitles:titles];
}
@end
