//
//  Eowyn.m
//  Eowyn
//
//  Created by gdlocal on 2021/6/17.
//  Copyright © 2021 gdlocal. All rights reserved.
//

#import <AtlasLuaSequencer/AtlasLuaSequencer.h>
#import <AtlasLogging/AtlasLogging.h>
#import "Eowyn.h"

@implementation Eowyn

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        fixtureCtl = [[fixtureControl alloc] init];
    }
    return self;
}


-(id)connectEowyn:(NSString *)ip withLogPath:(NSString *)path error:(NSError **)error
{
    int ret = [fixtureCtl initFixtureControl:ip withLogPath:path];
    return [NSNumber numberWithInt:ret];
}


-(id)writeReadString:(NSString *)cmd error:(NSError **)error
{
    return [fixtureCtl SendReadString:cmd];
}
-(id)fixture_open:(NSError **)error
{
    return [fixtureCtl SendReadString:@"release"];
}
-(id)fixture_close:(NSError **)error
{
    return [fixtureCtl SendReadString:@"press"];
}

-(id)led_red_on:(NSNumber *)site error:(NSError **)error
{
    status_flag = 0;
    NSString *cmd = [NSString stringWithFormat:@"redledon%@",site];
    return [fixtureCtl SendReadString:cmd];
}
-(id)led_green_on:(NSNumber *)site error:(NSError **)error
{
    status_flag = 0;
    NSString *cmd = [NSString stringWithFormat:@"greenledon%@",site];
    return [fixtureCtl SendReadString:cmd];
}
-(id)led_inprogress_on:(NSNumber *)site error:(NSError **)error
{
     status_flag = status_flag +1;
    if (status_flag !=0)
    {
        [fixtureCtl SendReadString:@"greenledon5"];
    }
    NSString *cmd = [NSString stringWithFormat:@"blueledon%@",site];
    return [fixtureCtl SendReadString:cmd];
}

-(id)led_gotoFA_on:(NSNumber *)site error:(NSError **)error
{
    return @"none";
}
-(id)led_panic_on:(NSNumber *)site error:(NSError **)error
{
    return @"none";
}
-(id)led_off:(NSNumber *)site error:(NSError **)error
{
    NSString *cmd = [NSString stringWithFormat:@"offledon%@",site];
    return [fixtureCtl SendReadString:cmd];
}

-(id)led_init:(NSError **)error
{
    [fixtureCtl SendReadString:@"blueledon5"];
//    [fixtureCtl SendReadString:@"offledon1"];
//    [fixtureCtl SendReadString:@"offledon2"];
//    [fixtureCtl SendReadString:@"offledon3"];
//    [fixtureCtl SendReadString:@"offledon4"];
    return @"none";
}

@end

#pragma mark -
#pragma mark Plugin Entry Point Functions

id PluginContextConstructor()
{
    return [Eowyn new];
}

NSDictionary *PluginFunctionTable()
{
    NSDictionary *fTable = @{
        // @"functionName" : @[ @[ ATKSelector(functionSignature), <arguments> ] ]
        @"connectEowyn" : @[@[ATKSelector(connectEowyn:withLogPath:error:),ATKString,ATKString]],
        @"writeReadString" : @[@[ATKSelector(writeReadString:error:),ATKString]],
        @"fixture_open" : @[@[ATKSelector(fixture_open:)]],
        @"fixture_close" : @[@[ATKSelector(fixture_close:)]],
        @"led_red_on" : @[@[ATKSelector(led_red_on:error:),ATKNumber]],
        @"led_green_on" : @[@[ATKSelector(led_green_on:error:),ATKNumber]],
        @"led_inprogress_on" : @[@[ATKSelector(led_inprogress_on:error:),ATKNumber]],
        @"led_gotoFA_on" : @[@[ATKSelector(led_gotoFA_on:error:),ATKNumber]],
        @"led_panic_on" : @[@[ATKSelector(led_panic_on:error:),ATKNumber]],
        @"led_off" : @[@[ATKSelector(led_off:error:),ATKNumber]],
        @"led_init" : @[@[ATKSelector(led_init:),]],
    };

    return fTable;
}

NSDictionary *PluginConstantTable()
{
    return @{
        //@"PI" : @M_PI
    };
}
