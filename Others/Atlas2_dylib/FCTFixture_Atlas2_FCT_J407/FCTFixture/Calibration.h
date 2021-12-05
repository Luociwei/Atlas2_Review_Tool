//
//  Calibration.h
//  FCTFixture
//
//  Created by gdlocal on 2021/8/23.
//  Copyright © 2021 RyanG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Calibration : NSObject

+ (NSDictionary *)readCalAddress;
+ (void)writeCalibrationData:(NSString *)strContent atSite:(int)site;

+ (float)cal_ai1_8_factor:(NSDictionary *)dic content:(NSString *)content value:(float)value site:(int)site;
+ (float)cal_target_current_factor:(NSDictionary *)dic level:(NSString *)level value:(float)value site:(int)site;
+ (float)cal_ibatt_factor:(NSDictionary *)dic value:(float)value site:(int)site;
+ (float)cal_ibus_factor:(NSDictionary *)dic value:(float)value site:(int)site;
+ (float)vbatt_set_with_cal_factor:(NSDictionary *)dic value:(float)value site:(int)site;
+ (float)usb_set_with_cal_factor:(NSDictionary *)dic value:(float)value site:(int)site;
+ (float)cal_eload_set_factor:(NSDictionary *)dic channel:(int)channel value:(float)value site:(int)site;
+ (float)cal_eload_read_factor:(NSDictionary *)dic channel:(int)channel value:(float)value site:(int)site;
+ (float)cal_ADC_zero_read_factor:(NSDictionary *)dic content:(NSString *)content value:(float)value site:(int)site;

@end

NS_ASSUME_NONNULL_END
