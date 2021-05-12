//
//  LuaFunction.m
//  Atlas2_Tool
//
//  Created by ciwei luo on 2021/5/11.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "LuaFunction.h"

@interface LuaFunction ()
//@property (nonatomic,strong)TextView *textView;
@property (unsafe_unretained) IBOutlet NSTextView *textFuncView;

@end

@implementation LuaFunction

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    //self.textView = [[TextView alloc]init];
    //    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
    //[self.view addSubview:self.textView];
    //    self.textView1.frame = self.view.bounds;
    //[self setupAutolayout];
}

-(void)setLuaFunctionPath:(NSString *)luaFuncPath{
    self.textFuncView.string = @"";
    if (luaFuncPath.length) {
        _luaFunctionPath = luaFuncPath;
        NSString *content = [FileManager cw_readFromFile:luaFuncPath];
        [self.textFuncView setString:content];
        
//        NSString *cmd = [NSString stringWithFormat:@"grep \",FAIL,\" %@",recordPath];
//        NSString *log = [Task cw_termialWithCmd:cmd];
//        [self.textView showLog:[NSString stringWithFormat:@"%@\n%@",recordPath,log]];
    }
}

//- (void)setupAutolayout {
//
//    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
//        // 添加大小约束
//        make.left.and.top.and.bottom.and.right.mas_equalTo(0);
//
//    }];
//}

- (IBAction)performChanges:(NSButton *)btn {
    [FileManager cw_removeItemAtPath:_luaFunctionPath];
    NSString *content = self.textFuncView.string;
    [FileManager cw_writeToFile:_luaFunctionPath content:content];
}


@end
