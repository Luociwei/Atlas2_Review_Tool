/*!
 *	Copyright 2016 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "CommonFixturePlugin.h"
#import <IOKit/IOKitLib.h>
#import <FFCommunication/CTUnit+FFCommunication.h>
#import <FFCommunication/FFCommunication.h>

//#define PROCESS_DEBUG

@interface  CommonFixturePlugin()
{
}

@property (assign) BOOL bypassAutoDetect;
@property (assign) NSUInteger maxSlotsperFixture;

@end

void on_fixture_event(const char* sn, void *controller, void* event_ctx, int site, int event_type);
void on_stop_event_notification(void* ctx);


@implementation CommonFixturePlugin

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _connectedFixtures = [[NSMutableDictionary alloc] init];
        _fixtureController = [[NSMutableArray alloc] init];
        _config = nil;

    }

    return self;
}

- (CTVersion *)version
{
    // Plugin version is first parameter (specified by plugin owner)
    // project build version is the version given by the build system (use compiler variable here)
    // short description is a string describing what your plugin does.

    CTVersion *version = [[CTVersion alloc] initWithVersion:@"0.2.1"
                                        projectBuildVersion:@"Proto1"
                                           shortDescription:@"Common Fixture Bundle"];
    
    return version;
}


- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
#ifdef PROCESS_DEBUG
    volatile int value = 1;
    while (value);
#endif
    
    // Do plugin setup work here
    // This context is safe to store a reference of

    // Can also register for event at any time. Requires a selector that takes in one argument of CTEvent type.
    // [context registerForEvent:CTEventTypeUnitAppeared selector:@selector(handleUnitAppeared:)];
    // [context registerForEvent:@"Random event" selector:@selector(handleSomeEvent:)];
    CTLog(CTLOG_LEVEL_DEBUG,@"CommonFixtureBundle start");
    NSLog(@"CommonFixtureBundle start");
    
    self.maxSlotsperFixture = context.parameters[@"maxSlotsperFixture"] ? [context.parameters[@"maxSlotsperFixture"] unsignedIntegerValue] : MAX_SLOT_PER_FIXTURE;
    
    //
    self.bypassAutoDetect =  context.parameters[@"bypassAutoDetect"] ? [context.parameters[@"bypassAutoDetect"] boolValue] : 0;
    
     CTLog(CTLOG_LEVEL_DEBUG,@"bypassAutoDetect %d",self.bypassAutoDetect);

    if (context.parameters[@"configFilePath"])
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:context.parameters[@"configFilePath"]])
        {
            self->_config = [NSDictionary dictionaryWithContentsOfFile:context.parameters[@"configFilePath"]];
            CTLog(CTLOG_LEVEL_INFO,@"use config file %@",context.parameters[@"configFilePath"]);
            
            NSLog(@"self->_config %@",self->_config);
        }
    }
    const char * vendor = get_vendor();

    _vendor = [NSString stringWithUTF8String:vendor];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"************* %s fixture start ***********",vendor);
    NSLog(@"************* %s fixture start ***********",vendor);
    
    [context registerForEvent:CTEventTypeUnitStart selector:@selector(handleUnitStart:)];
    [context registerForEvent:CTEventTypeUnitFinished selector:@selector(handleUnitFinished:)];
    
//    NSString * resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
//    NSLog(@"fixtureBundle's resource path %@",resourcePath);
    
    if([context.parameters objectForKey:@"maxConnectedFixtures"])
    {
        NSLog(@"maxConnectedFixtures %@",[context.parameters objectForKey:@"maxConnectedFixtures"]);
        NSUInteger maxConnectedFixtures = [[context.parameters objectForKey:@"maxConnectedFixtures"] unsignedIntegerValue];
        
        _fixtureControllerArray = (void**) malloc(maxConnectedFixtures*sizeof(void*));
        
        for (int index = 0; index < maxConnectedFixtures; index++)
        {
            NSMutableDictionary * fixture = [[NSMutableDictionary alloc] init];
            
            [fixture setObject:[NSNumber numberWithInt:index] forKey:kFixtureId];
            [fixture setObject:[NSNumber numberWithUnsignedInt:0] forKey:kNumOfStartedTests];
            [fixture setObject:[NSNumber numberWithUnsignedInt:0]forKey:kNumOfFinishedTests];
            [fixture setObject:[NSNumber numberWithUnsignedInt:0] forKey:kEnabledSlots];
            [fixture setObject:[NSNumber numberWithUnsignedInt:0]forKey:kNumOfPassedTests];
            
            //assume all fixture online for now
            [fixture setObject:[NSNumber numberWithBool:YES] forKey:kFixtureOnline];
            CTLog(CTLOG_LEVEL_DEBUG,@"FixtureBundle fixture %d online", index);
            
            NSLog(@"FixtureBundle fixture %d online", index);
            
            [_connectedFixtures setObject:fixture forKey:[NSString stringWithFormat:@"%d",index]];
            
            void * thisFixture = create_fixture_controller(index);
            
            _fixtureControllerArray[index] = thisFixture;
//            [_fixtureController addObject:(__bridge id)thisFixture];

//            NSLog(@"FixtureBundle create_fixture_controller %d, _fixtureController %@", index,[_fixtureController description]);
            CTLog(CTLOG_LEVEL_INFO,@"FixtureBundle create_fixture_controller %d, Vendor: %@, Version: %s", index, _vendor, get_version(thisFixture));

            
        }
        
        [_connectedFixtures setObject:[NSUUID UUID] forKey:kSectionId];        
    }
    
    CTLog(CTLOG_LEVEL_DEBUG,@"Completed Setup of CommonFixtureBundle, total of connected fixture %@",[_connectedFixtures description]);
    
    [NSThread detachNewThreadSelector:@selector(initFixture) toTarget:self withObject:nil];
    
    self.pluginContext = context;
    

    
    return YES;

}


- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    // Do plugin teardown work here
    return YES;
}

- (BOOL)initFixture
{
    //default open fixture when init
    int status = 0;
    
    NSArray * fixtureIds = [self getConnectedFixtureIds];
    
    @synchronized(_fixtureController)
    {
        for (NSString * fixturId in fixtureIds)
        {
            NSLog(@"initFixture %@",fixturId);
            void * fixtureController = (void*) _fixtureControllerArray[[fixturId intValue]];
            status = init(fixtureController);
            NSLog(@"initFixture %@ status %d",fixturId,status);
            
            setup_event_notification(fixtureController, (__bridge void *)(self), on_fixture_event, on_stop_event_notification);

        }
    }
    
    return (status)?NO:YES;
}

- (CTCommandCollection *)commmandDescriptors
{
    // Collection contains descriptions of all the commands exposed by a plugin
    CTCommandCollection *collection = [CTCommandCollection new];
    CTCommandDescriptor *command = [CTCommandDescriptor new];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"Engage Fixture" selector:@selector(fixture_engage:) description:@"Bring fixture to start testing"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"Disengage Fixture" selector:@selector(fixture_disengage:) description:@"Bring fixture to stop testing"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"Enter DFU" selector:@selector(enter_dfu:) description:@"Entering DFU Mode..."];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"Exit DFU" selector:@selector(exit_dfu:) description:@"DFU Mode Compeleted"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"SET UART SIGNAL ON" selector:@selector(set_uart_signal_on:) description:@"set uart signal"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"Enter DIAGS" selector:@selector(enter_diags:) description:@"Entering DIAGS Mode"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"Enter IBOOT" selector:@selector(enter_iboot:) description:@"Entering IBOOT Mode"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"LED RED ON" selector:@selector(led_red_on:) description:@"LED RED ON"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"LED GREEN ON" selector:@selector(led_green_on:) description:@"LED GREEN ON"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"LED INPROGRESS ON" selector:@selector(led_inprogress_on:) description:@"LED INPROGRESS ON"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"LED GOTO FA ON" selector:@selector(led_gotoFA_on:) description:@"LED GOTO FA ON"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"LED PANIC ON" selector:@selector(led_panic_on:) description:@"LED PANIC ON"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"LED OFF" selector:@selector(led_off:) description:@"LED OFF"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"POWER OFF" selector:@selector(dut_power_off:) description:@"POWER OFF"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"POWER ON" selector:@selector(dut_power_on:) description:@"POWER ON"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"USB ON" selector:@selector(usb_on:) description:@"USB ON"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"USB OFF" selector:@selector(usb_off:) description:@"USB OFF"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"BATT ON" selector:@selector(batt_on:) description:@"BATT ON"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"BATT OFF" selector:@selector(batt_off:) description:@"BATT OFF"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"GET UNIT SN" selector:@selector(get_serialNumber:) description:@"GET UNIT SN"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"SET STATION ATTRIBUTES" selector:@selector(setStationAttributes:) description:@"SET STATION ATTRIBUTES"];
    [collection addCommand:command];

    command = [[CTCommandDescriptor alloc] initWithName:@"IS FIXTURE CLOSED" selector:@selector(isFixtureClosed:) description:@"CHECK FIXTURE CLOSE STATUS"];
    [collection addCommand:command];
   
    command = [[CTCommandDescriptor alloc] initWithName:@"CHECK DUT IN DFU" selector:@selector(isDeviceinDFU:) description:@"CHECK IF DUT IS IN DFU MODE"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"CREATE UNIT TRANSPORT" selector:@selector(createUnitTransport:) description:@"CREATES UNIT TRANSPORT WITH USB LOCATION"];
    [collection addCommand:command];
    
    command = [[CTCommandDescriptor alloc] initWithName:@"getUsbLocation" selector:@selector(getUsbLocation:) description:@"returns the usb location for this unit"];
    [collection addCommand:command];
    
    return collection;
}


/*
 * handleUnitStart()
 * This function is called when unit start events are sent by the core
 * This function can engage the fixture when all units appear by checking against
 * the number of enabled slots from the setup.  
 * Notes: If it is not necessary to automatically close and engaged the fixture don't set any enabled slots at setup.
 */
