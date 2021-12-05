//
//  FixtureDetector.h
//  DetectorPlugin
//
//  Created by Jayson on 2020/8/31.
//  Copyright © 2020 Jayson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AtlasLuaSequencer/AtlasLuaSequencer.h>
#import <AtlasDetection/AtlasDetection.h>
#import <AtlasIO/AtlasIO.h>

@interface FixtureDetector : NSObject<ATKPollDetector>

@property ATKLuaPlugin * client;
@property NSURL* transportURL;
@property NSNumber* pollingInterval;
@property NSNumber* site;

-(instancetype)initWithClient:(ATKLuaPlugin *)client transportURL:(NSString *)url pollingRestPeriod:(NSNumber *)pollingRestPeriod;

@end
