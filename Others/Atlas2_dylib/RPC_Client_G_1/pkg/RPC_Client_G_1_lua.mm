/*
** Lua binding: RPC_Client_G_1
** Generated automatically by tolua++-1.0.92 on Tue Feb 20 08:32:07 2018.
*/

#ifndef __cplusplus
#include "stdlib.h"
#endif
#include "string.h"

#include "tolua++.h"

/* Exported function */
TOLUA_API int  tolua_RPC_Client_G_1_open (lua_State* tolua_S);

#include "RPC_Client_G_1.h"

/* function to release collected object via destructor */
#ifdef __cplusplus

static int tolua_collect_RPC_Client_G_1 (lua_State* tolua_S)
{
 RPC_Client_G_1* self = (RPC_Client_G_1*) tolua_tousertype(tolua_S,1,0);
	Mtolua_delete(self);
	return 0;
}
#endif


/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"RPC_Client_G_1");
}

/* method: new of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_new00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_new00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   RPC_Client_G_1* tolua_ret = (RPC_Client_G_1*)  Mtolua_new((RPC_Client_G_1)());
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"RPC_Client_G_1");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'new'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: new_local of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_new00_local
static int tolua_RPC_Client_G_1_RPC_Client_G_1_new00_local(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   RPC_Client_G_1* tolua_ret = (RPC_Client_G_1*)  Mtolua_new((RPC_Client_G_1)());
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"RPC_Client_G_1");
    tolua_register_gc(tolua_S,lua_gettop(tolua_S));
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'new'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: new of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_new01
static int tolua_RPC_Client_G_1_RPC_Client_G_1_new01(lua_State* tolua_S)
{
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
 {
  const char* filePath = ((const char*)  tolua_tostring(tolua_S,2,0));
  {
   RPC_Client_G_1* tolua_ret = (RPC_Client_G_1*)  Mtolua_new((RPC_Client_G_1)(filePath));
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"RPC_Client_G_1");
  }
 }
 return 1;
tolua_lerror:
 return tolua_RPC_Client_G_1_RPC_Client_G_1_new00(tolua_S);
}
#endif //#ifndef TOLUA_DISABLE

/* method: new_local of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_new01_local
static int tolua_RPC_Client_G_1_RPC_Client_G_1_new01_local(lua_State* tolua_S)
{
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
 {
  const char* filePath = ((const char*)  tolua_tostring(tolua_S,2,0));
  {
   RPC_Client_G_1* tolua_ret = (RPC_Client_G_1*)  Mtolua_new((RPC_Client_G_1)(filePath));
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"RPC_Client_G_1");
    tolua_register_gc(tolua_S,lua_gettop(tolua_S));
  }
 }
 return 1;
tolua_lerror:
 return tolua_RPC_Client_G_1_RPC_Client_G_1_new00_local(tolua_S);
}
#endif //#ifndef TOLUA_DISABLE

/* method: delete of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_delete00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_delete00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'delete'", NULL);
#endif
  Mtolua_delete(self);
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'delete'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: CreateIPC of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_CreateIPC00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_CreateIPC00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* reply = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* publish = ((const char*)  tolua_tostring(tolua_S,3,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'CreateIPC'", NULL);
#endif
  {
   int tolua_ret = (int)  self->CreateIPC(reply,publish);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'CreateIPC'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: CreateRepPubPort of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_CreateRepPubPort00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_CreateRepPubPort00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,5,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* rep = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* pub = ((const char*)  tolua_tostring(tolua_S,3,0));
  int channel = ((int)  tolua_tonumber(tolua_S,4,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'CreateRepPubPort'", NULL);
#endif
  {
   int tolua_ret = (int)  self->CreateRepPubPort(rep,pub,channel);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'CreateRepPubPort'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: initWithEndpoint of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_initWithEndpoint00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_initWithEndpoint00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* requester = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* receiver = ((const char*)  tolua_tostring(tolua_S,3,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'initWithEndpoint'", NULL);
#endif
  {
   int tolua_ret = (int)  self->initWithEndpoint(requester,receiver);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'initWithEndpoint'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: initWithEndpoint of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_initWithEndpoint01
static int tolua_RPC_Client_G_1_RPC_Client_G_1_initWithEndpoint01(lua_State* tolua_S)
{
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,5,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,6,&tolua_err)
 )
  goto tolua_lerror;
 else
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* requester = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* receiver = ((const char*)  tolua_tostring(tolua_S,3,0));
  int interval_ms = ((int)  tolua_tonumber(tolua_S,4,0));
  int retries = ((int)  tolua_tonumber(tolua_S,5,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'initWithEndpoint'", NULL);
#endif
  {
   int tolua_ret = (int)  self->initWithEndpoint(requester,receiver,interval_ms,retries);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
tolua_lerror:
 return tolua_RPC_Client_G_1_RPC_Client_G_1_initWithEndpoint00(tolua_S);
}
#endif //#ifndef TOLUA_DISABLE

/* method: isServerReady of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_isServerReady00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_isServerReady00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'isServerReady'", NULL);
#endif
  {
   int tolua_ret = (int)  self->isServerReady();
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'isServerReady'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: getServerMode of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_getServerMode00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_getServerMode00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'getServerMode'", NULL);
#endif
  {
   const char* tolua_ret = (const char*)  self->getServerMode();
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'getServerMode'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: isServerUpToDate of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_isServerUpToDate00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_isServerUpToDate00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'isServerUpToDate'", NULL);
#endif
  {
   const char* tolua_ret = (const char*)  self->isServerUpToDate();
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'isServerUpToDate'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: rpc_client of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_rpc_client00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_rpc_client00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,1,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* command = ((const char*)  tolua_tostring(tolua_S,2,0));
  int timeout = ((int)  tolua_tonumber(tolua_S,3,3000));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'rpc_client'", NULL);
#endif
  {
   const char* tolua_ret = (const char*)  self->rpc_client(command,timeout);
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'rpc_client'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: rpc_client2 of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_rpc_client200
static int tolua_RPC_Client_G_1_RPC_Client_G_1_rpc_client200(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,1,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* command = ((const char*)  tolua_tostring(tolua_S,2,0));
  int timeout = ((int)  tolua_tonumber(tolua_S,3,3000));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'rpc_client2'", NULL);
#endif
  {
   const char* tolua_ret = (const char*)  self->rpc_client2(command,timeout);
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'rpc_client2'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: UnLockSendCmd of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_UnLockSendCmd00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_UnLockSendCmd00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'UnLockSendCmd'", NULL);
#endif
  {
   int tolua_ret = (int)  self->UnLockSendCmd();
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'UnLockSendCmd'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: sendFile of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_sendFile00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_sendFile00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,5,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* srcFile = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* Folder = ((const char*)  tolua_tostring(tolua_S,3,0));
  int timeout = ((int)  tolua_tonumber(tolua_S,4,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'sendFile'", NULL);
#endif
  {
   int tolua_ret = (int)  self->sendFile(srcFile,Folder,timeout);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'sendFile'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: getFile of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_getFile00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_getFile00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* target = ((const char*)  tolua_tostring(tolua_S,2,0));
  int timeout = ((int)  tolua_tonumber(tolua_S,3,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'getFile'", NULL);
#endif
  {
   const char* tolua_ret = (const char*)  self->getFile(target,timeout);
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'getFile'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: getAndWriteFile of class  RPC_Client_G_1 */
#ifndef TOLUA_DISABLE_tolua_RPC_Client_G_1_RPC_Client_G_1_getAndWriteFile00
static int tolua_RPC_Client_G_1_RPC_Client_G_1_getAndWriteFile00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"RPC_Client_G_1",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,5,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  RPC_Client_G_1* self = (RPC_Client_G_1*)  tolua_tousertype(tolua_S,1,0);
  const char* target = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* dest = ((const char*)  tolua_tostring(tolua_S,3,0));
  int timeout = ((int)  tolua_tonumber(tolua_S,4,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'getAndWriteFile'", NULL);
#endif
  {
   int tolua_ret = (int)  self->getAndWriteFile(target,dest,timeout);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'getAndWriteFile'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_RPC_Client_G_1_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
  #ifdef __cplusplus
  tolua_cclass(tolua_S,"RPC_Client_G_1","RPC_Client_G_1","",tolua_collect_RPC_Client_G_1);
  #else
  tolua_cclass(tolua_S,"RPC_Client_G_1","RPC_Client_G_1","",NULL);
  #endif
  tolua_beginmodule(tolua_S,"RPC_Client_G_1");
   tolua_function(tolua_S,"new",tolua_RPC_Client_G_1_RPC_Client_G_1_new00);
   tolua_function(tolua_S,"new_local",tolua_RPC_Client_G_1_RPC_Client_G_1_new00_local);
   tolua_function(tolua_S,".call",tolua_RPC_Client_G_1_RPC_Client_G_1_new00_local);
   tolua_function(tolua_S,"new",tolua_RPC_Client_G_1_RPC_Client_G_1_new01);
   tolua_function(tolua_S,"new_local",tolua_RPC_Client_G_1_RPC_Client_G_1_new01_local);
   tolua_function(tolua_S,".call",tolua_RPC_Client_G_1_RPC_Client_G_1_new01_local);
   tolua_function(tolua_S,"delete",tolua_RPC_Client_G_1_RPC_Client_G_1_delete00);
   tolua_function(tolua_S,"CreateIPC",tolua_RPC_Client_G_1_RPC_Client_G_1_CreateIPC00);
   tolua_function(tolua_S,"CreateRepPubPort",tolua_RPC_Client_G_1_RPC_Client_G_1_CreateRepPubPort00);
   tolua_function(tolua_S,"initWithEndpoint",tolua_RPC_Client_G_1_RPC_Client_G_1_initWithEndpoint00);
   tolua_function(tolua_S,"initWithEndpoint",tolua_RPC_Client_G_1_RPC_Client_G_1_initWithEndpoint01);
   tolua_function(tolua_S,"isServerReady",tolua_RPC_Client_G_1_RPC_Client_G_1_isServerReady00);
   tolua_function(tolua_S,"getServerMode",tolua_RPC_Client_G_1_RPC_Client_G_1_getServerMode00);
   tolua_function(tolua_S,"isServerUpToDate",tolua_RPC_Client_G_1_RPC_Client_G_1_isServerUpToDate00);
   tolua_function(tolua_S,"rpc_client",tolua_RPC_Client_G_1_RPC_Client_G_1_rpc_client00);
   tolua_function(tolua_S,"rpc_client2",tolua_RPC_Client_G_1_RPC_Client_G_1_rpc_client200);
   tolua_function(tolua_S,"UnLockSendCmd",tolua_RPC_Client_G_1_RPC_Client_G_1_UnLockSendCmd00);
   tolua_function(tolua_S,"sendFile",tolua_RPC_Client_G_1_RPC_Client_G_1_sendFile00);
   tolua_function(tolua_S,"getFile",tolua_RPC_Client_G_1_RPC_Client_G_1_getFile00);
   tolua_function(tolua_S,"getAndWriteFile",tolua_RPC_Client_G_1_RPC_Client_G_1_getAndWriteFile00);
  tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
 TOLUA_API int luaopen_RPC_Client_G_1 (lua_State* tolua_S) {
 return tolua_RPC_Client_G_1_open(tolua_S);
};
#endif

