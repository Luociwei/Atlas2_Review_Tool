//
//  Client.h
//  MainUI
//
//  Copyright © 2015年 ___sc Automation___. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Requester.hpp"
#include "Subscriber.hpp"

#pragma once

#define JSON_RPC        @"2.0"

#define kFunction        @"method"
#define kParams          @"args"
#define kId              @"id"
#define kJsonrpc         @"jsonrpc"
#define kResult          @"result"
#define kError           @"error"

@interface Client : NSObject{
    @private
    CRequester * pRequester;
    CSubscriber * pSubscriber;
}


-(int)CreateRPC:(NSString *)ipRequest withSubscriber:(NSString *)ipSubscriber;
-(int)SendCmd:(NSString *)cmd;
-(NSString *)RecvRquest;
-(NSString *)RecvRquest:(NSInteger)size;
-(void)setTimeout:(int)timeout;

-(void)OnSubscriberData:(NSString *)msg;
-(void)SetFilter:(NSString *)filter;

@end
