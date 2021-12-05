# mix_rpc_client release history

version 1.1.2:

    * add lock for uuid handling code.
    * sleep 5ms in waiting resul.
    * remove lock for uuid code, will dig more for the thread safe issue
    * Update README for client being non-thread-safe

version 1.1.1:

    * Change RPC timeout error message to begin with [RPCError] so it could be correctly captured by plugin calling it.
    * fix an logic error when logging for receiving an TIMEOUTed RPC response.

version 1.1.0:

    * distinguish milliseconds in timeout by adding MS/ms to varname.
    * requiring server 1.1.0 and above to work.

version 1.0.12:

    * remove sendFile api() with default destination folder since it is not supported by server any more.
    * Code clean up: remove commented code.
    * add more api to mix_rpc_client_framework.h for reference.
    * remove unused test_drivers/ from repo
    * move default file transfer time to a const instead of hard-code in function; change default time to 180 for both send and get file.
    * add test case in testJSONDataType for large int and large float

version 1.0.11:

    * add getFile() client api to get file from server to client.
        Mainly for getting xavier log.
    * update api: send_file() --> sendFile

version 1.0.10:

    * add send_file() client api to send file to server from client.
        Mainly for xavier firmware update.

version 1.0.9:

    * getServerMode() api is available to get server mode;
        Server mode is added in server 1.0.4; "normal" for normal testing status, "dfu" for non-testing status.
    * hello() server RPC service is removed and not called anymore.
    * isServerUpToDate() api is available to check server and client version matching.
        Calling server_rpc_version() server RPC service (previously server_is_ready() api).
        server_rpc_version() is availble in RPC server 1.0.4.
    * isServerReady: call server_hello() and server_is_ready();
        Always return NSString:
            "PASS" if server is network accessible, mode is "normal" and server client version match.
            error msg if any checking fail.
        This is the API that user could call after client init to check server status and version.
    * initWithEndpoint: do not check server status anymore, and will return an RPCClientWrapper instance.
        User software could run isServerReady() api if want to check server status.
    * Requiring RPC Server 1.0.4 or above.

version 1.0.8:

    * remove isReady() api;
    * change isServerReady() api to perform cross version check between server and client.
        cient and server now perform minimum allowed version check;
        If version does not meet minimum allowed version requirement, isServerReady() will return false.
        Maching TinyrpcX version is 1.0.1.

version 1.0.7:

    * isReady() api replaced by isServerReady() to be more accurate.
        isReady() is still working but will be removed in a future release.

version 1.0.6:

    * Increase dependency libzmq dylib file into Resouces folder;
        Need to be copied into /usr/local/lib/ for hosts that does not have zmq installed, like GH station

version 1.0.5:

    * client provide -(BOOL)isReady api to check server network connection.
    * client initialization includes network connection checking; if server is not reachable, an error message (NSString) will be returned instead of client instance.
    * fix receiver thread crash issue encounter by FCN

version 1.0.4:

    * Now the Framework support both MacOS 10.12 and 10.13.

version 1.0.3:

    * support asynchronous RPC.
            Adding "asynchronize":@YES as keyword arguments in any RPC request will make that RPC an async one.
            Async RPC will return immediately after the request is sent to server; it will not wait for server response.
            The return value will be the UUID (as NSString) of the rpc call, which could be used to query rpc request afterwards;
            The following API are provided by client for async RPC:
                - (void) waitForUUID(id)
                    wait until the given uuid(s) rpc has a non-running results; could be DONE or TIMEOUT.
                - (id) getResult(id)
                    get current result of the RPC; could be nil if RPC response has not arrived from server;
                    or actual ret returned from server if there is.
    * RPC timeout could be specified in rpc kwargs by "timeout" key now.

version 1.0.2:

    * handle client side timeout.
        Client has an default 3s timeout for RPC request;
        "timeout" keyword in rpc kwargs could override default timeout.
    * client will not crash now when read and write happened to the same socket at the same time.

version 1.0.1:

    * [internal] put RPC response receiving into a separate RPCReceiver thread; no behavior impact;
    * support multiple client in the same namespace sending request to the same server

version 1.0.0:

    * support synchronous RPC call; async call is coming soooooon.
    * with ARC enabled, support various rpc call:
        -rpc:method;
        -rpc:method args:args;
        -rpc:method args:args kwargs:kwargs;
        -rpcWithDictionaryArgs:dictArgs;
    * with ARC disabled, support RPC proxy call;
        [client rpc:@"driver_fun" args:args] is available throught the following code which is in native Objective-C function call:
        PRCProxy* driver = [client getProxy:@"driver"];
        [driver func:arg]
