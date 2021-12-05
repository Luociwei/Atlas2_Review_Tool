# MIX_RPC_Client
This repo is Objective-C RPC Client to communicate with MIX RPC Server (in repo tinyrpcx);
The taget is to implement below feature:
1. work as a objective-c framework
2. Support the same functionality as Python RPC Client in tinyrpcx including

    i) synchronous rpc (blocking)
    ii) asynchronous rpc (non-blocking)
    iii) query rpc result
    iv) wait for rpc response

## install
Just install the release package with name mix_rpc_client_framework.pkg from rdar://problem/43830636

## steps to use MIX RPC Client Framework in Xcode project

1. Install from release pkg by double click .pkg install file.
    The package installer will cover the following manual items.
    Or manually:
        i) copy mix_rpc_client_framework.framework into /AppleInternal/Library/Frameworks/
        ii) Make sure there is valid libzmq.5.dylib in /usr/local/lib/
            If zmq is not installed (like GH station), copy mix_rpc_client_framework.framework/Resources/libzmq.5.dylib to /usr/local/lib/
            This is necessary or we will get error message saying bundle is damaged due to cannot find this dylib.
            The libzmq.5.dylib is built on MacOS 10.12 and has been verified to work with MacOS 10.13 and 10.14.
2.  For Mac App using sandbox, make sure the App has access to network:
        Make sure "outgoing network" access is granted in project setting App capability tab;
3. Open project setting, choose your target and add "/AppleInternal/Library/Frameworks" into "Framework search paths"
4. Use the following import statement in the header file when rpc client is to be used:
```
    #import <mix_rpc_client_framework/mix_rpc_client_framework.h>
```
5. Create client instance when necessary:
```
    RPCClientWrapper *client = [RPCClientWrapper initWithEndpoint:@"127.0.0.1:5556"];
```
6. use the following code to send rpc:
```
    id ret = [client rpc:@"util_measure" args:@[@1] kwargs:@{@"timeout_ms":20000}];
    // ret will be NSNumber 1
```
8. start tinyrpcx server following steps below
9. Check ret; being 1 means rpc communcation works.

### Thread-safe
RPC Client instance is NOT thread-safe.
Make sure one RPC Client instance is only used in 1 thread.
You can create multiple clients and use dedicated instance in each thread.

The reason is the client used a NSMutableDictionary to host RPC results and NSMutableDictionary is not thread-safe.
When using 1 client instance in 2 threads, unexpected behavior will happened when the 2 threads are trying to make RPC request at the same time; issues could be "Status being NIL for RPC sent" or unexpected exception.

### how it work
Basically RPC is to execute a function on server side, and server return the execution result back to client.
Translation of the example above:
```
    id ret = [client rpc:@"util_measure" args:@[@1] kwargs:@{@"timeout_ms":20000}];
    // This is calling util_measure(1, timeout_ms=20000) on python RPC server.
```

util_measure() is defined in start_python_rpc_server.py. Implementation:
```python
class utility(object):

    @public
    def measure(self, value):
        print 'measure: ', value
        return value

    ...
if __name__ == '__main__':
    ...
    util = utility()
    server.register_instance({'driver': driver, 'util': util})
```
* it is defined in class ```"utility"```
* it has a decorator @public
    function with @public will be recognied by RPC server as a RPC service;
    Other function inside utilty class without @public will not be accessible via RPC.
* The class is instantialized into a ```"util"``` object
* the "util" instance is registered into RPC server as name "util"
    With registration, RPC will try to match all rpc request starting with "util_" to the object "util"
So util_measure() here is translated into util.measure().

## rpc() api

As shown in the example above, an RPC could be issued using the code below:
```
    id ret = [client rpc:@"method" args:@[@1, @2] kwargs:@{@"timeout_ms":20000}];
```
type of ret will be determined by the actual data returned from tinyrpcx server;
        Basically any type could be possible:
            int, float, double --> NSNumber
            string --> NSString
            list --> NSArray
            dict --> NSDictionary
            None --> nil
    The following interfaces are supported as variant of the typical one above:
