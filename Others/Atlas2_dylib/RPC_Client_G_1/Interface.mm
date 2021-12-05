//
//  Interface.mm
//  RPC_Client
//
//
#import <Foundation/Foundation.h>
#include "Interface.h"
#include "tolua++.h"

TOLUA_API int tolua_RPC_Client_G_1_open (lua_State* tolua_S);

extern "C" int luaopen_libRPC_Client_G_1(lua_State * state)
{
    NSLog(@"Load RPC Client G-1 Dylib 20200413\r\n");
    tolua_RPC_Client_G_1_open(state);
    return 0;
}