- (void)handleUnitStart:(CTEvent *)eventInfo
{

#ifdef PROCESS_DEBUG
    volatile int value = 1;
    while(value);
#endif
    
    CTUnit *thisUnit = [eventInfo getUnit];
    
    CTLog(CTLOG_LEVEL_DEBUG, @"Unit started: %@", thisUnit.identifier);
    
    if([thisUnit.userInfo objectForKey:@"enabledSlots"])
    {
        [self setupFixtures:thisUnit.userInfo];
    }
    
    BOOL needCloseFixture = FALSE;
    NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];

    @synchronized(_connectedFixtures)
    {
        
        NSMutableDictionary * thisFixture = [_connectedFixtures objectForKey:fixtureId];
        
        NSNumber * enabledSlotsCnt = [thisFixture objectForKey:kEnabledSlots];
        NSNumber * numOfStartedTests = [thisFixture objectForKey:kNumOfStartedTests];
        
        numOfStartedTests = [NSNumber numberWithUnsignedInt:[numOfStartedTests unsignedIntValue] +1];
        
        //update original info
        [thisFixture removeObjectForKey:kNumOfStartedTests];
        [thisFixture setObject:numOfStartedTests forKey:kNumOfStartedTests];
        
        NSLog(@"handleUnitStart thisFixture %@, uid %@",[thisFixture description],thisUnit.identifier);
        
        CTLog(CTLOG_LEVEL_DEBUG, @"Unit started: %@ - numOfStartedTests %@, numOfEnabledSlots %@", thisUnit.identifier,numOfStartedTests, enabledSlotsCnt);
        
        if (enabledSlotsCnt && [numOfStartedTests isEqualToNumber: enabledSlotsCnt])
        {
            CTLog(CTLOG_LEVEL_DEBUG, @"ALL Unit started: - Close and engage the fixture %@", fixtureId);
            
            needCloseFixture = TRUE;
            NSLog(@"ALL Unit started: fid %@ %@",fixtureId, [_connectedFixtures description]);
        }
        else
        {
            CTLog(CTLOG_LEVEL_ERR, @"no enabled slots");
        }
    }
    // todo : need check engage result
    if (needCloseFixture)
    {
        [self closeFixture:fixtureId];
    }

}

