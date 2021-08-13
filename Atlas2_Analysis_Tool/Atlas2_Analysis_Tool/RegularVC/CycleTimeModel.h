//
//  CycleTimeModel.h
//  Atlas2_Analysis_Tool
//
//  Created by ciwei luo on 2021/8/13.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CycleTimeModel : NSObject
@property(nonatomic,copy)NSString *sc_TestName;
@property(nonatomic,copy)NSString *sc_SubItem;
@property(nonatomic,copy)NSString *sc_SubSubItem;
@property(nonatomic,copy)NSString *sc_test_time;

@property(nonatomic,copy)NSString *atlas2_test_time;
@property(nonatomic,copy)NSString *atlas2_SubItem;
@property(nonatomic,copy)NSString *atlas2_Item;

@property BOOL isFind;
@end

NS_ASSUME_NONNULL_END
