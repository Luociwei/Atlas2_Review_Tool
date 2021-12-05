//
//  mix_rpc_client_framework.h
//  mix_rpc_client_framework
//
//  Created by Shark Liu on 15/08/2018.
//  Copyright © 2018 HWTE. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mix_rpc_client_framework/mix_rpc_client.h"

//! Project version number for mix_rpc_client_framework.
FOUNDATION_EXPORT double mix_rpc_client_frameworkVersionNumber;

//! Project version string for mix_rpc_client_framework.
FOUNDATION_EXPORT const unsigned char mix_rpc_client_frameworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <mix_rpc_client_framework/PublicHeader.h>

/*
 * interface provided:
 * -----------------------------------------------------------------------------------
 * @interface RPCClientWrapper : NSObject
 * @property (retain) NSString* endpoint;
 * @property (retain) id <RPCTransport> transport;
 * @property (retain) id <RPCProtocol> protocol;
 * @property (retain) NSMutableDictionary* proxys;
 * @property (retain) RPCClientReceiver* receiver;

 * + (RPCClientWrapper *) initWithEndpoint: (NSString *)endpoint;
 * - (id)rpc:(NSString *)method args:(id)args kwargs:(NSDictionary *)kwargs;
 * - (id)rpc:(NSString *)method args:(id)args;
 * - (id)rpc:(NSString *)method kwargs:(id)kwargs;
 * - (id)rpc:(NSString *)method;
 * - (NSString *)isServerReady;
 * - (NSString *)getServerMode;
 * - (NSString *)isServerUpToDate;
 * - (id)getResult:(id)uuid;
 * - (void)waitForUUID:(id)uuid;
 * - (NSString *)sendFile:(NSString *)srcFile intoFolder:(NSString *)dstFolder withTimeoutInMS:(NSUInteger)timeout;
 * - (NSString *)sendFile:(NSString *)srcFile intoFolder:(NSString *)dstFolder;
 * - (NSData *)getFile:(NSString *)target withTimeoutInMS:(NSUInteger)timeout;
 * - (NSString *)getAndWriteFile:(NSString *)target intoDestFile:(NSString *)destFile withTimeoutInMS:(NSUInteger)timeout;

 * -----------------------------------------------------------------------------------
 * please refer to sample test code in test_framework_arc.m in mix_rpc_client_framework.framework/Resources/ for usage reference.
 */