- (void)handleUnitFinished:(CTEvent *)eventInfo
{
    
#ifdef PROCESS_DEBUG
    volatile int value = 1;
    while (value);
#endif
    
    CTUnit *thisUnit = [eventInfo getUnit];

    NSNumber * unitOverallStatus = eventInfo.userInfo[CTEventUnitOverallStatusKey];

    CTLog(CTLOG_LEVEL_DEBUG, @"%@, Unit finished, %@, unitOverallStatus %@",thisUnit.identifier, eventInfo.userInfo[CTEventUnitSequenceKey],eventInfo.userInfo[CTEventUnitOverallStatusKey]);
    
    BOOL needOpenFixture = FALSE;
    
    NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
    
    @synchronized(_connectedFixtures)
    {
        
        NSMutableDictionary * thisFixture = [_connectedFixtures objectForKey:fixtureId];
        
        NSNumber * numOfStartedTests = [thisFixture objectForKey:kNumOfStartedTests];
        NSNumber * numOfFinishedTests = [thisFixture objectForKey:kNumOfFinishedTests];
        NSNumber * numOfPassedTests = [thisFixture objectForKey:kNumOfPassedTests];
        
        numOfFinishedTests = [NSNumber numberWithUnsignedInt:[numOfFinishedTests unsignedIntValue] +1];
        
        if ([unitOverallStatus intValue] == CTRecordStatusPass)
        {
            numOfPassedTests = [NSNumber numberWithUnsignedInt:[numOfPassedTests unsignedIntValue] +1];
        }
        //update original info
        [thisFixture removeObjectForKey:kNumOfFinishedTests];
        [thisFixture setObject:numOfFinishedTests forKey:kNumOfFinishedTests];
        
        [thisFixture removeObjectForKey:numOfPassedTests];
        [thisFixture setObject:numOfFinishedTests forKey:numOfPassedTests];
        
        CTLog(CTLOG_LEVEL_DEBUG, @"fixture %@ numOfStartedTests %@ numOfFinishedTests %@, numOfPassedTests %@",fixtureId,numOfStartedTests,numOfFinishedTests,numOfPassedTests);
        
        if([numOfStartedTests isEqualToNumber: numOfFinishedTests])
        {
            CTLog(CTLOG_LEVEL_INFO, @"all tests finished ejecting fixture");

            
            //also clean start and finished enabledSlots tests + enabled Slots
            [thisFixture removeObjectForKey:kNumOfStartedTests];
            [thisFixture setObject:[NSNumber numberWithUnsignedInt:0] forKey:kNumOfStartedTests];
            
            [thisFixture removeObjectForKey:kNumOfFinishedTests];
            [thisFixture setObject:[NSNumber numberWithUnsignedInt:0]forKey:kNumOfFinishedTests];
            
            [thisFixture removeObjectForKey:kEnabledSlots];
            [thisFixture setObject:[NSNumber numberWithUnsignedInt:0] forKey:kEnabledSlots];
            
            if (YES == [[[NSBundle bundleForClass:[self class]]
                       objectForInfoDictionaryKey:@"OpenFixtureOnlyWhenAllPass"] boolValue])
            {
                CTLog(CTLOG_LEVEL_DEBUG, @"OpenFixtureOnlyWhenAllPass is set to TRUE, check if all units passed");
                
                if ([numOfPassedTests isEqualToNumber:numOfFinishedTests])
                {
                    needOpenFixture = TRUE;
                }
                else
                {
                    CTLog(CTLOG_LEVEL_DEBUG, @"OpenFixtureOnlyWhenAllPass is set to TRUE, numOfFinishedTests %@, numOfPassedTests %@, skip fixture %@ open",numOfFinishedTests,numOfPassedTests,fixtureId);
                }
                
            }
            else
            {
                needOpenFixture = TRUE;
            }

            [thisFixture removeObjectForKey:kNumOfPassedTests];
            [thisFixture setObject:[NSNumber numberWithUnsignedInt:0] forKey:kNumOfPassedTests];

            NSLog(@"ALL Unit finished: fid %@ %@",fixtureId, [_connectedFixtures description]);
        }
    }
    
    if (needOpenFixture)
    {
        CTLog(CTLOG_LEVEL_DEBUG, @"ALL unit finished test, open fixture %@",fixtureId);

        [self openFixture:fixtureId];
    }
}

