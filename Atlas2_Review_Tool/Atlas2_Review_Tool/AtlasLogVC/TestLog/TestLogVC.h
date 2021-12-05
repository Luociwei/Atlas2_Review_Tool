//
//  TestLogVC.h
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/11/22.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ExtensionConst.h"
#import "RecordVC.h"
NS_ASSUME_NONNULL_BEGIN

@interface TestLogVC : TabViewController
@property(nonatomic,strong)NSString *recordPath;
@property BOOL isFail;
@end

NS_ASSUME_NONNULL_END
