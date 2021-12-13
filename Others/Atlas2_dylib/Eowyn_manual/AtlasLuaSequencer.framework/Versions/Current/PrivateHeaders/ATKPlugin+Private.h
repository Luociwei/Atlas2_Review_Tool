#import <Foundation/Foundation.h>
#import <AtlasLuaSequencer/AtlasLuaSequencer.h>

@interface ATKLuaPlugin ()

@property (readonly) NSDictionary *functions;

+ (ATKLuaPlugin *)pluginWithContentsOfPath:(NSString *)path
                                bridgeable:(BOOL)canPass
                                     error:(NSError *__autoreleasing *)error;
- (id)getPluginContext;

@end

@interface ATKLuaCallback : NSObject

@property (readonly) int callback_reference;
@property (readonly, weak) NSUUID *uuid;

- (ATKLuaCallback *)init:(int)callback_reference withVMUUID:(NSUUID *)uuid;

@end

#ifdef __cplusplus
extern "C" {
#endif

BOOL patternMatchesArgument(NSArray *pattern, NSArray *args);
BOOL checkFunctionImpl(NSDictionary *interfaceRequirements, NSString *funcName, ATKLuaReturnType givenReturnType,
                       NSArray *argTypes);
NSData *serializePluginInfo(ATKLuaPlugin *plugin, NSError **error);
BOOL deserializePluginInfo(NSData *archive, NSMutableDictionary *functions, NSMutableDictionary *functionReturns,
                           NSMutableDictionary *constants, NSError **error);

#ifdef __cplusplus
}
#endif
