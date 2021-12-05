//
//  FixtureBundle.m
//  FixtureBundle
//
//  Created by eyen on 9/9/16.
//  Copyright © 2016 Apple. All rights reserved.
//

#import "FixtureBundle.h"
#import "CommonFixturePlugin.h"

@implementation FixtureBundle

- (void)registerBundlePlugins
{
    [self registerPluginName:@"CommonFixture" withPluginCreator:^id<CTPluginProtocol>(){
        return [[CommonFixturePlugin alloc] init];
    }];
}


@end
