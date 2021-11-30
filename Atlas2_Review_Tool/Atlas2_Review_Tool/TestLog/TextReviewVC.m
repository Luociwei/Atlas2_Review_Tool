//
//  TextReviewVC.m
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/11/22.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "TextReviewVC.h"

@interface TextReviewVC ()
@property (weak) IBOutlet NSButton *btnFail;

@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *filePathView;
@property (nonatomic, copy) NSString *contentStr;
@property (nonatomic, copy) NSString *contentFailStr;
//@property(nonatomic,strong)CSVParser *csv;
@end

@implementation TextReviewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (IBAction)filePathClick:(NSButton *)sender {
    NSString *file = [self.filePathView.stringValue stringByReplacingOccurrencesOfString:@"FilePath:" withString:@""];
    if ([FileManager cw_isFileExistAtPath:file]) {
        [FileManager cw_openFileWithPath:file.stringByDeletingLastPathComponent];
    }
}


-(void)viewWillDisappear{
    [super viewWillDisappear];
    self.textView.string = @"";
    self.filePathView.stringValue = @"";
    self.contentStr = @"";
    self.contentFailStr = @"";
}
-(void)viewWillAppear{
    [super viewWillAppear];

    if (self.textLogPath.length) {
        self.filePathView.stringValue = [NSString stringWithFormat:@"FilePath:%@",self.textLogPath];
        self.contentStr = [FileManager cw_readFromFile:self.textLogPath];
//        [self.textView setString:self.contentStr];
        [self showFailOnly:self.btnFail];
        
    }
    
}

-(void)setContentStr:(NSString *)contentStr{
    _contentStr = contentStr;
    if (contentStr.length) {
        NSMutableString*failStr = [[NSMutableString alloc]init];
        NSMutableArray*contentArr = [contentStr cw_regularWithPattern:@"(.+)"];
        for (int i =0; i<contentArr.count; i++) {
            NSArray *arr = contentArr[i];
            if (arr.count) {
                NSString *str =arr[0];
                if ([str.lowercaseString containsString:@"fail"]||[str.lowercaseString containsString:@"error"]) {
                    [failStr appendString:str];
                    [failStr appendString:@"\n"];
                }

            }
        }
        self.contentFailStr = failStr;
//        NSLog(@"11");
        
    }
    
}

- (IBAction)showFailOnly:(NSButton *)btn {
    if (btn.state == 1) {
        self.textView.string = self.contentFailStr;
    }else{
        self.textView.string = self.contentStr;
    }
}



//-(void)setTextLogPath:(NSString *)textLogPath{
//    self.textView.string = @"";
//    if (textLogPath.length) {
//        _textLogPath = textLogPath;
//        NSString *content = [FileManager cw_readFromFile:textLogPath];
//        [self.textView setString:content];
//
//
//    }
//}

@end
