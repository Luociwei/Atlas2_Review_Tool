//
//  ProgressBarVC.m
//  Atlas2_Analysis_Tool
//
//  Created by ciwei luo on 2021/11/20.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "ProgressBarVC.h"

@interface ProgressBarVC ()
@property (weak) IBOutlet NSProgressIndicator *ProgressBar;

@property (weak) IBOutlet NSTextField *LableInfo;

@end

@implementation ProgressBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
//    self.ProgressBar.doubleValue = 10;
    
    [self setProgressBarDoubleValue:0 info:@"Pls wait!"];
}

-(void)setProgressBarDoubleValue:(float)doubleVaule info:(NSString *)info{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (doubleVaule>0) {
                _ProgressBar.doubleValue = (double)doubleVaule;
                
            }
            if (info.length) {
                _LableInfo.stringValue = [NSString stringWithFormat:@"Loading....%@",info];
            }
        });
//    });

    
    return ;
}

@end
