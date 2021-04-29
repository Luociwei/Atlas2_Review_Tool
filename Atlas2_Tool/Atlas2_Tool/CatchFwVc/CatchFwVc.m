//
//  CatchFwVc.m
//  DFU_Tool
//
//  Created by ciwei luo on 2021/4/20.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "CatchFwVc.h"
//#import <CwGeneralManagerFrameWork/TextView.h>
//#import <CwGeneralManagerFrameWork/Task.h>
@interface CatchFwVc ()
@property (nonatomic,strong)TextView *textView;
@end

@implementation CatchFwVc{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
    [self.view addSubview:self.textView];
}

-(void)viewWillAppear{
    [super viewWillAppear];
    
    NSString *pyPath = [[NSBundle mainBundle] pathForResource:@"DFU_Station_CatchFW.py" ofType:nil];
    NSString *cmd = [NSString stringWithFormat:@"python %@",pyPath];
   NSString *log = [Task termialWithCmd:cmd];
    [self.textView showLog:[NSString stringWithFormat:@"\n\n\n%@",log]];
}

@end
