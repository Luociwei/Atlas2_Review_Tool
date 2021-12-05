//
//  Interface.h
//  RPC_Client
//

//

#ifndef Interface_hpp
#define Interface_hpp

#include "lua.hpp"


#define DL_EXPORT __attribute__((visibility("default")))

#include <stdio.h>

extern "C" int luaopen_libRPC_Client_G_1(lua_State * state);


#endif /* Interface_hpp */
