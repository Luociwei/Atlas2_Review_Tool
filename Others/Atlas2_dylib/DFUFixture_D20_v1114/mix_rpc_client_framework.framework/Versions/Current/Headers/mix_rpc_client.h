//
//  mix_rpc_client.h
//  mix_rpc_client
//
//  Created by Shark Liu on 03/08/2018.
//  Copyright © 2018 HWTE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RPCProtocol.h"
#import "RPCTransport.h"
#import "RPCClientReceiver.h"

/*
 * RPC Exception class to report problem like timeout.
 */
 @interface RPCClientException: NSException
 + (RPCClientException *)initWithMsg:(NSString *)msg;
 @end


/*
 * rpc proxy to support
 *      driver = [client getProxy:@"driver:];
 *      [driver fun];
 * function as
 *      [client driver_fun];
 */
@interface RPCProxy : NSObject
@property (retain) NSString* prefix;
@property (assign) id client;

+ (RPCProxy *)initWithPrefix:(NSString *)prefix withClient:(id)client;
@end

/*
 * Main RPC Client wrapper class;
 * instancelize to send rpc command.
 */
@interface RPCClientWrapper : NSObject

@property (retain) id <RPCTransport> transport;
@property (retain) id <RPCProtocol> protocol;
@property (retain) NSMutableDictionary* proxys;
@property (retain) RPCClientReceiver* receiver;
@property (retain) NSString* version;
@property (retain) NSString* minAllowedServerVersion;
/* retries: client has global default retry number; retries==0 means no retry.
 *          each rpc call could override global retry number by adding "rpc_retry"
 *          keyword in kwargs.
 *          here is global retry number of the client.
 *          Not enabled yet.
 */
@property (assign) NSUInteger retries;

/*
 * endpoint should be a dictionary with 2 keys which match server's 2 endpoint:
 *     ENDPOINT = @{@"requester":@"tcp://127.0.0.1:5556", @"receiver":@"tcp://127.0.0.1:15556"};
 * correponding server endpoint:
 *     endpoint_server = {'receiver': 'tcp://127.0.0.1:7777', 'replier': 'tcp://127.0.0.1:17777'}
 *
 */
+ (id)initWithEndpoint: (NSDictionary*)endpoint;
// retry not implemented yet; use the one without retries above for the moment.
+ (id)initWithEndpoint: (NSDictionary*)endpoint withRetries:(NSUInteger)retries;

/*
 * Check server mode and server version using the 2 API below;
 * return "PASS" if server is valid: network accessible, in "normal" mode and version matches.
 * return error msg in NSString for any checking fail; please print/log the response when handling.
 */
- (NSString *)isServerReady;

/*
 * getServerMode: return "normal" when xavier is ready for testing.
 * Other possible status includes "dfu" which means xavier is in firmware update
 * and should not be regarded as valid status for testing.
 */
- (NSString *)getServerMode;

/*
 * check if client and server version match.
 * return "PASS" when client and server version match;
 * return error msg in NSString for failed version check;
 * please print/log the response when handling.
 */
- (NSString *)isServerUpToDate;

/*
 * RPC api: return whatever returned from RPC server; data type is preserved
 * For example, if server returns an python int, return value here will be NSNumber;
 * if server returns an python string, return value here will be NSString.
 */
- (id)rpc:(NSString *)method args:(NSArray *)args kwargs:(NSDictionary *)kwargs;
- (id)rpc:(NSString *)method kwargs:(NSDictionary *)kwargs;
- (id)rpc:(NSString *)method args:(NSArray *)args;
- (id)rpc:(NSString *)method;
- (id)rpcWithJSONArgs:(NSString *)json_args;
- (id)rpcWithDictionaryArgs:(NSDictionary *)dict_args;

/*
 * get either actual rpc result or error code if there is rpc error.
 * For async RPC.
 */
- (id)getResult:(id)uuid;

/*
 * wait for certain task with given uuid until its status is not RUNNING;
 * could be either TIMEOUT or DONE.
 * Do not return anything.
 * For async RPC.
 */
- (void)waitForUUID:(id)uuid;

/*
 * send file to xavier; encode file content with base64 as jsonrpc does not support binary data.
 * Send file specified by srcFile to xavier through RPC, as intoFolder/filename.
 * filename is the file name without path info of srcFile.
 * dst_folder should be valid folder in xavier file system;
 * server has an allowed list of dst folder; this folder should be in the list or be rejected.
 * this function will read file content from srcFile, encode it with base64encode,
 * and send to server using server_send_file api.
 * server will decode and write to dst_folder/dst_fn after validating the dst folder and fn.
 * return string 'PASS' or error exception
 */
- (NSString *)sendFile:(NSString *)srcFile intoFolder:(NSString *)dstFolder withTimeoutInMS:(NSUInteger)timeout;
// default timeout.
- (NSString *)sendFile:(NSString *)srcFile intoFolder:(NSString *)dstFolder;

/*
 * Get file/folder from xavier; folder will be packed into tgz file before uploading.
 * Server has an allowed list of white list folder for getting files from;
 * Only file/folders directly located in whitelist folder is allowed; currently rpc log folder and ~ is supported.
 * Requesting files in other folders is considered illegal and will be rejected.
 * Specially, use "log" as target will get the whole rpc "log" folder, which contains log file of all RPC server.
 *    No log is removed in this scenario.
 * Specially, use "#log" as target will get all rpc server log of the current rpc server.
 *    note that after "#log", the log file got will be removed on server side.
 *    This is the designed way for client to retrive server log.
 */
- (NSData *)getFile:(NSString *)target withTimeoutInMS:(NSUInteger)timeout;
// calls getFile above and write to file on client side.
- (NSString *)getAndWriteFile:(NSString *)target intoDestFile:(NSString *)destFile withTimeoutInMS:(NSUInteger)timeout;

/*
 * Get an rpc proxy for certain instance.
 * for example if server has an instance registered as "driver" and has a fun() RPC service,
 * we can either call it by
 *      id ret = [client rpc:@"driver_fun"];
 * or using proxy:
 *      RPCProxy* driver = [client getProxy:@"driver"];
 *      id ret = [driver fun];
 * ONLY for non-ARC user software; please refer to test_framework.m for sample code.
 */
- (RPCProxy *)getProxy:(NSString *)prefix;

@end
