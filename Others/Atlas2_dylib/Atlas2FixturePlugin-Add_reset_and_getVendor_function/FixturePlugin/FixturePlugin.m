//
//  FixturePlugin.m
//  FixturePlugin
//
//  Created by swqt on 2020/9/23.
//  Copyright © 2020 swqt. All rights reserved.
//

#import <AtlasLuaSequencer/AtlasLuaSequencer.h>
#import <AtlasLogging/AtlasLogging.h>
#import "FixturePlugin.h"
#import "CommonFixture.h"
#import "FixtureDetector.h"

@implementation FixturePlugin


-(ATKLuaPlugin *)createFixtureBuilder:(NSNumber *)groupId error:(NSError *__autoreleasing *)error
{
    NSError *failureInfo;
    CommonFixture *commonFixture = [[CommonFixture alloc] initWithGroupId:[groupId intValue] error:&failureInfo];
    ATKLuaPlugin *atkLuaPlugin = [ATKLuaPlugin pluginWithContext:commonFixture functions:commonFixture.pluginFunctionTable constants:commonFixture.pluginConstantTable error:&failureInfo];
    if (failureInfo) {
        *error = failureInfo;
        ATKLogError("%@",failureInfo.localizedDescription);
    }
//    return [ATKLuaPlugin new];
    return atkLuaPlugin;
}

- (FixtureDetector <ATKPollDetector>*)createDeviceDetector:(ATKLuaPlugin *)dataChannel url:(NSString *)url pollingRestPeriod:(NSNumber *)pollingRestPeriod error:(NSError **)error {
    return [[FixtureDetector alloc] initWithClient:dataChannel transportURL:url pollingRestPeriod:pollingRestPeriod];
}

@end

#pragma mark -
#pragma mark Plugin Entry Point Functions

id PluginContextConstructor()
{
    return [FixturePlugin new];
}

NSDictionary *PluginFunctionTable()
{
    NSDictionary *fTable = @{
        // @"functionName" : @[ @[ ATKSelector(functionSignature), <arguments> ] ]
         @"createFixtureBuilder" : @[ @[ATKSelector(createFixtureBuilder:error:),ATKNumber]],
        @"createDeviceDetector" : @[ @[ ATKSelector(createDeviceDetector:url:pollingRestPeriod:error:),ATKProtocol(ATKLuaPluginProtocol),ATKString, ATKNumber ]],
    };

    return fTable;
}

NSDictionary *PluginConstantTable()
{
    return @{
        //@"PI" : @M_PI
    };
}
