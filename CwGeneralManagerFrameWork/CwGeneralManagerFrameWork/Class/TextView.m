//
//  TextView.m
//  MyBase
//
//  Created by Louis Luo on 2021/12/24.
//  Copyright © 2021 Suncode. All rights reserved.
//
#import "Task.h"
#import "Masonry.h"
#import "TextView.h"
//#import "CWGeneralManager.h"
#import "NSString+Extension.h"
#import "Image.h"
#import "FileManager.h"
@interface TextView ()
@property (strong,nonatomic)NSMutableString *mutLogString;
//@property (nonatomic, strong) NSTextView *logTextView;
//@property (unsafe_unretained) IBOutlet NSTextView *logTextView;
//@property (nonatomic, strong) NSScrollView *scrollView;

@end


@implementation TextView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
//    self.scrollView.bounds = dirtyRect;
}



-(void)clean{
    self.mutLogString=nil;
//    [self.mutLogString appendString:@"Clean..................\n"];
    self.string = @"";
}


//+(void)postNotificationWithLog:(NSString *)log type:(NSString *)type{
//    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
//    [dic setObject:log forKey:@"log"];
//    [dic setObject:type forKey:@"type"];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowingLogVCWillPrintLog" object:nil userInfo:dic];
//}

- (void)saveLog{
    NSString *log = self.mutLogString;
    [FileManager savePanel:^(NSString * _Nonnull path) {
        [FileManager cw_writeToFile:path content:log];
    }];
}


-(void)showLog:(NSString *)log
{
    
    
    NSString *timeString = [NSString cw_stringFromCurrentDateTimeWithMicrosecond];
    [self.mutLogString appendString:[NSString stringWithFormat:@"%@ %@\n",timeString,log]];
    //    self.string = self.mutLogString;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.string = self.mutLogString;
        [self scrollRangeToVisible:NSMakeRange(self.string.length, 1)];
    });
    
}


-(NSMutableString *)mutLogString{
    if (_mutLogString==nil) {
        _mutLogString = [[NSMutableString alloc]init];
    }
    return _mutLogString;
}


//-(void)dealloc{
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}


-(void)setPingIpAddress:(NSString *)ip{
    //    if ([self.title containsString:@"1"]) {
    //        return;
    //    }
    NSString *ip_address = [NSString stringWithFormat:@"ping %@",ip];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/sh"];
        
        [task setArguments:[NSArray arrayWithObjects:@"-c",ip_address, nil]];
        //        NSData *readData = nil;
        NSPipe* nsreadPipe = [NSPipe pipe];
        NSFileHandle *nsreadHandle = [nsreadPipe fileHandleForReading];
        [task setStandardOutput: nsreadPipe];
        [task launch];
        
        while (1)
        {
            
            NSData *readData = [nsreadHandle availableData];
            if (readData.length) {
                NSString *reply = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];
                
                
                [self showLog:reply];
                
                
            }else{
                break;
            }
            
            
            [NSThread sleepForTimeInterval:0.5];
        }
    });
}



-(void)searchIpFrom:(NSString *)ip to:(NSInteger)ipRangeCount{
    //    if ([self.title containsString:@"1"]) {
    //        return;
    //    }
    
    NSArray *ipSegmentArr = [ip cw_componentsSeparatedByString:@"."];
    NSInteger ipSegmentEnd = [ipSegmentArr.lastObject integerValue];
    
    NSString *ipPingSegments = [NSString stringWithFormat:@"%@.%@.%@.",ipSegmentArr[0],ipSegmentArr[1],ipSegmentArr[2]];
    
//    NSString *ip_address = [NSString stringWithFormat:@"ping %@",ipStart];
    BOOL isSearch = NO;
    for (int i =0; i<ipRangeCount; i++) {
        NSString *ip =[NSString stringWithFormat:@"%@%ld",ipPingSegments,ipSegmentEnd+i];
        NSString *pingIP =[NSString stringWithFormat:@"ping %@ -t1",ip];
        NSString *read  = [Task cw_termialWithCmd:pingIP];
        if ([read containsString:@"icmp_seq="]&&[read containsString:@"ttl="]) {
            [self showLog:[NSString stringWithFormat:@"Connect IP:%@",ip]];
            isSearch = YES;
        }
    }
    if (!isSearch) {
        [self showLog:@"Connect IP:None"];
    }

}





@end
