//
//  fixtureControl.h
//  Eowyn
//
//  Created by gdlocal on 2021/6/17.
//  Copyright © 2021 gdlocal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "eowynController.h"

NS_ASSUME_NONNULL_BEGIN

@interface fixtureControl : NSObject
{
    NSLock * m_lock;
    BOOL ipOk;
    NSDictionary *GPIO;
    eowynController *eowyn;
    NSString *current_low_state;
    NSString *current_high_state;
    NSString * logPath;
}

-(int)initFixtureControl:(NSString *)ip withLogPath:(NSString *)path;
-(NSString *)SendReadString:(NSString *)cmd;

@end

NS_ASSUME_NONNULL_END
