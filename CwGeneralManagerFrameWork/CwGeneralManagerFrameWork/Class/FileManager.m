//
//  CWFileManager.m
//  Callisto_Charge
//
//  Created by Louis Luo on 2018/7/5.
//  Copyright © 2017 Innorev. All rights reserved.
//

#import "FileManager.h"
#import "Alert.h"

@implementation FileManager

+(void)cw_createFile:(NSString *)filePath isDirectory:(BOOL)isDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        if (isDirectory) {
            [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }else{
            [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        }
    }
}

+(void)cw_removeItemAtPath:(NSString *)filePath
{
   
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
    
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
}

+(BOOL)cw_isFileExistAtPath:(NSString*)fileFullPath {
    BOOL isExist = NO;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:fileFullPath];
    return isExist;
}
//文件是否能够写
+(BOOL)fileCanWrite:(NSString*)filePath
{
    BOOL readFlag=NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager isWritableFileAtPath:filePath]) readFlag= YES;
    
    return readFlag;
}

+(BOOL)cw_fileCanWrite:(NSString*)filePath{
    if (![self fileCanWrite:filePath]) {
        [self cw_createFile:filePath isDirectory:NO];
    }
    if (![self fileCanWrite:filePath]) {
        NSString *info = [NSString stringWithFormat:@"%@ was not able to be wrote",filePath ];
        [Alert cw_RemindException:@"Error" Information:info];
        return NO;
    }
    return YES;
}

