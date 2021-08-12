//
//  OC_Regular.m
//  Atlas2_Analysis_Tool
//
//  Created by ciwei luo on 2021/6/22.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "OC_Regular.h"

@interface OC_Regular ()
@property (unsafe_unretained) IBOutlet NSTextView *resultVIew;

@property (unsafe_unretained) IBOutlet NSTextView *ContentView;


@property (weak) IBOutlet NSTextField *PatternView;

@end

@implementation OC_Regular

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    NSString *ret = @"sssfffsfsdasCHECKPOINT END: (null):[0x1309] provision_ace2fssdfaa";
    //    NSString *ret = @"current FW files is :nandfs:diag-pallas-41.09.50.bin";
    NSString *apattern = @"CHECKPOINT END: (null):%[.+%] provision_ace2";
    //        NSString *ret = @"08.882002          0000000: 00 00 20 00";
    //        NSString *apattern = @"\\d+:\\s+(\\d+\\s+\\d+\\s+\\d+\\s+\\d+)";
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:apattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *results = [regular matchesInString:ret options:0 range:NSMakeRange(0,ret.length)];
    NSString *Version=@"";
    for (NSTextCheckingResult *result in results) {
        NSInteger num = result.numberOfRanges;
        Version =[Version stringByAppendingString:[ret substringWithRange:[result rangeAtIndex:1]]];
    }
    
}


//- (IBAction)patternClick:(NSButton *)sender {
//    NSString *ret = self.resultVIew.string;
//    //    NSString *ret = @"current FW files is :nandfs:diag-pallas-41.09.50.bin";
//    NSString *apattern =self.PatternView.string;
//    //        NSString *ret = @"08.882002          0000000: 00 00 20 00";
//    //        NSString *apattern = @"\\d+:\\s+(\\d+\\s+\\d+\\s+\\d+\\s+\\d+)";
//    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:apattern options:NSRegularExpressionCaseInsensitive error:nil];
//    NSArray *results = [regular matchesInString:ret options:0 range:NSMakeRange(0,ret.length)];
//    NSString *Version=@"";
//    for (NSTextCheckingResult *result in results) {
//        NSInteger num = result.numberOfRanges;
//        Version =[Version stringByAppendingString:[ret substringWithRange:[result rangeAtIndex:1]]];
//    }
//}


@end
