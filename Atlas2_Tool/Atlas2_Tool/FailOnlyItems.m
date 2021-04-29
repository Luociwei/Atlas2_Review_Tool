//
//  FailOnlyItems.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/26.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "FailOnlyItems.h"
#import <CwGeneralManagerFrameWork/TextView.h>
#import <CwGeneralManagerFrameWork/Task.h>
@interface FailOnlyItems ()
@property (nonatomic,strong)TextView *textView;
@end

@implementation FailOnlyItems

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
    [self.view addSubview:self.textView];
//    NSString *pyPath = [[NSBundle mainBundle] pathForResource:@"DFU_Station_CatchFW.py" ofType:nil];
//    NSString *cmd = [NSString stringWithFormat:@"python %@",pyPath];
//    NSString *log = [Task termialWithCmd:cmd];
//    [self.textView showLog:[NSString stringWithFormat:@"\n\n\n%@",log]];
}

-(void)setRecordPath:(NSString *)recordPath{
    [self.textView showLog:@""];
    if (recordPath.length) {
        _recordPath = recordPath;
        NSString *cmd = [NSString stringWithFormat:@"grep \",FAIL,\" %@",recordPath];
        NSString *log = [Task termialWithCmd:cmd];
        [self.textView showLog:[NSString stringWithFormat:@"%@\n%@",recordPath,log]];
    }
}


-(void)viewDidLayout{
    [super viewDidLayout];
    self.textView.frame = self.view.bounds;
}

@end