- (void) setupFixtures:(NSDictionary*) userInfo
{
    BOOL needSetupLed = FALSE;
    
    @synchronized(_connectedFixtures)
    {
        if ([userInfo objectForKey:kSectionId])
        {
            NSUUID * userInfoSid = [[NSUUID alloc] initWithUUIDString:[userInfo objectForKey:kSectionId]];

            
            if ([userInfoSid isEqualTo:[_connectedFixtures objectForKey:kSectionId]])
            {
                //already setup, skip
            }
            else
            {
                NSArray * enabledSlots = [userInfo objectForKey:kEnabledSlots];
                
                for (NSString* aSlot in enabledSlots)
                {
                    NSString* fid = [self fixtureBySlotId:aSlot];
                    NSMutableDictionary * thisFixture = [_connectedFixtures objectForKey:fid];
                    
                    if (thisFixture)
                    {
                        NSNumber* enabledSlotsNum = [thisFixture objectForKey:kEnabledSlots];
                        enabledSlotsNum = [NSNumber numberWithUnsignedInt:[enabledSlotsNum unsignedIntValue] +1];
                        
                        [thisFixture removeObjectForKey:kEnabledSlots];
                        [thisFixture setObject:enabledSlotsNum forKey:kEnabledSlots];
                        
                        [thisFixture removeObjectForKey:kNumOfStartedTests];
                        [thisFixture setObject:[NSNumber numberWithUnsignedInt:0] forKey:kNumOfStartedTests];
                        
                        [thisFixture removeObjectForKey:kNumOfFinishedTests];
                        [thisFixture setObject:[NSNumber numberWithUnsignedInt:0]forKey:kNumOfFinishedTests];
                    }
                    
                    needSetupLed = TRUE;
                    
                }
                //add new sid
                [_connectedFixtures removeObjectForKey:kSectionId];
                [_connectedFixtures setObject:userInfoSid forKey:kSectionId];
                NSLog(@"setupFixtures _connectedFixtures %@", [_connectedFixtures description]);
            }
        }
    }
    
    if (needSetupLed)
    {
        NSArray * enabledSlots = [userInfo objectForKey:kEnabledSlots];
        
        @synchronized(_fixtureController)
        {
            for (NSString* aSlot in enabledSlots)
            {
                NSString* fixtureId = [self fixtureBySlotId:aSlot];

                if ([self validateFixtureId:fixtureId])
                {
                    void * fixtureController = (void *)(_fixtureControllerArray[[fixtureId integerValue]]);
                    
                    int slotID = [self SlotIdNum:aSlot];
                    set_led_state(fixtureController, OFF, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
    
                }
                else
                {
                    CTLog(CTLOG_LEVEL_DEBUG, @"error: _fixtureController count %lu less than fixtureId %@", (unsigned long)[_fixtureController count],fixtureId);
                    
                    NSLog(@"error: _fixtureController count %lu less than fixtureId %@", (unsigned long)[_fixtureController count],fixtureId);
                    
                }
            }
        }
    }
}

- (void)fixture_engage:(CTTestContext *)context
{
    [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
        NSString *cmd = context.commandName;
        NSDate *start = [NSDate date];
        NSError *err;
        
        int status = 0;
        
        [context logWithLevel:CTLOG_LEVEL_INFO message:@"Engage Fixture: %@", cmd];
        
        NSArray * fixtureIds = [self getConnectedFixtureIds];
        
        @synchronized(_fixtureController)
        {
            for (NSString * fixturId in fixtureIds)
            {
                status = [self closeFixture:fixturId];

            }
        }
        
        CTRecordSet *records = [CTRecordSet new];
        [records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                     status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                failureInfo:nil
                                   priority:CTRecordPriorityRequired
                                  startTime:start
                                    endTime:[NSDate date] error:&err];
        if (!status)
        {
            return CTRecordStatusPass;
        }
        else
            return CTRecordStatusFail;
        
    }];
}

- (void)fixture_disengage:(CTTestContext *)context
{
    [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
        
        NSString *cmd = context.commandName;
        NSDate *start = [NSDate date];
        NSError *err;
        int status = 0;
        
        [context logWithLevel:CTLOG_LEVEL_INFO message:@"Disenagage Fixture: %@", cmd];
        
        NSArray * fixtureIds = [self getConnectedFixtureIds];
        
        @synchronized(_fixtureController)
        {
            for (NSString * fixturId in fixtureIds)
            {
                status = [self openFixture:fixturId];
                
            }
        }

        
        CTRecordSet *records = [CTRecordSet new];
        [records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                     status:(!status)? CTRecordStatusPass : CTRecordStatusFail
                                failureInfo:nil
                                   priority:CTRecordPriorityRequired
                                  startTime:start
                                    endTime:[NSDate date] error:&err];
        
        if (!status)
        {
            return CTRecordStatusPass;
        }
        else
            return CTRecordStatusFail;
    }];
}

- (void)enter_dfu:(CTTestContext *)context
{
    
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start enter_dfu Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_force_dfu(fixtureController, TURN_ON, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished enter_dfu Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", @"Enter DFU"]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)exit_dfu:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start exit_dfu Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_force_dfu(fixtureController, TURN_OFF, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished exit_dfu Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", @"EXIT DFU"]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)enter_diags:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start enter_diags Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            status = set_force_diags(fixtureController, TURN_ON, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished enter_diags Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", @"Enter DIAGS"]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)enter_iboot:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start enter_iboot Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_force_iboot(fixtureController, TURN_ON, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished enter_iboot Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", @"Enter IBOOT"]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)set_uart_signal_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start set uart signal Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            status = set_uart_signal(fixtureController, CLOSE_RELAY, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished set uart signal Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", @"Enter IBOOT"]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)led_red_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start led_red_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_led_state(fixtureController, FAIL, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished led_red_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)led_gotoFA_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start led_gotoFA_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            status = set_led_state(fixtureController, FAIL_GOTO_FA, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished led_gotoFA_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}


- (void)led_green_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start led_green_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_led_state(fixtureController, PASS, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished led_green_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)led_inprogress_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start led_inprogress_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_led_state(fixtureController, INPROGRESS, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished led_inprogress_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)led_panic_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start led_panic_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            status = set_led_state(fixtureController, PANIC, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished led_panic_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)led_off:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start led_off Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_led_state(fixtureController, OFF, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished led_off Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}
- (void)usb_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start usb_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_usb_power(fixtureController, TURN_ON, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished usb_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)usb_off:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start usb_off Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_usb_power(fixtureController, TURN_OFF, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        CTLog(CTLOG_LEVEL_DEBUG,@"finished usb_off Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)batt_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start batt_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            status = set_battery_power(fixtureController, TURN_ON, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished batt_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)batt_off:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start batt_off Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            status = set_battery_power(fixtureController, TURN_OFF, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        CTLog(CTLOG_LEVEL_DEBUG,@"finished batt_off Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
        
    }
}

- (void)dut_power_off:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start dut_power_off Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
        
            status = set_dut_power(fixtureController, TURN_OFF, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished dut_power_off Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
    }
}

