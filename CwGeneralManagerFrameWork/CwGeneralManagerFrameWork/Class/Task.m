//
//  PythonTask.m
//  TestDemo
//
//  Created by Louis Luo on 2020/4/20.
//  Copyright © 2017 Innorev. All rights reserved.
//

#import "Task.h"


@implementation Task
{
    BOOL isOpen;
    NSTask *task;
    NSPipe *readPipe;
    NSFileHandle *readHandle;
    NSPipe *writePipe;
    NSFileHandle *writeHandle;
}

-(instancetype)initWithLauchPath:(NSString *)lauchPath  cmd:(NSString *)cmd{
    if (self=[super init]) {
        
        task = [[NSTask alloc] init];
        [task setLaunchPath:lauchPath];//@"/usr/bin/python"
        [task setArguments:[NSArray arrayWithObjects:@"-c",@"ls",nil]];
//        task.currentDirectoryPath = NSHomeDirectory();
//        if (@available(macOS 10.13, *)) {
//            task.executableURL = [NSURL fileURLWithPath:lauchPath];
//        } else {
//            // Fallback on earlier versions
//        }
        readPipe = [NSPipe pipe];
        readHandle = [readPipe fileHandleForReading];
        writePipe = [NSPipe pipe];
        _writeHandle = [writePipe fileHandleForWriting];
        [task setStandardInput:writePipe];
        [task setStandardOutput:readPipe];
//       [task waitUntilExit];
        [task launch];
        
        NSString * read =[self cw_read];
        NSLog(@"%@",read);
        
    }
    return self;
}


+(NSString *)cw_termialWithCmd:(NSString *)cmd{
    return [self cw_termialWithCmd:cmd delay:0.05];
    
}

+(NSString *)cw_openFileWithPath:(NSString *)path{
    return [self cw_termialWithCmd:[NSString stringWithFormat:@"open %@",path]];
    
}

+(NSString *)cw_termialWithCmd:(NSString *)cmd delay:(int)delay{
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];//@"/usr/bin/python"
    [task setArguments:[NSArray arrayWithObjects:@"-c",cmd,nil]];
    //        task.currentDirectoryPath = NSHomeDirectory();
    //        if (@available(macOS 10.13, *)) {
    //            task.executableURL = [NSURL fileURLWithPath:lauchPath];
    //        } else {
    //            // Fallback on earlier versions
    //        }
    NSPipe *readPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [readPipe fileHandleForReading];
    
    [task setStandardOutput:readPipe];
//    [task waitUntilExit];
    [task launch];
    
    
    NSMutableString *mut_string = [[NSMutableString alloc]init];
    while (1) {
        [NSThread sleepForTimeInterval:delay];
        NSData *readData = [readHandle availableData];
        if (!readData.length) {
            break;
        }
        
        NSString *string = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];
        //        if (!string.length) {
        //            break;
        //        }
        [mut_string appendString:string];
    }
    
    NSLog(@"%@",mut_string);
    return mut_string;
    
}




-(instancetype)initWithPythonPath:(NSString*)path parArr:(NSArray *)parArr lauchPath:(NSString *)lauchPath{
    if (self=[super init]) {
        
        NSMutableArray *mut_parArr = [[NSMutableArray alloc]initWithArray:[NSArray arrayWithObjects:path, nil]];
        if (parArr.count) {
            [mut_parArr addObjectsFromArray:parArr];
        }
        if (task ==nil) {
            task = [[NSTask alloc] init];
            [task setLaunchPath:lauchPath];//@"/usr/bin/python"
            //        NSMutableString *mut_str = nil;
            //        if (parArr.count) {
            //            mut_str = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@"%@ %@",pythonPath,filePath]];
            //
            //            for (NSString *str in parArr) {
            //                [mut_str appendString:@" "];
            //                [mut_str appendString:@"\'"];
            //                [mut_str appendString:str];
            //                [mut_str appendString:@"\'"];
            //
            //            }
            //        }
            //        [task setArguments:[NSArray arrayWithObjects:@"-c",mut_parArr, nil]];
            [task setArguments:mut_parArr];
            readPipe = [NSPipe pipe];
            readHandle = [readPipe fileHandleForReading];
            writePipe = [NSPipe pipe];
            writeHandle = [writePipe fileHandleForWriting];
            [task setStandardInput:writePipe];
            [task setStandardOutput:readPipe];
            [task launch];
            [task waitUntilExit];
 

            
        }

    }
    return self;
}


