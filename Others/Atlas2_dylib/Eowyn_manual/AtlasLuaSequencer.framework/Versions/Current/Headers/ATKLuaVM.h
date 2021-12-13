#import <Foundation/Foundation.h>
#import "ATIDebugVM.h"
#import "ATILuaVMDebugManager.h"
#import <AtlasLogging/AtlasLogging.h>

@class ATKLuaVM;
@protocol ATIDebugHookHandler <NSObject>
- (void)registerVMManager:(ATILuaVMDebugManager *)manager;
- (void)deregisterVMManager:(ATILuaVMDebugManager *)manager;

- (void)didTriggerCallHook;
- (void)didTriggerReturnHook;
- (void)didTriggerLineHookIn:(NSString *)currentFile onLine:(NSNumber *)currentLine;

- (void)handleVMError;

- (void)perform:(ATIDebugVM *)activeVM;
@end

@interface ATKLuaVM : NSObject

+ (instancetype)resourcePaths:(NSArray *)resourcePaths
              globalVariables:(NSDictionary *)globals
                  hookHandler:(id<ATIDebugHookHandler>)hookHandler
                         name:(NSString *)name
                        error:(NSError *__autoreleasing *)error;

- (BOOL)loadSequenceFile:(NSString *)path
            hostingHooks:(NSDictionary *)hostingHooks
                   error:(NSError *__autoreleasing *)error;

- (NSArray *)runEntryPoint:(NSString *)entry args:(NSArray *)args error:(NSError *__autoreleasing *)error;

- (void)close;

@property (nonatomic, readonly) id<ATIDebugHookHandler> hookHandler;
@property (nonatomic, readonly) NSString *name;

@end
