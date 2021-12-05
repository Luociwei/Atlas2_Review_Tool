//
//  ErrorCode.h
//  FxitureController
//
//  Created by IvanGan on 16/9/2.
//  Copyright © 2016年 IvanGan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErrorCode : NSObject
{
    NSMutableDictionary * errorDic;
}
- (int)setErrorCode:(int)errorcode :(NSString *)msg;
- (const char *)getErrorMsg:(int)errorcode;
@end
