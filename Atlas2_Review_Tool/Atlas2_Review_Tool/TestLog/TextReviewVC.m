//
//  TextReviewVC.m
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/11/22.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "TextReviewVC.h"

@interface TextReviewVC ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *filePathView;

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


//
-(void)viewDidAppear{
    [super viewDidAppear];
    self.textView.string = @"";
    self.filePathView.stringValue = @"";
    if (self.textLogPath.length) {
        self.filePathView.stringValue = [NSString stringWithFormat:@"FilePath:%@",self.textLogPath];
        NSString *content = [FileManager cw_readFromFile:self.textLogPath];
        [self.textView setString:content];
        
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
