#ifndef ATILuaVMSyscall_hpp
#define ATILuaVMSyscall_hpp

#include <stdio.h>

int system__no_lock(char const *command);

FILE *safer_popen(const char *filename, const char *mode);

#endif /* ATILuaVMSyscall_hpp */
