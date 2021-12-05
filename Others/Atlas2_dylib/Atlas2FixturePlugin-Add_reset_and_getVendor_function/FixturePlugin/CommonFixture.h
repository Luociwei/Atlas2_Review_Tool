
#import <Foundation/Foundation.h>
#import <AtlasLuaSequencer/AtlasLuaSequencer.h>
#import <AtlasIO/AtlasIO.h>


NS_ASSUME_NONNULL_BEGIN


@interface CommonFixture : NSObject

@property(readonly) NSDictionary *pluginFunctionTable;
@property(readonly) NSDictionary *pluginConstantTable;

@property (readonly) NSString *stationName;   // J3XX or J5XX, default J3XX

- (instancetype)initWithGroupId:(int)groupId error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
