//
//  MTFixtureDetector.m
//
//
//  Created by Jayson on 2020/8/31.
//  Copyright © 2020 Jayson. All rights reserved.
//

#import <AtlasLogging/AtlasLogging.h>
#import "FixtureDetector.h"

@implementation FixtureDetector

@synthesize client;
@synthesize transportURL;
@synthesize pollingInterval;
@synthesize site;

-(instancetype)initWithClient:(ATKLuaPlugin *)client transportURL:(NSString *)url pollingRestPeriod:(NSNumber *)pollingRestPeriod {
    self = [super init];
    if (self) {
        site = [[NSNumber alloc] initWithInt:[url substringFromIndex:url.length-1].intValue];
        [self setPollingInterval:pollingRestPeriod];
        [self setClient:client];
        [self setTransportURL:[NSURL URLWithString:url]];
    }
    
    return self;
}

#pragma mark - interface protocols
- (NSTimeInterval)pollingRestPeriod {
    return [self.pollingInterval intValue];
}

- (NSURL *)checkPresence {

    NSError *error;

    ATKLog("[%@] is checkPresence --- 1!", self.transportURL);
    
    if ([self.client performBOOL:@"is_board_detect" args:@[site] error:&error]) {
        ATKLog("[%@] detected successfully!", self.transportURL);
        return [self transportURL];
    } else {
        ATKLog("[%@] detected failure! error: %@!\n", self.transportURL, error.localizedFailureReason);
    }
    
    return nil;
}

- (BOOL)start:(NSError *__autoreleasing *)error {
    ATKLog("[%@] Start detection", [self transportURL]);
    return YES;
}

- (void)stop {
    ATKLog("[%@] Stop detection", [self transportURL]);
}

#pragma mark - Public methods

@end
