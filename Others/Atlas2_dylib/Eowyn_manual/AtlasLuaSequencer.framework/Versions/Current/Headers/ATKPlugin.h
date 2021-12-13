#import <AtlasLuaSequencer/AtlasLuaSequencer.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ATKSelector(selector_) __atiGetSelectorLabel(@selector(selector_))

#define ATKType(class_) __atiArgTypeLabel([class_ class])
#define ATKNumber ATKType(NSNumber)
#define ATKString ATKType(NSString)
#define ATKArray ATKType(NSArray)
#define ATKData ATKType(NSData)
#define ATKDictionary ATKType(NSDictionary)
#define ATKCallback ATKType(ATKLuaCallback)
#define ATKVariadic __atiVargTypeLabel()
#define ATKProtocol(protocol_) __atiProtocolLabel(@protocol(protocol_))
#define ATKAny __atiAnyTypeLabel()

#define ATKPack(arr) __atiPackedReturnType((arr))

typedef NS_ENUM(NSInteger, ATKLuaReturnType) {
    ATKLuaFFIReturnObject,
    ATKLuaFFIReturnBoolean,
    ATKLuaFFINoReturn,
    ATKLuaFFIInvalid
};

@protocol ATKLuaPluginProtocol <NSObject>

@property (readonly) NSString *identifier;
@property (readonly) BOOL bridgeable;

- (NSArray *)availableFunctions;
- (NSDictionary *)availableConstants;

// NOTE: This should be used to ensure the plugin adheres to the desired interface. It can be useful in plugins that
// accept other plugins as an input argument.
- (BOOL)checkFunction:(NSString *)functionName returns:(ATKLuaReturnType)returnType arguments:(NSArray *)argTypes;

// NOTE: Should be used as a preflight check before executing a function.
//  The Execution Order is as follows:
//      1. Ensure that a plugin can perform the desired function (checkFunctionExists:)
//      2. Ensure that the arguments to the functions match to the desired pattern.
//         (checkPatternForFunction:argument:)
//      3. Check execution model type of the function
//      4. Call the appropriate "perform method" based on the execution model.
//          ATKLuaFFIReturnObject   mode should call performObject:args:error:
//          ATKLuaFFIReturnBoolean  mode should call performBOOL:args:error:
//          ATKLuaFFINoReturn       mode should call performVoid:args:error:
- (BOOL)checkFunctionExists:(NSString *)functionName;
- (BOOL)checkPatternForFunction:(NSString *)functionName argument:(NSArray *)args;
- (ATKLuaReturnType)getFunctionReturnType:(NSString *)functionName;

- (id)performObject:(NSString *)functionName args:(NSArray *)args error:(NSError *__autoreleasing *)error;
- (BOOL)performBOOL:(NSString *)functionName args:(NSArray *)args error:(NSError *__autoreleasing *)error;
- (void)performVoid:(NSString *)functionName args:(NSArray *)args;

@end

@interface ATKLuaPlugin : NSObject <ATKLuaPluginProtocol>

+ (ATKLuaPlugin *)pluginWithContentsOfFile:(NSString *)path
                                bridgeable:(BOOL)canPass
                                     error:(NSError *__autoreleasing *)error;

+ (ATKLuaPlugin *)pluginWithContext:(id)context
                          functions:(NSDictionary *)functions
                              error:(NSError *__autoreleasing *)error;

+ (ATKLuaPlugin *)pluginWithContext:(id)context
                          functions:(NSDictionary *)functions
                          constants:(NSDictionary *)constants
                              error:(NSError *__autoreleasing *)error;

+ (ATKLuaPlugin *)pluginWithContext:(id)context
                          functions:(NSDictionary *)functions
                         bridgeable:(BOOL)canPass
                              error:(NSError *__autoreleasing *)error;

+ (ATKLuaPlugin *)pluginWithContext:(id)context
                          functions:(NSDictionary *)functions
                          constants:(NSDictionary *)constants
                         bridgeable:(BOOL)canPass
                              error:(NSError *__autoreleasing *)error;

@end

id __atiGetSelectorLabel(SEL selector);
id __atiArgTypeLabel(Class type);
id __atiProtocolLabel(Protocol *protocol);
id __atiVargTypeLabel(void);
id __atiAnyTypeLabel(void);
id __atiPackedReturnType(NSArray *);

#ifdef __cplusplus
}
#endif
