//
//  RPCClientReceiver.h
//  mix_rpc_client
//
//  Created by Shark Liu on 23/08/2018.
//  Copyright © 2018 HWTE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RPCProtocol.h"
#import "RPCTransport.h"

static NSString* const DONE = @"done";
static NSString* const RUNNING = @"running";
static NSString* const TIMEOUT = @"timeout";
static NSUInteger const DEFAULT_MSG_TRANSMIT_TIME = 100;

/*
 * class to store information for each rpc
 * including status, result, start time, timeout, endtime, callback and jsonArgs.
 * will be item in results and running.
 */
@interface RPCRecord: NSObject
@property (retain) NSString* status;
@property (retain) id result;
@property (assign) NSTimeInterval startTime;
@property (assign) NSTimeInterval timeoutInSec;
@property (assign) NSTimeInterval finishTime;

@end


@interface RPCClientReceiver: NSThread
@property (retain) NSMutableDictionary* results;
@property (retain) NSMutableDictionary* running;
@property (assign) BOOL alive;
@property (assign) id <RPCTransport> transport;
@property (assign) id <RPCProtocol> protocol;
@property (retain) NSOperationQueue* queue;

+ (RPCClientReceiver *)initWithTransport:(id <RPCTransport>)transport withProtocol:(id <RPCProtocol>)protocol;
- (void)stop;
@end