-(void)cw_setParArr:(NSArray *)parArr  pythonPath:(NSString*)path {
    NSMutableArray *mut_parArr = [[NSMutableArray alloc]initWithArray:[NSArray arrayWithObjects:path, nil]];
    if (parArr.count) {
        [mut_parArr addObjectsFromArray:parArr];
    }
    [task setArguments:mut_parArr];
}

-(instancetype)initWithShellPath:(NSString*)filePath parArr:(NSArray *)parArr pythonPath:(NSString *)pythonPath{
    if (self=[super init]) {

        task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/sh"];

        if (!pythonPath.length) {
            pythonPath = @"python";
        }
        NSMutableString *mut_str = nil;
        if (parArr.count) {
            mut_str = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@"%@ %@",pythonPath,filePath]];
            
            for (NSString *str in parArr) {
                [mut_str appendString:@" "];
                [mut_str appendString:@"\'"];
                [mut_str appendString:str];
                [mut_str appendString:@"\'"];
                
            }
        }
        
       // @"sudo spctl --master-disable";
//        NSString * cmd = [NSString stringWithFormat:@"%@\necho '%@' | sudo -S which python",@"sudo spctl --master-disable",@"luo%2019"];
        
        
        [task setArguments:[NSArray arrayWithObjects:@"-c",mut_str, nil]];
        readPipe = [NSPipe pipe];
        readHandle = [readPipe fileHandleForReading];
        writePipe = [NSPipe pipe];
        writeHandle = [writePipe fileHandleForWriting];
        [task setStandardInput:writePipe];
        [task setStandardOutput:readPipe];
        [task launch];
        
    }
    return self;
}


-(NSString*)cw_send:(NSString*)command
{
//    if(isOpen == false)
//    {
//        return @"";
//    }
    [readHandle availableData];;
    NSString *cmd = [NSString stringWithFormat:@"%@\n",command];
    NSData * in_data = [cmd dataUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
    [writeHandle writeData:in_data];
    usleep(200000);
    //[QThread usleep: 100];
    NSData *readData = [readHandle availableData];
    NSString *string = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];
    NSLog(@"\nsend command: %@ ----> %@\n", command, string);
    return string;
}


-(NSString*)read1{

    NSData *readData = [readHandle availableData];
    NSString *string = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];

    return string;
}

-(NSString*)cw_read{
    
    NSMutableString *mut_string = [[NSMutableString alloc]init];
    while (1) {
        NSData *readData = [readHandle availableData];
        if (!readData.length) {
            break;
        }
        NSString *string = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];
//        if (!string.length) {
//            break;
//        }
        [mut_string appendString:string];
    }
    
    
    
    return mut_string;
}

-(BOOL)cw_close{
    
    if(isOpen == false)
    {
        return true;
    }
    BOOL result = false;
    NSString * in_str = @"quit\n";
    NSData * in_data = [in_str dataUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
    [_writeHandle writeData:in_data];
    [_writeHandle closeFile];
    usleep(100000);
    NSData *readData = [readHandle availableData];
    NSString *string = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];
    NSLog(@"\nsend command: %@ ----> %@\n", @"quit", string);
    if([string containsString:@"Quitting"])
    {
        isOpen = false;
        result = true;
    }
    [task waitUntilExit];
    return result;
}


-(BOOL)cw_isOpen
{
    return isOpen;
}


@end
