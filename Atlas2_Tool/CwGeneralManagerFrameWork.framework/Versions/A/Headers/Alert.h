//
//  MyEexception.h
//  MYAPP
//
//  Created by Zaffer.yang on 3/8/17.
//  Copyright © 2017 Zaffer.yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Alert : NSObject
+ (void)cw_RemindException: (NSString*)Title Information:(NSString*)info;
+ (void)cw_messageBox: (NSString*)Title Information:(NSString*)info;
+ (bool)cw_messageBoxYesNo: (NSString*)prompt;
+(bool)cw_messageBoxYesNo:(NSString *)prompt informativeText:(NSString *)informativeText;
+(NSString *)cw_passwordBox:(NSString *)prompt defaultValue:(NSString *)defaultValue;
@end