- (void)dut_power_on:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start dut_power_on Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            status = set_dut_power(fixtureController, TURN_ON, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
        }
        else
        {
            status = -1;
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished dut_power_on Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(!status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (!status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
    }
}


- (NSString*)get_serialNumber:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    
    CTUnit *thisUnit = context.unit;
    NSString * serialNumber = nil;
    
    if([thisUnit.userInfo objectForKey:@"SnNum"])
    {
        serialNumber = [thisUnit.userInfo objectForKey:@"SnNum"];
        CTLog(CTLOG_LEVEL_DEBUG, @"get_serialNumber for Unit : %@ Sn: %@", thisUnit.identifier,serialNumber);
    }
    

        NSError *recordErr = nil;
        [context setOutput:serialNumber?serialNumber:@"NoSn"];
        [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                         status:serialNumber ? CTRecordStatusPass:CTRecordStatusFail
                                    failureInfo:nil
                                       priority:CTRecordPriorityRequired
                                      startTime:start
                                        endTime:[NSDate date] error:&recordErr];

    return serialNumber;
}


- (void)setStationAttributes:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    
    CTUnit *thisUnit = context.unit;
    
    //read gh_station_info for STATION_NUMBER
    
    NSString * station_number = [self getStationNumber];
    
    NSString * fixtureId = _vendor;
    
    if (station_number)
    {
        fixtureId = [NSString stringWithFormat:@"%@-%@",_vendor,station_number];
    }
    NSDictionary * stationAttributes = [NSDictionary dictionaryWithObjectsAndKeys:fixtureId,kFixtureID,
                                                    thisUnit.identifier,kHeadID,nil];
    NSError *err = nil;
    
    BOOL status = [context.records addStationAttributes:stationAttributes error:&err];
    
    NSLog(@"fixture addStationAttributes %@", [stationAttributes description]);
    
    [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
        
        NSError *recordErr = nil;
        [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                             status:(status) ? CTRecordStatusPass : CTRecordStatusFail
                                        failureInfo:nil
                                           priority:CTRecordPriorityRequired
                                          startTime:start
                                            endTime:[NSDate date] error:&recordErr];
        
        return (status) ? CTRecordStatusPass : CTRecordStatusFail;
    }];
}

- (void)isFixtureClosed:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    bool status = false;
    
    CTUnit *thisUnit = context.unit;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start isFixtureClosed Current Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            status = is_fixture_closed(fixtureController, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
            
            if (!status)
            {
                CTLog(CTLOG_LEVEL_DEBUG,@"is_fixture_closed return false Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
            }
            
            status = is_fixture_engaged(fixtureController, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
                
            if (!status)
            {
                CTLog(CTLOG_LEVEL_DEBUG,@"is_fixture_engaged return false Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
            }
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished isFixtureClosed Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
        
        [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
            
            NSError *recordErr = nil;
            [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                                 status:(status) ? CTRecordStatusPass : CTRecordStatusFail
                                            failureInfo:nil
                                               priority:CTRecordPriorityRequired
                                              startTime:start
                                                endTime:[NSDate date] error:&recordErr];
            
            return (status) ? CTRecordStatusPass : CTRecordStatusFail;
        }];
    }
}

- (void)isDeviceinDFU:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    NSDate *start = [NSDate date];
    id interval = context.parameters[@"interval"];
    id maxRetry = context.parameters[@"retry"];
    NSInteger retry=0;
    
    CTUnitTransport *unitTransport = [context.unit unitTransportsWithScheme:@"lockdown"][0];
    NSString *locationId = unitTransport.url.host; // lockdown://0x12340000
    
    if(!interval || [interval integerValue] == 0 || [interval integerValue] > 10 ) {
        interval = [NSNumber numberWithInteger:2];
    }
    
    if(!maxRetry || [maxRetry integerValue] == 0 || [maxRetry integerValue] > 10) {
        maxRetry = [NSNumber numberWithInteger:3];
    }
    
    BOOL status = false;
    while (retry <= [maxRetry integerValue])
    {
        if(retry > 0) {
            CTLog(CTLOG_LEVEL_DEBUG, @"%@: retry %ld...", cmd, retry);
            NSLog(@"%@: retry %ld...", cmd, retry);
        }
        status = [self isDFUDeviceFound:locationId];
        if(status) {
            break;
        }
        [NSThread sleepForTimeInterval:[interval integerValue]];
        retry++;
    }

    [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
        
        NSError *recordErr = nil;
        [context.records addPassFailRecordWithNames:@[@"FixtureAction", cmd]  // TODO: proper name
                                             status:(status) ? CTRecordStatusPass : CTRecordStatusFail
                                        failureInfo:nil
                                           priority:CTRecordPriorityRequired
                                          startTime:start
                                            endTime:[NSDate date] error:&recordErr];
        
        return (status) ? CTRecordStatusPass : CTRecordStatusFail;
    }];
}

