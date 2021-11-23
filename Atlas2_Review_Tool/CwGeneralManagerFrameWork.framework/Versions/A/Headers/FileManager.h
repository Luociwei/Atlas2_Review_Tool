//
//  CWFileManager.h
//  Callisto_Charge
//
//  Created by Louis Luo on 2018/7/5.
//  Copyright © 2017 Innorev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileManager : NSObject

+(void)cw_createFile:(NSString *)filePath isDirectory:(BOOL)isDirectory;
+(BOOL)cw_isFileExistAtPath:(NSString*)fileFullPath;
//文件是否能够写
+(BOOL)cw_fileCanWrite:(NSString*)filePath;
+(NSString *)cw_getAppResourcePath;
+(NSString *)cw_readFromFile:(NSString *)filePath;

+(BOOL)cw_writeToFile:(NSString*)filePath content:(NSString*)content;
+(BOOL)cw_fileHandleWriteToFile:(NSString *)filePath content:(NSString *)content;

+(void)cw_removeItemAtPath:(NSString *)filePath;

+(id)cw_serializationWithJsonFilePath:(NSString *)filePath;
+ (id)cw_serializationWithJsonString:(NSString *)jsonString;
+ (id)cw_serializationInMainBundleFile:(NSString *)fileName;
+(void)cw_openFileWithPath:(NSString *)path;
+(NSArray *)cw_findPathWithfFileNames:(NSArray *)fileNames dirPath:(NSString *)dirPath deepFind:(BOOL)isDeedFind;
+(NSArray *)cw_findPathWithfFileName:(NSString *)fileName dirPath:(NSString *)dirPath deepFind:(BOOL)isDeedFind;
+(NSArray *)cw_getFilenamelistOfType:(NSString *)type fromDirPath:(NSString *)dirPath;

+(void)cw_copyBundleFileToDestPath:(NSString *)fullName destDir:(NSString *)destDir;
+(void)cw_copyFlolderFrom:(NSString *)filePath to:(NSString *)toPath;

+(void)openPanel:(void(^)(NSString * path))callBack;
+(void)savePanel:(void(^)(NSString * path))callBack;
@end

NS_ASSUME_NONNULL_END
