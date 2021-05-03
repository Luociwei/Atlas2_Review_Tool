//
//  ScritItemMode.h
//  OPP_Tool
//
//  Created by ciwei luo on 2020/5/26.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "SnVauleMode.h"

NS_ASSUME_NONNULL_BEGIN

@interface ScritItemMode : NSObject

@property (nonatomic)NSInteger index;
@property (nonatomic,copy)NSString *testName;
@property (nonatomic,copy)NSString *subTestName;
@property (nonatomic,copy)NSString *subSubTestName;
@property (nonatomic,copy)NSString *function;
@property (nonatomic,copy)NSString *params;
@property (nonatomic,copy)NSString *command;
@property (nonatomic,copy)NSString *lowLimit;
@property (nonatomic,copy)NSString *upperLimit;
@property (nonatomic,copy)NSString *unit;

//@property BOOL isSearch;
@property (nonatomic,copy)NSString *searchKeyWord;
//@property (nonatomic,copy)NSString *desc;

//@property (readonly)BOOL isFail;
//@property (nonatomic,strong)NSMutableArray<SnVauleMode *> *SnVauleArray;
//-(NSString *)getVauleWithKey:(NSString *)key;
+(NSMutableArray *)getDicArrayWithScritItemModeArr:(NSArray *)item_mode_arr;
@end

NS_ASSUME_NONNULL_END