- (int) openFixture: (NSString*) fixtureId
{
    int status = 0;
    
    @synchronized(_fixtureController)
    {
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            int status = fixture_disengage(fixtureController, 0);
            
            [NSThread sleepForTimeInterval:3.0];
            
            if (!status)
            {
                status = fixture_open(fixtureController, 0);
            }
            else
            {
                CTLog(CTLOG_LEVEL_DEBUG, @"fixture_disengage errored: %@ status = %d", fixtureId,status);
                NSLog(@"fixture_disengage errored: %@ status = %d", fixtureId,status);
            }
            
            if (status)
            {
                CTLog(CTLOG_LEVEL_DEBUG, @"fixture_open errored: %@ status = %d", fixtureId,status);
                NSLog(@"fixture_open errored: %@ status = %d", fixtureId,status);
                
            }
            
        }
        else
        {
            status = -1;
        }
        
    }
    
    [NSThread sleepForTimeInterval:3.0];
    
    return status;
}

- (int) closeFixture: (NSString*) fixtureId
{
    int status = 0;
    
    @synchronized(_fixtureController)
    {
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            int status = fixture_close(fixtureController, 0);
            
            [NSThread sleepForTimeInterval:3.0];
            
            if (!status)
            {
                status = fixture_engage(fixtureController, 0);
            }
            else
            {
                CTLog(CTLOG_LEVEL_DEBUG, @"fixture_close errored: %@ status = %d", fixtureId,status);
                NSLog(@"fixture_close errored: %@ status = %d", fixtureId,status);
            }
            
            if (status)
            {
                CTLog(CTLOG_LEVEL_DEBUG, @"fixture_engage errored: %@ status = %d", fixtureId,status);
                NSLog(@"fixture_engage errored: %@ status = %d", fixtureId,status);
                
            }
            
        }
        else
        {
            CTLog(CTLOG_LEVEL_DEBUG, @"Close Fixture error: _fixtureController count %lu less than fixtureId %@", (unsigned long)[_fixtureController count],fixtureId);
            
            NSLog(@"Close Fixture error: _fixtureController count %lu less than fixtureId %@", (unsigned long)[_fixtureController count],fixtureId);
            
            status = -1;
        }
        
    }
    
    [NSThread sleepForTimeInterval:3.0];
    
    return status;
}

-(NSString*) fixtureBySlotId:(NSString*)slotId
{
    NSArray *slotIDTemp = [slotId componentsSeparatedByString:@"-"];
    int fid = 0;
    
    if ([slotIDTemp count]>1)
    {
        int enabledSlotID = [slotIDTemp[1] intValue];
        if (enabledSlotID)
        {
            fid = (enabledSlotID-1) / self.maxSlotsperFixture;
        }
        else
        {
            //slotID should always start from 1
            fid = enabledSlotID / self.maxSlotsperFixture;
        }
    }
    return [NSString stringWithFormat:@"%d",fid];
}

-(int) SlotIdNum:(NSString*)slotId
{
    NSArray *slotIDTemp = [slotId componentsSeparatedByString:@"-"];
    int numSlotId = 0;
    
    if ([slotIDTemp count]>1)
    {
        numSlotId = [slotIDTemp[1] intValue];
    }
    return numSlotId;
}

-(NSArray*) getConnectedFixtureIds
{
    NSArray * fixtureIds = nil;
    
    @synchronized(_connectedFixtures)
    {
        NSPredicate *findFixtureId = [NSPredicate predicateWithFormat:@"NOT SELF CONTAINS 'sid'"];
        
        fixtureIds = [[NSArray alloc] initWithArray:[[_connectedFixtures allKeys] filteredArrayUsingPredicate:findFixtureId] copyItems:YES];
                      
    }
    
//    NSLog(@"getConnectedFixtureIds %@",[fixtureIds description]);
    return fixtureIds;
}

-(BOOL) validateFixtureId:(NSString*)fixtureId
{
    NSPredicate *findFixtureId = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@",fixtureId];
    NSArray * fixtureIds = [[self getConnectedFixtureIds] filteredArrayUsingPredicate:findFixtureId];
    
    if ([fixtureIds count])
    {
        NSLog(@"validateFixtureId fixtureId %@ is valid",fixtureId);
        return YES;
    }
    else
    {
        NSLog(@"validateFixtureId fixtureId %@ is not valid, fixtureIds %@",fixtureId,[fixtureIds description]);
        return NO;
    }
}

- (NSString*) getStationNumber
{
    
    NSString * stationInfoFilePath = @"/vault/data_collection/test_station_config/gh_station_info.json";
    NSString * stationNumber = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:stationInfoFilePath])
    {
        NSData * jdata = [NSData dataWithContentsOfFile:stationInfoFilePath];
        if (jdata)
        {
            NSDictionary * stationInfo = [NSJSONSerialization JSONObjectWithData:jdata
                                                                         options:NSJSONReadingAllowFragments|NSJSONReadingMutableContainers
                                                                           error:nil];
            
            if (stationInfo)
            {
                if ([stationInfo objectForKey:@"ghinfo"])
                {
                    stationNumber = [[stationInfo objectForKey:@"ghinfo"] objectForKey:@"STATION_NUMBER"];
                }
            }
        }
    }
    return stationNumber;
}