+(NSString *)cw_readFromFile:(NSString *)filePath
{
    return [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
}
+(NSString *)cw_getAppResourcePath{
    NSString *bundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
    NSString *resourcePath =[[[bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingString:@"/Resources"];
    return resourcePath;
}
+(BOOL)cw_writeToFile:(NSString*)filePath content:(NSString*)content
{
    if (![self cw_fileCanWrite:filePath]) {
        return NO;
    }
    @synchronized(self) {
        NSMutableData *writer = [[NSMutableData alloc] initWithContentsOfFile:filePath];
        [writer appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
        [writer writeToFile:filePath atomically:YES];
    }
    return YES;
}

+(BOOL)cw_fileHandleWriteToFile:(NSString *)filePath content:(NSString *)content
{
    
    if ([self cw_fileCanWrite:filePath]) {
        return NO;
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@",content]  dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
    return YES;
}


+ (id)cw_serializationWithJsonFilePath:(NSString *)filePath
{
    
    NSFileManager * fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:filePath]) {
        
        // 保存 json 文件中的信息，即那些字符串
        NSString * jsonStr = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        return [self cw_serializationWithJsonString:jsonStr];
    }else{
         [Alert cw_RemindException:@"Error" Information:@"not found the file"];
        NSLog(@"not found the file");
        return nil;
    }
    
    
}

//+ (id)cw_serializationWithJsonFileInMainBundle:(NSString *)fileName
//{
//    NSLog(@"1");
//    NSString * path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
//    return [self cw_serializationWithJsonFilePath:path];
//}


// JSON字符串转化为字典
+ (id)cw_serializationWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                             options:NSJSONReadingMutableContainers
                                               error:&err];
    if(err)
    {
        [Alert cw_RemindException:@"Error" Information:[NSString stringWithFormat:@"json解析失败：%@",err]];
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

+ (id)cw_serializationInMainBundleFile:(NSString *)fileName
{
    NSString * path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    
    return [self cw_serializationWithJsonFilePath:path];
    
}

//+ (id)cw_serializationWithPlistFilePath:(NSString *)path
//{
//
//    NSFileManager * fileMgr = [NSFileManager defaultManager];
//    if (![fileMgr fileExistsAtPath:path]) {
//        NSLog(@"not found the file");
//        return nil;
//    }
//
//    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:path];
//    if (dic) {
//        return dic;
//    }else{
//        NSArray *arr=[[NSArray alloc]initWithContentsOfFile:path];
//        return arr;
//    }
//
//}


+(void)cw_openFileWithPath:(NSString *)path{
    system([[NSString stringWithFormat:@"open %@",path] UTF8String]);
}

//NSFileManager *manager = [NSFileManager defaultManager];
//NSString *flow_file = [systemFile stringByAppendingPathComponent:@"device.log"];
//for (NSString *file in [manager enumeratorAtPath:systemFile]) {
//
//    if ([file containsString:@"flow.log"]) {
//        flow_file = [systemFile stringByAppendingPathComponent:file];
//        break;
//    }
//}

+(NSArray *)cw_findPathWithfFileNames:(NSArray *)fileNames dirPath:(NSString *)dirPath deepFind:(BOOL)isDeedFind{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSMutableArray *mutPathArr = [[NSMutableArray alloc]init];
    if (isDeedFind) {
        for (NSString *name in [manager enumeratorAtPath:dirPath]) {
            
            for (NSString *fileName in fileNames) {
                if ([name containsString:fileName]) {
                    //flow_file = [systemFile stringByAppendingPathComponent:file];
                    NSString *file_path = [dirPath stringByAppendingPathComponent:name];
                    [mutPathArr addObject:file_path];
                    break;
                    
                }
            }

        }
    }else{
        NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
        for (NSString *name in tmplist) {
            for (NSString *fileName in fileNames) {
                if ([name containsString:fileName]) {
                    NSString *file_path = [dirPath stringByAppendingPathComponent:name];
                    [mutPathArr addObject:file_path];
                    break;
                }
            }
        }
    }
    
    return mutPathArr;
}

+(NSArray *)cw_findPathWithfFileName:(NSString *)fileName dirPath:(NSString *)dirPath deepFind:(BOOL)isDeedFind{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSMutableArray *mutPathArr = [[NSMutableArray alloc]init];
    if (isDeedFind) {
        for (NSString *name in [manager enumeratorAtPath:dirPath]) {
            
            if ([name containsString:fileName]) {
                //flow_file = [systemFile stringByAppendingPathComponent:file];
                NSString *file_path = [dirPath stringByAppendingPathComponent:name];
                [mutPathArr addObject:file_path];
                
            }
        }
    }else{
        NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
        for (NSString *name in tmplist) {
            if ([name containsString:fileName]) {
                NSString *file_path = [dirPath stringByAppendingPathComponent:name];
                [mutPathArr addObject:file_path];
            }
        }
    }

    return mutPathArr;
}
+(NSArray *)cw_getFilenamelistOfType:(NSString *)type fromDirPath:(NSString *)dirPath
{
    NSMutableArray *filenamelist = [[NSMutableArray alloc]init];
    NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    
    for (NSString *filename in tmplist) {
        NSString *fullpath = [dirPath stringByAppendingPathComponent:filename];
        if ([self cw_isFileExistAtPath:fullpath]) {
//            NSString *ss =[filename pathExtension];
            if ([[filename pathExtension] isEqualToString:type]) {
                [filenamelist  addObject:filename];
            }
        }
    }
    
    return filenamelist;
}


+(void)cw_copyBundleFileToDestPath:(NSString *)fullName destDir:(NSString *)destDir{
    NSString *file = [[NSBundle mainBundle] pathForResource:fullName ofType:nil];
    [self cw_copyFlolderFrom:file to:destDir];
    
}

+(void)cw_copyFlolderFrom:(NSString *)filePath to:(NSString *)toPath {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:toPath])
    {
        [fileManager removeItemAtPath:toPath error:&error];
    }
    [fileManager copyItemAtPath:filePath toPath:toPath error:&error];
}


+(void)openPanel:(void(^)(NSString * path))callBack{
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    //NSString *openPath =[[NSBundle mainBundle] resourcePath];
    NSString *openPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)lastObject];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:openPath]];
    
    NSArray *fileType=[NSArray arrayWithObjects:@"csv",nil];
    [openPanel setAllowedFileTypes:fileType];
    ;
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    
    [openPanel beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:^(NSInteger result){
        if (result==NSFileHandlingPanelOKButton)
        {
            
           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                NSArray *urls=[openPanel URLs];
                
                for (int i=0; i<[urls count]; i++)
                {
                    NSString *csvPath = [[urls objectAtIndex:i] path];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callBack(csvPath);
                        // [self refleshWithPath:csvPath];
                    });
                }
            });
        }
    }];
}



+(void)savePanel:(void(^)(NSString * path))callBack
{
    NSSavePanel *saveDlg = [[NSSavePanel alloc]init];
    saveDlg.title = @"Save File";
    saveDlg.message = @"Save File";
//    saveDlg.allowedFileTypes = @[@"png"];
    saveDlg.nameFieldStringValue = @"xxxx";
    [saveDlg beginWithCompletionHandler: ^(NSInteger result){
        
        if(result==NSFileHandlingPanelOKButton){
            callBack([[saveDlg URL] path]);
        }
        
    }];
    
}
@end
