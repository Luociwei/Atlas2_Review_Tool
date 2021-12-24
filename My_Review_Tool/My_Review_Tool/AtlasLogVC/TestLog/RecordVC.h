//
//  FailOnlyItems.h
//  My_Review_Tool
//
//  Created by ciwei luo on 2021/4/26.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ExtensionConst.h"
NS_ASSUME_NONNULL_BEGIN

@interface RecordVC : NSViewController
@property(nonatomic,strong)NSString *recordPath;
@property BOOL isFail;
@end

NS_ASSUME_NONNULL_END
