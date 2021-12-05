//
//  RPCTransport.h
//  mix_rpc_client
//
//  Created by Shark Liu on 14/08/2018.
//  Copyright © 2018 HWTE. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RPCTransport <NSObject>
@property (assign) BOOL isLogging;
+ (id)createWithZMQContext:(id)ctx withEndpoint:(NSDictionary *)endpoint;
- (void)sendMessage:(NSString *)message;
- (void)sendData:(NSData *)data;
- (NSString *)recvMessage;
- (NSData *)recvData;
- (NSData *)recvDataNonBlocking;
- (void)shutdown;
- (NSUInteger)defaultTimeoutMS;

@end
