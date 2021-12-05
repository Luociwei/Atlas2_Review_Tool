//
//  plistParse.h
//  FCTFixture
//
//  Created by RyanGao on 2020/10/02.
//  Copyright © 2020年 RyanGao. All rights reserved.
//


#import <Foundation/Foundation.h>

#define kVENDER                 @"vender"
#define kSERIAL                 @"serial_number"
#define kVERSION                @"version"
#define kFIXTUREHWLog           @"Fixture_HW_Log"
#define kFIXTUREPORT            @"Fixture_Control_Port"
#define kFIXTURESLOTS           @"Fixture_Slots"

#define kINIT                   @"init"
#define kRESET                  @"reset"
#define kFrequency              @"frequency"

#define kvdm_read_serial_number      @"vdm_read_serial_number"
#define keload_read_serial_number    @"eload_read_serial_number"
#define kscope_read_serial_number    @"scope_read_serial_number"
#define koab3_read_serial_number     @"oab3_read_serial_number"
#define kget_xavier_ip               @"get_xavier_ip"
#define kuart_enable                 @"uart_enable"
#define kbellatrix_uart_enable       @"bellatrix_uart_enable"
#define kchange_vdm_pdo_to_1         @"change_vdm_pdo_to_1"
#define kchange_vdm_pdo_to_2         @"change_vdm_pdo_to_2"
#define k5v_to_vdm_exit              @"5v_to_vdm_exit"
#define kchange_pdo2_to_9v2a         @"change_pdo2_to_9v2a"
#define kchange_pdo_count_to_5       @"change_pdo_count_to_5"
#define kdisable_usb_cable           @"disable_usb_cable"
#define kace_reset_h                 @"ace_reset_h"
#define kace_reset_l                 @"ace_reset_l"
#define kace_programmer_id           @"ace_programmer_id"

#define kace_programmer_erase_mx25v16  @"ace_programmer_erase_mx25v16"
#define kace_programmer_erase_gd25xxx  @"ace_programmer_erase_gd25xxx"
#define kace_programmer_erase_w25q128  @"ace_programmer_erase_w25q128"

#define kace_programmer_only_gd25xxx           @"ace_programmer_only_gd25xxx"
#define kace_programmer_only_w25q128           @"ace_programmer_only_w25q128"
#define kace_programmer_only_mx25v16           @"ace_programmer_only_mx25v16"
#define keload_enable1                 @"eload_enable1"
#define keload_disable1                @"eload_disable1"
#define keload_set_1_cc_200            @"eload_set_1_cc_200"
#define keload_set_1_cc_0              @"eload_set_1_cc_0"
#define kace_program_readverify        @"ace_program_readverify"

@interface plistParse : NSObject

+(NSDictionary*)parsePlist:(NSString *)file;
+(NSDictionary *)readAllCMD;
+(void)checkLogFileExist:(NSString *)filePath;
+(void)writeLog2File:(NSString *)filePath withTime:(NSString *) testTime andContent:(NSString *)str;

@end
