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

@property (nonatomic,copy)NSString *Disable;
@property (nonatomic,copy)NSString *Input;
@property (nonatomic,copy)NSString *Output;
@property (nonatomic,copy)NSString *Timeout;
@property (nonatomic,copy)NSString *Retries;
@property (nonatomic,copy)NSString *ExitEarly;
@property (nonatomic,copy)NSString *SetPoison;
@property (nonatomic,copy)NSString *FA;
@property (nonatomic,copy)NSString *Condition;


@property (nonatomic,copy)NSString *mainDisable;
@property (nonatomic,copy)NSString *production;
@property (nonatomic,copy)NSString *audit;
@property (nonatomic,copy)NSString *thread;
@property (nonatomic,copy)NSString *sample;
@property (nonatomic,copy)NSString *loop;
@property (nonatomic,copy)NSString *cof;
@property (nonatomic,copy)NSString *mainCondition;
//@property BOOL isSearch;
@property (nonatomic,copy)NSString *searchKeyWord;
//@property (nonatomic,copy)NSString *desc;

//@property (readonly)BOOL isFail;
//@property (nonatomic,strong)NSMutableArray<SnVauleMode *> *SnVauleArray;
//-(NSString *)getVauleWithKey:(NSString *)key;
+(NSMutableArray *)getDicArrayWithScritItemModeArr:(NSArray *)item_mode_arr;
@end

NS_ASSUME_NONNULL_END
