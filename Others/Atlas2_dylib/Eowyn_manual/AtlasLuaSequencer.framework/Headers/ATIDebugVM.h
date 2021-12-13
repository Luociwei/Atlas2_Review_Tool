#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ATIDebugInfo : NSObject
@property (strong, nonatomic) NSString *currentFile;
@property (strong, nonatomic) NSNumber *currentLine;
@property (strong, nonatomic) NSDictionary *localVars;
@property (strong, nonatomic) NSDictionary *globalVars;
@property (strong, nonatomic) NSNumber *stackOffset;
@property (strong, nonatomic) NSArray *stackTrace;
@property (strong, nonatomic) NSString *sourceSnippet;
@property (strong, nonatomic) NSString *errorMessage;
@end

@protocol ATIVMOps <NSObject>
- (ATIDebugInfo *)getInfo:(int)stackOffset;

- (NSString *)getVarsString:(int)stackOffset;
- (NSString *)getGlobalVarsString;
- (NSString *)sourcePath:(int)stackOffset;
- (NSString *)getSource:(int)surroundingLines stackOffset:(int)stackOffset;
- (NSString *_Nullable)execute:(NSString *)request stackOffset:(int)stackOffset;
- (NSArray *)getStackTrace;
- (NSString *_Nullable)getErrorMessage;
- (NSString *)update:(NSString *)varName newValue:(NSString *)newValue stackOffset:(int)stackOffset;

- (BOOL)doString:(NSString *)string;
@end

@interface ATIDebugVM : NSObject <ATIVMOps>
@end

NS_ASSUME_NONNULL_END
