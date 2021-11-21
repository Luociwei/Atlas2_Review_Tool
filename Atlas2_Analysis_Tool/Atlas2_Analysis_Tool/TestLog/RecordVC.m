//
//  FailOnlyItems.m
//  Atlas2_Analysis_Tool
//
//  Created by ciwei luo on 2021/4/26.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "RecordVC.h"

@interface RecordVC ()
@property (nonatomic,strong)TextView *textView;
@property (nonatomic,strong)NSView *textView1;

@property (weak) IBOutlet NSTableView *recordTableView;
@property(nonatomic,strong)TableDataDelegate *tableDataDelegate;
@end

@implementation RecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.textView = [[TextView alloc]init];
    //    self.textView = [TextView cw_allocInitWithFrame:self.view.bounds];
    [self.view addSubview:self.textView];
//    self.textView1.frame = self.view.bounds;
    [self setupAutolayout];
    
    self.tableDataDelegate.owner = self.recordTableView;

}

-(void)setRecordPath:(NSString *)recordPath{
    [self.textView clean];
    if (recordPath.length) {
        _recordPath = recordPath;
        NSString *cmd = [NSString stringWithFormat:@"grep \",FAIL,\" %@",recordPath];
        NSString *log = [Task cw_termialWithCmd:cmd];
        [self.textView showLog:[NSString stringWithFormat:@"%@\n%@",recordPath,log]];
    }
}



- (void)setupAutolayout {
 
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束
        make.left.and.top.and.bottom.and.right.mas_equalTo(0);

    }];
}



-(TableDataDelegate *)tableDataDelegate{
    if (!_tableDataDelegate) {
        //        __weak __typeof(self)weakSelf = self;
        __weak __typeof(&*self)weakSelf = self;
        _tableDataDelegate = [[TableDataDelegate alloc]initWithTaleView:_recordTableView];
        _tableDataDelegate.tableViewForTableColumnCallback = ^(id view, NSInteger row, NSDictionary *data,NSString *idfix) {
            if ([idfix isEqualToString:id_record]) {
                BOOL isfail = [[data objectForKey:key_is_fail] boolValue];
                NSButton *btn = (NSButton *)view;
                if (isfail) {
                    
                    btn.layer.backgroundColor = [NSColor systemRedColor].CGColor;
                }else{
                    btn.layer.backgroundColor = [NSColor systemGreenColor].CGColor;
                }
                
            }else if([idfix isEqualToString:id_index]) {
                NSTextField *textView = (NSTextField *)view;
                textView.stringValue =[ NSString stringWithFormat:@"%ld",row+1];
            }
            
        };

        _tableDataDelegate.tableViewRowDoubleClickCallback = ^(NSInteger index, NSDictionary *item_data) {
            
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
//            NSString *record_path = [item_data objectForKey:key_record_path];

        };
        
        
        
        _tableDataDelegate.buttonClickCallback = ^(NSInteger index, NSDictionary *item_data) {
            
            //            __strong __typeof(weakSelf)strongSelf = weakSelf;
            NSString *record_path = [item_data objectForKey:key_record_path];
            if ([FileManager cw_isFileExistAtPath:record_path]) {
                [Task cw_openFileWithPath:record_path.stringByDeletingLastPathComponent];
            }
            
        };
        
        _tableDataDelegate.tableViewdidClickColumnCallback = ^(NSString *identifier, NSInteger clickIndex) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
        };
        
    }
    return _tableDataDelegate;
}

@end
