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

-(void)viewWillDisappear{
    [super viewWillDisappear];

}

-(void)viewWillAppear{
    [super viewWillAppear];

    if (![FileManager cw_isFileExistAtPath:_recordPath]) {
        [Alert cw_messageBox:@"Error!!!" Information:[NSString stringWithFormat:@"Not found the file path:%@,pls check.",_recordPath]];
        return;
    }
    
    RecordVC *recordVC = [[RecordVC alloc]init];
    recordVC.title = _recordPath.lastPathComponent;
    recordVC.recordPath = _recordPath;
    [self addViewControllers:@[recordVC]];
    
    
    NSString *systemPath = _recordPath.stringByDeletingLastPathComponent;
    NSString *userPath = [_recordPath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"user"];
    NSArray *systemFiles = [FileManager cw_findPathWithfFileNames:@[@".csv",@".log",@".txt"] dirPath:systemPath deepFind:NO];
    NSArray *userFiles = [FileManager cw_findPathWithfFileNames:@[@".csv",@".log",@".txt"] dirPath:userPath deepFind:NO];
    
    for (NSString *path in systemFiles) {
        if ([path isEqualToString:_recordPath]) {
            continue;
        }
        //        NSString *content = [FileManager cw_readFromFile:path];
        TextReviewVC *textReviewVC = [[TextReviewVC alloc]init];
        textReviewVC.title = path.lastPathComponent;
        textReviewVC.textLogPath =path;
        [self addViewControllers:@[textReviewVC]];
        
    }
    
    for (NSString *path in userFiles) {
        if ([path isEqualToString:_recordPath]) {
            continue;
        }
        //        NSString *content = [FileManager cw_readFromFile:path];
        TextReviewVC *textReviewVC = [[TextReviewVC alloc]init];
        textReviewVC.title = path.lastPathComponent;
        textReviewVC.textLogPath =path;
        [self addViewControllers:@[textReviewVC]];
        
    }
    
    
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.view.frame = NSMakeRect(0, 0, 1200, 650);
//    self.view.window = @"";
//    NSView *titleView = [self.view.window standardWindowButton:NSWindowDocumentIconButton].superview;
//    NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:@"NSFolder"] target:self action:@selector(windowBtnClick:)];
////    button.frame = NSMakeRect(0,0,24,24);
//    button.bezelStyle = NSBezelStyleRegularSquare;
//    [titleView addSubview:button];
    
//    NSImage *image = [NSImage imageNamed:@"NSFolder"];
//    [[self.view.window standardWindowButton:NSWindowDocumentIconButton] setImage:image];
    
//    self.systemPath = self.
//    RecordVC *recordVC = [[RecordVC alloc]init];
//    [self addViewControllers:@[recordVC]];
}


//-(void)setRecordPath:(NSString *)recordPath{
//    //    [self.textView clean];
//
//    _recordPath = recordPath;

//
//
//}


@end