- (BOOL) isDFUDeviceFound:(NSString*) locationIdString
{
    bool retValue = false;
    
    kern_return_t kr = KERN_SUCCESS;
    io_iterator_t usbDeviceItr = IO_OBJECT_NULL;
    
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault,IOServiceMatching("IOUSBDevice"),&usbDeviceItr);
    
    if((kr == KERN_SUCCESS) && (usbDeviceItr != IO_OBJECT_NULL))
    {
        io_service_t aUSBDevice = IO_OBJECT_NULL;
        
        while((aUSBDevice = IOIteratorNext(usbDeviceItr)))
        {
            // Found an IOService matching a USB Port
            // Check the LocationID
            id value = (id)CFBridgingRelease(IORegistryEntrySearchCFProperty(aUSBDevice,
                                                                             kIOServicePlane,
                                                                             CFSTR("locationID"),
                                                                             kCFAllocatorDefault,
                                                                             0L));
            
            if(value && [value isKindOfClass:[NSNumber class]] &&
               [locationIdString isEqualToString:[NSString stringWithFormat:@"0x%x", [(NSNumber*)value intValue]]])
            {
                
                
                id productName = (id)CFBridgingRelease(IORegistryEntrySearchCFProperty(aUSBDevice,
                                                                                       kIOServicePlane,
                                                                                       CFSTR("USB Product Name"),
                                                                                       kCFAllocatorDefault,
                                                                                       0L));
                
                if ([productName isKindOfClass:[NSString class]])
                {
                    if ([productName rangeOfString:@"Apple Mobile Device (DFU Mode)"].location != NSNotFound)
                    {
                        IOObjectRelease(aUSBDevice);
                        NSLog(@"found Apple Mobile Device in DFU mode at %@",locationIdString);
                        retValue = true;
                        break;
                    }
                }
                
                
            }
            
            IOObjectRelease(aUSBDevice);
        }
        
        IOObjectRelease(usbDeviceItr);
    }
    return retValue;
}

/*
 * returns the usb location in format 0x14130000
 */

-(void)getUsbLocation:(CTTestContext *)context
{
    NSString *cmd = context.commandName;
    int status =0;
    
    CTUnit *thisUnit = context.unit;
    NSString *locationId;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start get usb Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            const char *usbLocationId = get_usb_location(fixtureController, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
            if (usbLocationId)
            {
                locationId = [NSString stringWithUTF8String:usbLocationId];
                status = 1;
            }
            else
            {
                CTLog(CTLOG_LEVEL_ERR, @"failed to get usblocation");
                status = 0;
            }
            
        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished getusb_location Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
    }
    
    if (status)
    {
        CTLog(CTLOG_LEVEL_INFO, @"got usblocation %@",locationId);
    }
    [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
        
        context.output = locationId;
        
        if (!status)
        {
            *failureInfo = [CTError errorWithDomain:@"com.apple.hwte.atlas.fixture" errorCode:1 format:@"error getting usb location"];
        }
        return (status) ? CTRecordStatusPass : CTRecordStatusFail;
    }];
}

-(void)createUnitTransport:(CTTestContext *)context
{
    
#ifdef PROCESS_DEBUG
    volatile int value = 1;
    while (value);
#endif
    
    NSString *cmd = context.commandName;
    int status =0;

    CTUnit *thisUnit = context.unit;
    NSString *locationId;
    
    int slotID = [self SlotIdNum:thisUnit.identifier];
    
    CTLog(CTLOG_LEVEL_DEBUG,@"cmd: %@ Current Unit: %@ - Slot: %d", cmd, thisUnit.identifier, slotID);
    [NSThread sleepForTimeInterval:0.5];  //FIXME: why is this here?
    
    @synchronized(_fixtureController)
    {
        CTLog(CTLOG_LEVEL_DEBUG,@"start get usb Unit : %@ - Slot: %d", thisUnit.identifier, slotID);
        
        NSString* fixtureId = [self fixtureBySlotId:thisUnit.identifier];
        
        if ([self validateFixtureId:fixtureId])
        {
            void * fixtureController = (void*) _fixtureControllerArray[[fixtureId integerValue]];
            
            const char *usbLocationId = get_usb_location(fixtureController, (slotID<=self.maxSlotsperFixture)?slotID:(slotID-self.maxSlotsperFixture));
            if (usbLocationId)
            {
                locationId = [NSString stringWithUTF8String:usbLocationId];
                status = 1;
            }
            else
            {
                CTLog(CTLOG_LEVEL_ERR, @"failed to get usblocation");
                status = 0;
            }

        }
        
        CTLog(CTLOG_LEVEL_DEBUG,@"finished getusb_location Current Unit: %@ - Slot: %d status %d", thisUnit.identifier, slotID,status);
    }
    
    if (status)
    {
        CTLog(CTLOG_LEVEL_INFO, @"got usblocation %@",locationId);
        FFFactoryServicesDut *usbComms = [FFFactoryServicesDut factoryServicesWithLocationId:locationId config:nil];
        
        CTUnitTransport  *unitTrasportusb = [CTUnitTransport unitTransportFromFFCommunication:usbComms];
        NSArray *ctUnitTransportArray = @[unitTrasportusb];
        CTUnit *unit = context.unit;
        unit.unitTransports = ctUnitTransportArray;
        
        [context unitUpdate:unit];
    }
    [context runTestWithPriority:CTRecordPriorityRequired test:^CTRecordStatus (NSError *__autoreleasing *failureInfo) {
        if (!status)
        {
            *failureInfo = [CTError errorWithDomain:@"com.apple.hwte.atlas.fixture" errorCode:1 format:@"error getting usb location"];
        }
        return (status) ? CTRecordStatusPass : CTRecordStatusFail;
    }];
    
}

void on_fixture_event(const char* sn, void *controller, void* event_ctx, int site, int event_type)
{
//#ifdef PROCESS_DEBUG
//    volatile int value = 1;
//    while (value);
//#endif
    
    NSLog(@"fixture event call back : %s, %d, %d",sn, site,event_type);
    CTLog(CTLOG_LEVEL_INFO,@"fixture event call back : %s, %d, %d",sn, site,event_type);
    
    CommonFixturePlugin *thisPlugin = (__bridge CommonFixturePlugin *)(event_ctx);
    if (thisPlugin.bypassAutoDetect)
    {
        CTLog(CTLOG_LEVEL_INFO,@"bypass autodetect");
        return;
    }
//    CommonFixturePlugin *thisPlugin = (CommonFixturePlugin *)CFBridgingRelease(event_ctx);
    [thisPlugin handleFixtureEvent:event_type forSite:site controller:controller withSN:sn];
    CTLog(CTLOG_LEVEL_INFO,@"finish start events");

    
}

