#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ATILuaVMDebugManager : NSObject
+ (instancetype)managerWithPath:(NSString *)path;

- (void)setBreakpoint:(NSString *)file lines:(NSArray *)lines;
- (void)clearBreakpoint:(NSString *)file line:(NSNumber *)line;
- (void)clearAllBreakpoints;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSSet *> *breakpoints;
@property (nonatomic, readonly) NSString *path;
@end

NS_ASSUME_NONNULL_END
