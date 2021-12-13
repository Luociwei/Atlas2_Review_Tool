#import <AtlasLuaSequencer/AtlasLuaSequencer.h>
#import <Foundation/Foundation.h>

#import "ATKPlugin+Private.h"

extern const char *const ATLAS_LUA_VM_UUID_KEY;
extern const char *const ATLAS_LUA_VM_CALLBACK_MAPPING_KEY;
extern const char *const ATLAS_LUA_VM_CALLBACK_SET_KEY;

@interface ATKLuaVM ()

@property (readonly) NSArray *resourcePaths;
@property (readonly) NSUUID *uuid;

- (id)executeCallback:(ATKLuaCallback *)callback args:(NSArray *)args error:(NSError *__autoreleasing *)error;

@end