void on_stop_event_notification(void* ctx)
{
    NSLog(@"stop notification : here");
    CTLog(CTLOG_LEVEL_INFO,@"stop notification");
}


-(void)handleFixtureEvent:(int)eventType forSite:(int) site controller:(void*) controller withSN:(const char*) sn
{
    if ( START == eventType)
    {
        if (site == -1 )
        {
            // site == -1 start all slots in the fixture
            @synchronized(_fixtureController)
            {
                int numOfSites = get_site_count(controller);
                
                for (int i=1; i < numOfSites+1; i++)
                {
                    if (is_board_detected(controller, i))
                    {
                        [self sendUnitAppearedNotification:i];
                    }
                }
            }
        }
        else
        {
            @synchronized(_fixtureController)
            {
                if (is_board_detected(controller, site))
                {
                    [self sendUnitAppearedNotification:site];
                }
            }
        }
    }
}

-(void) sendUnitAppearedNotification:(int)site
{
    if (self->_config)
    {
        
        NSDictionary *testers = [self->_config objectForKey:kTESTERS];
        
        if (!testers)
        {
            CTLog(CTLOG_LEVEL_ERR, @"no tester config");
            return;
        }
        
        NSString *identifier = [NSString stringWithFormat:@"Slot-%d",site];
        
        for (NSString *testerName in testers)
        {
            NSDictionary *slotConfig = [testers objectForKey:testerName];
            
            if (slotConfig )
            {
                if  ([slotConfig objectForKey:identifier])
                {

                    NSDictionary * slotMap = [[slotConfig objectForKey:identifier] objectForKey:@"SlotMap"];
                    
                    if (slotMap)
                    {
                        NSString *urlPath = [NSString stringWithFormat:@"uart://%@", [slotMap objectForKey:@"DUTUART"]];
                        
                        NSString *USB = [self getUSBStringFromConfig:slotMap];
                        
                        NSArray *ctUnitTransportArray = @[[CTUnitTransport unitTransportFromFFCommunication:
                                                            [FFStringDevice stringDeviceWithURL:[NSURL URLWithString:urlPath] config:nil]],
                                                           [CTUnitTransport unitTransportFromFFCommunication:
                                                            [FFFactoryServicesDut factoryServicesWithLocationId:USB config:nil]]];
                        
                        NSUUID *uuid = [NSUUID UUID];
                        CTUnit *unit = [[CTUnit alloc] initWithIdentifier:identifier
                                                            configuration:[[slotConfig objectForKey:identifier] objectForKey:@"Config" ]
                                                                     uuid:uuid
                                                              environment:CTUnitEnvironment_unknown
                                                           unitTransports:ctUnitTransportArray
                                                      componentTransports:nil
                                                                 userInfo:nil];
                        [self.pluginContext unitAppeared:unit];

                    }
                    
                    break;
                }
            }
        }

    }
    else
    {
        NSString *identifier = [NSString stringWithFormat:@"Slot-%d",site];
        NSUUID *uuid = [NSUUID UUID];
        CTUnit *unit = [[CTUnit alloc] initWithIdentifier:identifier
                                            configuration:@"A"
                                                     uuid:uuid
                                              environment:CTUnitEnvironment_unknown
                                           unitTransports:nil
                                      componentTransports:nil
                                                 userInfo:@{@"HenhouseSlotID" : @(site)}];
        [self.pluginContext unitAppeared:unit];
    }
}

- (NSString*) getUSBStringFromConfig:(NSDictionary*) configDict
{
    id usbLocation = [configDict objectForKey:@"USB"];
    
    NSString * retUSBString = nil;
    
    if(!usbLocation)
    {
        CTLog(CTLOG_LEVEL_INFO,@"USB definition is not found in config");
    }
    else if ([usbLocation isKindOfClass:[NSString class]])
    {
        retUSBString = [usbLocation lowercaseString];
    }
    else if ([usbLocation isKindOfClass:[NSDictionary class]])
    {
        //find out current system model
        NSString * model = [self getHostModel];
        
        if (model)
        {
            if ([usbLocation objectForKey:model])
            {
                retUSBString = [[usbLocation objectForKey:model] lowercaseString];
            } else
            {
                
                CTLog(CTLOG_LEVEL_INFO,@"can not find USB config for host model: %@, can not config UUT USB location", model);
            }
        }
        else
        {
            CTLog(CTLOG_LEVEL_INFO,@"can not find host model info, can not config UUT USB location");
        }
    }
    
    return retUSBString;
}

- (NSString *) getHostModel
{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
    NSString *modelString;
    
    if (platformExpert) {
        
        NSData * model = (__bridge_transfer NSData *)IORegistryEntryCreateCFProperty(platformExpert,
                                                                                     CFSTR("model"),
                                                                                     kCFAllocatorDefault, 0);
        modelString = [NSString stringWithUTF8String:[model bytes]];
        
        IOObjectRelease(platformExpert);
    }
    
    NSLog(@"getHostModel %@",modelString);
    
    return modelString;
}

-(void)cleanUp
{
    NSArray * fixtureIds = [self getConnectedFixtureIds];
    
    @synchronized(_fixtureController)
    {
        for (NSString * fixturId in fixtureIds)
        {
            NSLog(@"release fixture %@",fixturId);
            void * fixtureController = (void*) _fixtureControllerArray[[fixturId intValue]];
            release_fixture_controller(fixtureController);
        }
    }
    _connectedFixtures = nil;
    _fixtureController = nil;
    _config = nil;
    free (_fixtureControllerArray);
    _vendor = nil;
}

@end
