/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import <XCTest/XCTest.h>
#import <CoreTestFoundation/CoreTestFoundation.h>
#import "CommonFixturePlugin.h"


@interface CommonFixturePluginCTTestContextDelegate : NSObject <CTContextDelegateProtocol>

@end

@implementation CommonFixturePluginCTTestContextDelegate

- (void)updateProgressValue:(double)value
                    maximum:(double)maximum
                   interval:(NSUInteger)interval
                   userInfo:(NSDictionary *)userInfo
                    context:(CTContext *)context
{
    NSLog(@"value = %f, max = %f, interval = %ld, userInfo = %@", value, maximum, interval, userInfo);
}

- (void)dispatchEvent:(CTEvent *)event context:(CTContext *)context
{
}

- (void)registerForEvent:(NSString *)eventName selector:(SEL)selector context:(CTContext *)context
{
}

- (void)unregisterFromEvent:(NSString *)eventName context:(CTContext *)context
{
}

- (void)logWithLevel:(CTLogLevel)level message:(NSString *)message context:(CTContext *)context
{
    NSLog(@"%@", message);
}

- (void)registerForEvent:(NSString *)eventName context:(CTContext *)context callback:(void(^)(CTEvent * event))callback
{
    
}

- (NSString *)getContextLogFilePath
{
    NSFileManager *dMan = [NSFileManager defaultManager];
    NSError *err = nil;
    NSString *dir = @"/tmp/CommonFixturePlugin";
    [dMan createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&err];
    return [NSString stringWithFormat:@"%@/CommonFixturePlugin.log",dir];
}

@end


@interface CommonFixturePluginTest : XCTestCase

@end

@implementation CommonFixturePluginTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (CTTestContext *)getCTTestContextForCommand:(NSString *)command
{
    NSString *urlPath = @"DummyDevice";
    NSDictionary *userInfo = @{};
    CTUnitTransport *transport = [[CTUnitTransport alloc] initWithURL:[NSURL URLWithString:urlPath] metadata:userInfo];
    CTLog(CTLOG_LEVEL_INFO, @"URL: %@", transport.url);
    NSArray *ctUnitTransportArray = @[transport];
    
    CTUnit *unit = [[CTUnit alloc] initWithIdentifier:@"CommonFixturePlugin"
                                        configuration:nil
                                                 uuid:[NSUUID new]
                                          environment:CTUnitEnvironment_unknown
                                       unitTransports:ctUnitTransportArray
                                  componentTransports:nil
                                             userInfo:@{}];
    NSUUID *uuid = [NSUUID new];
    CommonFixturePluginCTTestContextDelegate *testDelegate = [CommonFixturePluginCTTestContextDelegate new];
    NSDictionary *parameters = @{};
    
    NSURL *directory = [NSURL URLWithString:@"/tmp/CommonFixturePlugin"];
    unit.workingDirectory = directory;
    CTTestContext *myContext = [[CTTestContext alloc] initForPlugin:@"CommonFixturePlugin" command:command unit:unit delegate:testDelegate parameters:parameters limits:nil uuid:uuid directory:directory log:nil];
    return myContext;
}


- (void)testVersion
{
    // add code here to test version api from CTPluginProtocol
}

- (void)testSetup
{
    // add code here to test setup api from CTPluginProtocol
    XCTAssertTrue(false, @"Plugin setup test failed");
}

- (void)testTearDown
{
    // add code here to test tear down api from CTPluginProtocol
    XCTAssertTrue(false, @"Plugin teardown test failed");
}

- (void)testCommandDescriptors
{
    // add code to test getting command descriptors
    XCTAssertTrue(false, @"Plugin commandDescriptors test failed");
}

- (void)testHelloCommonFixturePlugin
{
    CommonFixturePlugin *CommonFixturePluginPlugin = [CommonFixturePlugin new];
    CTTestContext *myContext = [self getCTTestContextForCommand:@"helloCommonFixturePlugin"];
    [CommonFixturePluginPlugin helloCommonFixturePlugin:myContext];
    CTRecordStatus status = myContext.records.overallRecordStatus;
    XCTAssertEqual(status, CTRecordStatusPass, @"Pass");
    
}


@end
