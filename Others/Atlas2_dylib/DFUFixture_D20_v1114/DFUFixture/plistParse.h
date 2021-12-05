//
//  plistParse.h
//  DFUFixture
//
//  Created by IvanGan on 16/10/17.
//  Copyright © 2016年 IvanGan. All rights reserved.
//


#import <Foundation/Foundation.h>

#define kVENDER                 @"vender"
#define kSERIAL                 @"serial_number"
#define kVERSION                @"version"

#define kINIT                   @"init"
#define kRESET                  @"reset"
#define kUSBLOCATION            @"usb_location"
#define kUARTPATH               @"uart_path"
#define kUSBPOWERON             @"usb_power_on"
#define kUSBPOWEROFF            @"usb_power_off"
#define kBATTERYPOWERON         @"battery_power_on"
#define kBATTERYPOWEROFF        @"battery_power_off"
#define kUSBSIGNALON            @"usb_signal_on"
#define kUSBSIGNALOFF           @"usb_signal_off"
#define kUARTSIGNALON           @"uart_signal_on"
#define kUARTSIGNALOFF          @"uart_signal_off"
#define kAPPLEIDON              @"apple_id_on"
#define kAPPLEIDOFF             @"apple_id_off"
#define kCONNDETGNDON           @"conn_det_grounded_on"
#define kCONNDETGNDOFF          @"conn_det_grounded_off"
#define kHI5ON                  @"hi5_bs_grounded_on"
#define kHI5OFF                 @"hi5_bs_grounded_off"
#define kDUTPOWERON             @"dut_power_on"
#define kDUTPOWEROFF            @"dut_power_off"
#define kFORCEDFUON             @"force_dfu_on"
#define kFORCEDFUOFF            @"force_dfu_off"
#define kFORCEDIAGSON           @"force_diags_on"
#define kFORCEDIAGSOFF          @"force_diags_off"
#define kFORCEIBOOTON           @"force_iboot_on"
#define kFORCEIBOOTOFF          @"force_iboot_off"

#define kLEDSTATE               @"led_state"
#define kOFF                    @"off"
#define kPASS                   @"pass"
#define kFAIL                   @"fail"
#define kINPROCESS              @"inprocess"
#define kFAILGOTOFA             @"fail_goto_fa"
#define kPANIC                  @"panic"



#define kFIXTURESETTING         @"Fixture_Control_Setting"
#define kFIXTUREPORT            @"Fixture_Control_Port"
#define kFIXTURESLOTS           @"Fixture_Slots"



@interface plistParse : NSObject

+(NSDictionary*)parsePlist:(NSString *)file;
+(NSDictionary *)readAllCmdsWithFile:(NSString *)file;

@end
