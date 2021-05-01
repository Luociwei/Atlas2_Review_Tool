//
//  FailOnlyItems.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/4/26.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "FailOnlyItems.h"
@interface FailOnlyItems ()
@property (nonatomic,strong)TextView *textView;
@property (nonatomic,strong)NSView *textView1;
@end

@implementation FailOnlyItems

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.textView = [[TextView alloc]init];
    //    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
    [self.view addSubview:self.textView];
//    self.textView1.frame = self.view.bounds;
    [self setupAutolayout];
//    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
//    [self.view addSubview:self.textView];
//    NSString *pyPath = [[NSBundle mainBundle] pathForResource:@"DFU_Station_CatchFW.py" ofType:nil];
//    NSString *cmd = [NSString stringWithFormat:@"python %@",pyPath];
//    NSString *log = [Task termialWithCmd:cmd];
//    [self.textView showLog:[NSString stringWithFormat:@"\n\n\n%@",log]];
}
//- (void)loadView {
//    [super loadView];
//    self.textView = [[TextView alloc]init];
////    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
//    [self.view addSubview:self.textView];
////    [self.textView addItemsToView];
//
//}
-(void)setRecordPath:(NSString *)recordPath{
    [self.textView clean];
    if (recordPath.length) {
        _recordPath = recordPath;
        NSString *cmd = [NSString stringWithFormat:@"grep \",FAIL,\" %@",recordPath];
        NSString *log = [Task termialWithCmd:cmd];
        [self.textView showLog:[NSString stringWithFormat:@"%@\n%@",recordPath,log]];
    }
}



- (void)setupAutolayout {
 
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束
        make.left.and.top.and.bottom.and.right.mas_equalTo(0);

    }];
}
@end
