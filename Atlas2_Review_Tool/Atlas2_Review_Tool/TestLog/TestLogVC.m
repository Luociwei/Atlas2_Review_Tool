//
//  TestLogVC.m
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/11/22.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "TestLogVC.h"
#import "RecordVC.h"
#import "TextReviewVC.h"

@interface TestLogVC ()
//@property(nonatomic,strong)NSString *systemPath;
//@property(nonatomic,strong)NSString *userPath;
@end

@implementation TestLogVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.view.frame = NSMakeRect(0, 0, 1200, 650);
//    self.systemPath = self.
//    RecordVC *recordVC = [[RecordVC alloc]init];
//    [self addViewControllers:@[recordVC]];
}


-(void)setRecordPath:(NSString *)recordPath{
    //    [self.textView clean];
    
    [self removeAllChildViewController];
    if (![FileManager cw_isFileExistAtPath:recordPath]) {
        [Alert cw_messageBox:@"Error!!!" Information:[NSString stringWithFormat:@"Not found the file path:%@,pls check.",recordPath]];
        return;
    }
    RecordVC *recordVC = [[RecordVC alloc]init];
    [self addViewControllers:@[recordVC]];
    recordVC.recordPath = recordPath;
    
    NSString *systemPath = recordPath.stringByDeletingLastPathComponent;
    NSString *userPath = [recordPath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"user"];
    NSArray *systemFiles = [FileManager cw_findPathWithfFileNames:@[@".csv",@".log",@".txt"] dirPath:systemPath deepFind:NO];
    NSArray *userFiles = [FileManager cw_findPathWithfFileNames:@[@".csv",@".log",@".txt"] dirPath:userPath deepFind:NO];
    
    for (NSString *path in systemFiles) {
        if ([path isEqualToString:recordPath]) {
            continue;
        }
//        NSString *content = [FileManager cw_readFromFile:path];
        TextReviewVC *textReviewVC = [[TextReviewVC alloc]init];
        textReviewVC.title = path.lastPathComponent;
        [self addViewControllers:@[textReviewVC]];
        textReviewVC.textLogPath =path;
    }
    
    for (NSString *path in userFiles) {
        if ([path isEqualToString:recordPath]) {
            continue;
        }
//        NSString *content = [FileManager cw_readFromFile:path];
        TextReviewVC *textReviewVC = [[TextReviewVC alloc]init];
        textReviewVC.title = path.lastPathComponent;
        [self addViewControllers:@[textReviewVC]];
        textReviewVC.textLogPath =path;
    }


    
}


@end
