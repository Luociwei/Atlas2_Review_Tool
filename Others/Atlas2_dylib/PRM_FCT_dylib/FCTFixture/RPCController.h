//
//  RPCController.h
//  FCTFixture
//
//  Created by Kim on 2021/8/16.
//  Copyright © 2021 PRM-JinHui.Huang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mix_rpc_client_framework/mix_rpc_client_framework.h>

NS_ASSUME_NONNULL_BEGIN

@interface RPCController : NSObject
{
    int status;
}
@property (atomic,retain) NSMutableArray *rpcClients;
@property (atomic, retain) NSMutableArray *logPaths;
@property (atomic) NSMutableArray *rpcSendRecvLogs;

-(BOOL)isFloat: (NSString *)string;
-(BOOL)isInt: (NSString *)string;
-(BOOL)isHex: (NSString *)string;
-(int)close;
-(void)uartShutdown:(int)site;
-(void)hwlog: (NSString *) message andSite:(int)site;
- (BOOL)createRPCClient:(NSString *)inIP andPort:(NSUInteger)inPort andLogPath:(NSString *)inLogPath;
-(id)rpcCall:(NSString *)command atSite:(int)inSite timeOut:(int)inTimeoutms;
-(NSString *)getAndWriteFile:(NSString*)target dest:(NSString*) dest atSite:(int)site timeout:(int) timeout;
@end

NS_ASSUME_NONNULL_END
