//
//  MyEexception.m
//  MYAPP
//
//  Created by Zaffer.yang on 3/8/17.
//  Copyright © 2017 Zaffer.yang. All rights reserved.
//

#import "Alert.h"
#import <Cocoa/Cocoa.h>

@implementation Alert
// just remind the user, there are some error infomation.
+ (void)cw_RemindException: (NSString*)Title Information:(NSString*)info{
    NSAlert* alert = [[NSAlert alloc]init];
    [alert setMessageText:Title];
    [alert addButtonWithTitle:@"OK"];
    [alert setInformativeText:info];
    [alert runModal];
}

// just remind the user.
+ (void)cw_messageBox: (NSString*)Title Information:(NSString*)info{
    NSAlert* alert = [[NSAlert alloc]init];
    [alert setMessageText:Title];
    [alert setInformativeText:info];
    [alert runModal];
}

// just remind the user.
+(bool)cw_messageBoxYesNo:(NSString *)prompt {
    //NSAlert *alert = [NSAlert alertWithMessageText: prompt
    //                                 defaultButton:@"OK"
    //                               alternateButton:@"Cancel"
    //                                   otherButton:nil
    //                     informativeTextWithFormat:@""];
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setInformativeText:@""]; //sub text
    [alert setMessageText:prompt];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];

    NSInteger button = [alert runModal];
    
    return (button == NSAlertFirstButtonReturn);
}

+(bool)cw_messageBoxYesNo:(NSString *)prompt informativeText:(NSString *)informativeText{
    //NSAlert *alert = [NSAlert alertWithMessageText: prompt
    //                                 defaultButton:@"OK"
    //                               alternateButton:@"Cancel"
    //                                   otherButton:nil
    //                     informativeTextWithFormat:@""];
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setInformativeText:informativeText]; //sub text
    [alert setMessageText:prompt];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    
    NSInteger button = [alert runModal];
    
    return (button == NSAlertFirstButtonReturn);
}

+(NSString *)cw_passwordBox:(NSString *)prompt defaultValue:(NSString *)defaultValue {
    //NSAlert *alert = [NSAlert alertWithMessageText: prompt
    //                                 defaultButton:@"OK"
    //                               alternateButton:@"Cancel"
    //                                   otherButton:nil
    //                     informativeTextWithFormat:@""];
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setInformativeText:@"Enter Password:"];
    [alert setMessageText:prompt];
    [alert addButtonWithTitle:@"Ok"];
    [alert addButtonWithTitle:@"Cancel"];
    NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:defaultValue];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {
        [input validateEditing];
        return [input stringValue];
    } else {
        return nil;
    }
}

@end
