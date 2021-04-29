//
//  ItemMode.m
//  OPP_Tool
//
//  Created by ciwei luo on 2020/5/26.
//  Copyright © 2020 macdev. All rights reserved.
//

#import "ItemMode.h"


@implementation ItemMode

-(instancetype)init{
    if (self == [super init]) {
        
        self.SnVauleArray = [[NSMutableArray alloc]init];
    }
    return self;
}
//@property (nonatomic,copy)NSString *sn;
//@property (nonatomic,copy)NSString *startTime;
//@property (nonatomic,copy)NSString *failList;
-(NSString *)getVauleWithKey:(NSString *)key{
    NSString *value = @"";
    if ([key.lowercaseString isEqualToString:@"sn"]) {
        value = self.sn;
    }else if ([key.lowercaseString isEqualToString:@"starttime"]) {
        value = self.startTime;
    }else if ([key.lowercaseString isEqualToString:@"faillist"]) {
        value = self.failList;
    }else if ([key.lowercaseString isEqualToString:@"index"]) {
        value = [NSString stringWithFormat:@"%ld",(long)self.index];
    }else if ([key.lowercaseString isEqualToString:@"record"]) {
        value = self.recordPath;
    }
    return value;
}

-(void)setFailList:(NSString *)failList{
    if (failList.length) {
        _failList = failList;
        _isFail = YES;
    }else{
        _failList = @"";
        _isFail = NO;
    }
    
    
    
}

@end
