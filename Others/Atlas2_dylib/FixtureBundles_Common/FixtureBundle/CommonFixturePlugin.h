/*!
 *	Copyright 2016 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  CommonFixturePlugin.h
 *  FixtureBundle
 *
 */

#import <CoreTestFoundation/CoreTestFoundation.h>
#import <Foundation/Foundation.h>
#include "DFUFixture.h"


// DO NOT REMOVE pluginame is used by UpdatePluginList.py script
// to automatically update CommonTestPlatform.plist file witht he plugin name and class name information
#define kCoreTestPluginName_CommonFixture @ "CommonFixture"

#define MAX_SLOT_PER_FIXTURE 6
#define kSectionId          @"sid"
#define kFixtureId          @"fid"
#define kNumOfStartedTests  @"numOfStartedTests"
#define kNumOfFinishedTests @"numOfFinishedTests"
#define kEnabledSlots       @"enabledSlots"
#define kFixtureController  @"fixtureController"
#define kFixtureOnline      @"fixtureOnline"
#define kNumOfPassedTests   @"numOfPassedTests"

#define CTGUICONFIG_FILENAME      @"CTGuiConfig.plist"
#define CTGUICONFIG_PATH_OVERRIDE @"~/Library/Atlas/config/"

#define kFixtureID          @"fixtureID"
#define kHeadID             @"headID"

#define kTESTERS             @"Testers"

// CommonFixture DO NOT REMOVE
// UpdatePluginList.py script matches the class name and Protocol
@interface CommonFixturePlugin : NSObject<CTPluginProtocol>
{
    NSMutableDictionary  *  _connectedFixtures;
    NSMutableArray *        _fixtureController;
    void **                 _fixtureControllerArray;
    NSString*               _vendor;
    NSDictionary*           _config;
}

@property (strong)CTContext  *pluginContext;

- (void)handleFixtureEvent:(int)eventType forSite:(int) site controller:(void*) controller withSN:(const char*) sn;

- (void)fixture_engage:(CTTestContext *)context;
- (void)fixture_disengage:(CTTestContext *)context;
- (void)handleUnitStart:(CTEvent *)eventInfo;
- (void)handleUnitFinished:(CTEvent *)eventInfo;
- (void)enter_dfu:(CTTestContext *)context;
- (void)enter_diags:(CTTestContext *)context;
- (void)enter_iboot:(CTTestContext *)context;
- (void)exit_dfu:(CTTestContext *)context;
- (void)led_red_on:(CTTestContext *)context;
- (void)led_green_on:(CTTestContext *)context;
- (void)led_off:(CTTestContext *)context;
- (void)dut_power_off:(CTTestContext *)context;
- (void)usb_on:(CTTestContext *)context;
- (void)usb_off:(CTTestContext *)context;

@end