```
    [client rpc:@"method"];
    [client rpc:@"method" args:@[@1, @2]];
    [client rpc:@"method" kwargs:@{@"timeout_ms":20000}];
```
    method should be NSString; cannot be nil;
    args should be NSArray, could be nil or [];
    kwargs should be NSDictionary, could be nil or {};

## other client api:

### getResult/waitForUUID
These 2 apis are used to handle asynchronous RPC.
Async RPC does not wait and return the RPC execution result;
instead it will return immediately a UUID (NSString) for the result.
So the main thread has an chance to run something else in parallel while the previous RPC is still running in server.
The UUID will be used with getResult and waitforUUID api:
```
/*
 * get either actual rpc result or error code if there is rpc error.
 * mainly for async RPC.
 */
- (id)getResult:(id)uuid;

/*
 * wait for certain task with given uuid until its status is not RUNNING;
 * could be either TIMEOUT or DONE.
 * Do not return anything.
 * mainly for async RPC.
 */
- (void)waitForUUID:(id)uuid;
```

For the following code:
```
    id uuid = [client rpc:@"util_measure" args:@[@1] kwargs:@{@"timeout_ms":@20000, @"asynchronize":@YES}];
    // could do something else here
    [client waitForUUID:uuid];
    id ret = [client getResult:uuid];
```
The rpc call will return immediately while the actual rpc service is still running at server side;
the code will block at "watiForUUID" line until the waited rpc result returned from server, or client timeout.
ret will be 1 which is return value of the rpc service.

### sendFile/getFile

```
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
```
Example:
```
    // sending test.log at client side to rpc server's HOME folder.
    id ret = [client sendFile:@"test.log" intoFolder:@"~"];

    // get file content of rpc server's ~/test.log.
    NSData* data = [client getFile:@"~/test.log" withTimeoutInMS:120 * 1000];
    // collect current rpc server's log files, pack into tarball, get its content to client,
    // and write to client's /tmp/rpc_server_log.tgz
    // the log files are removed from server after transfer.
    NSString* ret = [client getAndWriteFile:@"#log" intoDestFile:@"/tmp/rpc_server_log.tgz" withTimeoutInMS:120 * 1000];
```

## Run mix_rpc_client_framework unit test:
1. start tinyrpcx server following steps below;
    Ensure the ip address and port number match in unit test code and rpc server;
    By default "127.0.0.1:5556" is used.
1. open mix_rpc_client project in xcode
2. Switch target to "mix_rpc_client_framework"
3. CMD+U to run the test for non-ARC and ARC;
   Or in command line, use the following commands to run tests:
```
    xcodebuild -scheme test_framework test
    xcodebuild -scheme test_framework_arc test
```

## running tinyrpcx RPC server for testing
1. Get matching tinyrpcx. unzip if necessary.
    Usually tinyrpcx is included in mix_rpc_client_framework release package in rdar://problem/43830636
    Please only use the included one; there are version locks between client and server and only the pair in release package is verified.
2.  install zmq and pyzmq which is zmq python binding;
		https://github.com/zeromq/pyzmq
    tinyrpcx relies on zmq as transport protocol on top of TCP.
3. copy "start_python_rpc_server.py" to root folder of tinyrpcx (same level with rpc_server.py)
4. open terminal, "cd" into tinyrpcx root folder, and run "python start_python_rpc_server.py"
Notes: this will start an RPC server at 127.0.0.1:5556 port; if you are not using this port please change either client or server to make sure they align.
RPC service provided are mainly in start_python_rpc_server.py; those function with @public decorator are exposed via RPC.

## how to create your own rpc service in start_python_rpc_server.py
1. write your code in a function
2. Give it @public decorator
3. Put the function in a class
4. Create a instance ("obj" in  from the class
5. register into rpc server with a meaningful name
```
    class SomeClass(object):
        @public
        def fun(self):
            return 'something'

    obj = SomeClass()
    server.register_instance({'name': obj})
```
6. call it via rpc:
```
    id ret = [client rpc:@"name_fun" args:@[] kwargs:@{@"timeout_ms":20000}];
    // ret should be NSString "something".
```



## Full reference code
Refer to mix_rpc_client_framework.framework/Resources/test_framework_arc.m for examples.

