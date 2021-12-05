//
//  Calibration.m
//  FCTFixture
//
//  Created by gdlocal on 2021/8/23.
//  Copyright © 2021 RyanG. All rights reserved.
//

#import "Calibration.h"

NSMutableDictionary *dic_value = nil;

@implementation Calibration

+(NSDictionary *)readCalAddress
{
    if (!dic_value)
    {
        dic_value = [[NSMutableDictionary alloc] init];
    }
    
    NSDictionary *dic = @{
        @"ai1_voltage_reading_5_200_mV"                           :@"0x0000",
        @"ai2_voltage_reading_5_200_mV"                           :@"0x0010",
        @"ai3_voltage_reading_5_200_mV"                           :@"0x0020",
        @"ai4_voltage_reading_5_200_mV"                           :@"0x0030",
        @"ai5_voltage_reading_5_200_mV"                           :@"0x0040",
        @"ai6_voltage_reading_5_200_mV"                           :@"0x0050",
        @"ai7_voltage_reading_5_200_mV"                           :@"0x0060",
        @"batt_voltage_setting_5_200_mV"                          :@"0x0070",
        @"ai1_voltage_reading_200_4500_mV"                        :@"0x0080",
        @"ai2_voltage_reading_200_4500_mV"                        :@"0x0090",
        @"ai3_voltage_reading_200_4500_mV"                        :@"0x00A0",
        @"ai4_voltage_reading_200_4500_mV"                        :@"0x00B0",
        @"ai5_voltage_reading_200_4500_mV"                        :@"0x00C0",
        @"ai6_voltage_reading_200_4500_mV"                        :@"0x00D0",
        @"ai7_voltage_reading_200_4500_mV"                        :@"0x00F0",
        @"batt_voltage_setting_200_4500_mV"                       :@"0x0100",
        @"ai8_voltage_reading_3000_17000_mV"                      :@"0x0260",
        @"vbus_voltage_setting"                                   :@"0x0270",
        @"ibatt_1_10_ma"                                          :@"0x0280",
        @"ibatt_10_500_ma"                                        :@"0x0290",
        @"ibatt_500_1000_ma"                                      :@"0x02A0",
        @"ibatt_1000_1500_ma"                                     :@"0x02B0",
        @"ibatt_1500_2500_ma"                                     :@"0x02C0",
        @"ibus_1_10_ma"                                           :@"0x0300",
        @"ibus_10_700_ma"                                         :@"0x0310",
        @"ibus_700_1300_ma"                                       :@"0x0320",
        @"ibus_1300_1950_ma"                                      :@"0x0330",
        @"ibus_1950_2500_ma"                                      :@"0x0340",
        @"eload1_setting_1_10_ma"                                 :@"0x0400",
        @"eload1_setting_10_700_ma"                               :@"0x0410",
        @"eload1_setting_700_1300_ma"                             :@"0x0420",
        @"eload1_setting_1300_1950_ma"                            :@"0x0430",
        @"eload1_setting_1950_2500_ma"                            :@"0x0440",
        @"eload1_reading_1_10_ma"                                 :@"0x0500",
        @"eload1_reading_10_700_ma"                               :@"0x0510",
        @"eload1_reading_700_1300_ma"                             :@"0x0520",
        @"eload1_reading_1300_1950_ma"                            :@"0x0530",
        @"eload1_reading_1950_2500_ma"                            :@"0x0540",
        @"eload2_setting_1_10_ma"                                 :@"0x0600",
        @"eload2_setting_10_700_ma"                               :@"0x0610",
        @"eload2_setting_700_1300_ma"                             :@"0x0620",
        @"eload2_setting_1300_1950_ma"                            :@"0x0630",
        @"eload2_setting_1950_2500_ma"                            :@"0x0640",
        @"eload2_reading_1_10_ma"                                 :@"0x0650",
        @"eload2_reading_10_700_ma"                               :@"0x0660",
        @"eload2_reading_700_1300_ma"                             :@"0x0670",
        @"eload2_reading_1300_1950_ma"                            :@"0x0680",
        @"eload2_reading_1950_2500_ma"                            :@"0x0690",
        @"target_5V_current_1_10_ma"                              :@"0x0700",
        @"target_5V_current_10_160_ma"                            :@"0x0710",
        @"target_5V_current_160_700_ma"                           :@"0x0720",
        @"target_5V_current_700_1800_ma"                          :@"0x0730",
        @"target_5V_current_1000_2500_ma"                         :@"0x0740",
        @"target_9V_current_1_10_ma"                              :@"0x0750",
        @"target_9V_current_10_160_ma"                            :@"0x0760",
        @"target_9V_current_160_700_ma"                           :@"0x0770",
        @"target_9V_current_700_1800_ma"                          :@"0x0780",
        @"target_9V_current_1000_2500_ma"                         :@"0x0790",
        @"target_12V_current_1_10_ma"                             :@"0x07A0",
        @"target_12V_current_10_160_ma"                           :@"0x07B0",
        @"target_12V_current_160_700_ma"                          :@"0x07C0",
        @"target_12V_current_700_1800_ma"                         :@"0x07D0",
        @"target_12V_current_1000_2000_ma"                        :@"0x07F0",
        @"target_15V_current_1_10_ma"                             :@"0x0800",
        @"target_15V_current_10_160_ma"                           :@"0x0810",
        @"target_15V_current_160_700_ma"                          :@"0x0820",
        @"target_15V_current_700_1400_ma"                         :@"0x0830",
        @"target_15V_current_1000_1400_ma"                        :@"0x0840",
        @"vpp_reading"                                            :@"0x0950",
        @"ADC_A_Zero_reading"                                     :@"0x0960",
        @"ADC_B_Zero_reading"                                     :@"0x0970",
        @"ADC_C_Zero_reading"                                     :@"0x0980",
        @"ADC_D_Zero_reading"                                     :@"0x0990",
        @"ADC_E_Zero_reading"                                     :@"0x09A0",
        @"ADC_F_Zero_reading"                                     :@"0x09B0",
        @"ADC_G_Zero_reading"                                     :@"0x09C0",
        @"ADC_H_Zero_reading"                                     :@"0x09D0",
        @"neg_current_setting_10_100_ua"                          :@"0x0A10",
        @"neg_current_setting_500_2000_ua"                        :@"0x0A20",
        @"neg_current_setting_3000_20000_ua"                      :@"0x0A30",
        @"neg_current_reading_10_100_ua"                          :@"0x0A40",
        @"neg_current_reading_500_2000_ua"                        :@"0x0A50",
        @"neg_current_reading_3000_20000_ua"                      :@"0x0A60",
        @"fixture_base_sn"                                        :@"0x0A70",
    };
    
    return dic;
}

+ (void)writeCalibrationData:(NSString *)strContent atSite:(int)site;
{
    NSDateFormatter* DateFomatter = [[NSDateFormatter alloc] init];
    [DateFomatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS "];
    NSString* timeFlag = [DateFomatter stringFromDate:[NSDate date]];

    NSString * filePath = [NSString stringWithFormat:@"/tmp/FCT_calibration_Suncode_uut%d.txt",site];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isExist = [fm fileExistsAtPath:filePath];
    if (!isExist)
    {
         BOOL ret = [fm createFileAtPath:filePath contents:nil attributes:nil];
         if (ret)
         {
             NSLog(@"create file is successful");
         }
         
    }
    NSFileHandle* fh=[NSFileHandle fileHandleForWritingAtPath:filePath];
    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@  %@\r\n",timeFlag,strContent] dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

+ (NSString *)get_channel:(NSString *)str
{
    str = [str stringByReplacingOccurrencesOfString:@"\'" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *pattern = @"CH:\\w*";
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *results = [regular matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSString *ret = nil;
    for (NSTextCheckingResult *result in results)
    {
        ret = [str substringWithRange:NSMakeRange(result.range.location+4, result.range.length-4)];
        break;
    }
    return ret;
}

+ (float)cal_ai1_8_factor:(NSDictionary *)dic content:(NSString *)content value:(float)value site:(int)site
{
    NSString *channel = [self get_channel:content];
    if (!channel)
    {
        return value;
    }
    float k = 1;
    float r = 0;
    if ([[channel uppercaseString] isEqualToString:@"AI8"])
    {
        @try
        {
            NSString *key_k = [NSString stringWithFormat:@"ai8_voltage_reading_3000_17000_mV_k_%d",site];
            NSString *key_r = [NSString stringWithFormat:@"ai8_voltage_reading_3000_17000_mV_r_%d",site];
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
        @catch (NSException *exception)
        {
            k = 1;
            r = 0;
            
        }
        
    }
    else
    {
        if (value<200)
        {
            @try
            {
                NSString *key_k = [NSString stringWithFormat:@"%@_voltage_reading_5_200_mV_k_%d",[channel lowercaseString],site];
                NSString *key_r = [NSString stringWithFormat:@"%@_voltage_reading_5_200_mV_r_%d",[channel lowercaseString],site];
                if (dic[key_k])
                {
                    k = [dic[key_k] floatValue];
                }
                if (dic[key_r])
                {
                    r = [dic[key_r] floatValue];
                }
            }
           
            @catch (NSException *exception)
            {
                k = 1;
                r = 0;
            }
            
        }
        else
        {
            @try
            {
                NSString *key_k = [NSString stringWithFormat:@"%@_voltage_reading_200_4500_mV_k_%d",[channel lowercaseString],site];
                NSString *key_r = [NSString stringWithFormat:@"%@_voltage_reading_200_4500_mV_r_%d",[channel lowercaseString],site];
                if (dic[key_k])
                {
                    k = [dic[key_k] floatValue];
                }
                if (dic[key_r])
                {
                    r = [dic[key_r] floatValue];
                }
            }
            @catch (NSException *exception)
            {
                k = 1;
                r = 0;
            }
            
            
            
        }
    }
    
    //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
    return  value * k + r;
}


+ (float)cal_target_current_factor:(NSDictionary *)dic level:(NSString *)level value:(float)value site:(int)site
{
    
    NSString *key_k = nil;
    NSString *key_r = nil;
    if (value<10)
    {
        key_k = [NSString stringWithFormat:@"target_%@_current_1_10_ma_k_%d",level,site];
        key_r = [NSString stringWithFormat:@"target_%@_current_1_10_ma_r_%d",level,site];
        
    }
    else if (value>=10 && value<160)
    {
        key_k = [NSString stringWithFormat:@"target_%@_current_10_160_ma_k_%d",level,site];
        key_r = [NSString stringWithFormat:@"target_%@_current_10_160_ma_r_%d",level,site];
        
    }
    else if (value>=160 && value<=700)
    {
        key_k = [NSString stringWithFormat:@"target_%@_current_160_700_ma_k_%d",level,site];
        key_r = [NSString stringWithFormat:@"target_%@_current_160_700_ma_r_%d",level,site];
        
    }
    else if (value>700 && value<=1600)
    {
        if ([level isEqualToString:@"15V"])
        {
            key_k = [NSString stringWithFormat:@"target_%@_current_700_1400_ma_k_%d",level,site];
            key_r = [NSString stringWithFormat:@"target_%@_current_700_1400_ma_r_%d",level,site];
        }
        else
        {
            key_k = [NSString stringWithFormat:@"target_%@_current_700_1800_ma_k_%d",level,site];
            key_r = [NSString stringWithFormat:@"target_%@_current_700_1800_ma_r_%d",level,site];
        }
        
    }
    else if (value>1600)
    {
        if ([level isEqualToString:@"15V"])
        {
            key_k = [NSString stringWithFormat:@"target_%@_current_1000_1400_ma_k_%d",level,site];
            key_r = [NSString stringWithFormat:@"target_%@_current_1000_1400_ma_r_%d",level,site];
        }
        else if ([level isEqualToString:@"12V"])
        {
            key_k = [NSString stringWithFormat:@"target_%@_current_1000_2000_ma_k_%d",level,site];
            key_r = [NSString stringWithFormat:@"target_%@_current_1000_2000_ma_r_%d",level,site];
        }
        else if ([level isEqualToString:@"9V"])
        {
            key_k = [NSString stringWithFormat:@"target_%@_current_1000_2500_ma_k_%d",level,site];
            key_r = [NSString stringWithFormat:@"target_%@_current_1000_2500_ma_r_%d",level,site];
            
        }
        else if ([level isEqualToString:@"5V"])
        {
            key_k = [NSString stringWithFormat:@"target_%@_current_1000_2500_ma_k_%d",level,site];
            key_r = [NSString stringWithFormat:@"target_%@_current_1000_2500_ma_r_%d",level,site];
            
        }
        
    }
    
    float k = 1;
    float r = 0;
    
    @try
    {
        if (key_k && key_r)
        {
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
    return value * k + r;
}


+ (float)cal_ibatt_factor:(NSDictionary *)dic value:(float)value site:(int)site
{
     NSString *key_k = nil;
     NSString *key_r = nil;
     if(value > 0 && value <= 25)
     {
         key_k = [NSString stringWithFormat:@"ibatt_1_10_ma_k_%d",site];
         key_r = [NSString stringWithFormat:@"ibatt_1_10_ma_r_%d",site];
     }
    else if (value > 25 && value <= 500)
    {
        key_k = [NSString stringWithFormat:@"ibatt_10_500_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibatt_10_500_ma_r_%d",site];
        
    }
     else if (value > 500 && value <= 1000)
     {
         key_k = [NSString stringWithFormat:@"ibatt_500_1000_ma_k_%d",site];
         key_r = [NSString stringWithFormat:@"ibatt_500_1000_ma_r_%d",site];
     }
    else if (value > 1000 && value <= 1500)
    {
        key_k = [NSString stringWithFormat:@"ibatt_1000_1500_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibatt_1000_1500_ma_r_%d",site];
        
    }
    else if (value > 1500 )
    {
        key_k = [NSString stringWithFormat:@"ibatt_1500_2500_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibatt_1500_2500_ma_r_%d",site];
    }
    
    float k = 1;
    float r = 0;
    
    @try
    {
        
        if (key_k && key_r)
        {
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    
       //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
       return value * k + r;
}


+ (float)cal_ibus_factor:(NSDictionary *)dic value:(float)value site:(int)site
{
    NSString *key_k = nil;
    NSString *key_r = nil;
    if(value > 0 && value <= 10)
    {
        key_k = [NSString stringWithFormat:@"ibus_1_10_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibus_1_10_ma_r_%d",site];
    }
    if(value > 10 && value <= 700)
    {
        key_k = [NSString stringWithFormat:@"ibus_10_700_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibus_10_700_ma_r_%d",site];
        
    }
    if(value > 700 && value <= 1300)
    {
        key_k = [NSString stringWithFormat:@"ibus_700_1300_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibus_700_1300_ma_r_%d",site];
        
    }
    if(value > 1300 && value <= 1950)
    {
        key_k = [NSString stringWithFormat:@"ibus_1300_1950_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibus_1300_1950_ma_r_%d",site];
        
    }
    if(value > 1950)
    {
        key_k = [NSString stringWithFormat:@"ibus_1950_2500_ma_k_%d",site];
        key_r = [NSString stringWithFormat:@"ibus_1950_2500_ma_r_%d",site];
           
    }
    
    float k = 1;
    float r = 0;
    @try
    {
        if (key_k && key_r)
        {
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
    return value * k + r;
}

+ (float)vbatt_set_with_cal_factor:(NSDictionary *)dic value:(float)value site:(int)site
{
    NSString *key_k = nil;
    NSString *key_r = nil;
    if(value < 200)
    {
        key_k = [NSString stringWithFormat:@"batt_voltage_setting_5_200_mV_k_%d",site];
        key_r = [NSString stringWithFormat:@"batt_voltage_setting_5_200_mV_r%d",site];
    }
    else
    {
        key_k = [NSString stringWithFormat:@"batt_voltage_setting_200_4500_mV_k_%d",site];
        key_r = [NSString stringWithFormat:@"batt_voltage_setting_200_4500_mV_r_%d",site];
    }
    
    float k = 1;
    float r = 0;
    
    @try
    {
        if (key_k && key_r)
        {
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    return value * k + r;
}

+ (float)usb_set_with_cal_factor:(NSDictionary *)dic value:(float)value site:(int)site
{
    NSString *key_k = [NSString stringWithFormat:@"vbus_voltage_setting_k_%d",site];
    NSString *key_r = [NSString stringWithFormat:@"vbus_voltage_setting_r_%d",site];
    
    float k = 1;
    float r = 0;
    
    @try
    {
        if (key_k && key_r)
        {
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
    return value * k + r;
    
}

+ (float)cal_eload_set_factor:(NSDictionary *)dic channel:(int)channel value:(float)value site:(int)site
{
    float k = 1;
    float r = 0;
    NSString *key_k = nil;
    NSString *key_r = nil;
    
    if (value == 0)
    {
        k = 1;
        r = 0;
        
    }
    else if (value <= 10)
    {
        key_k = [NSString stringWithFormat:@"eload%d_setting_1_10_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_setting_1_10_ma_r_%d",channel,site];
    }
     else if (value >10 && value <=700)
     {
         key_k = [NSString stringWithFormat:@"eload%d_setting_10_700_ma_k_%d",channel,site];
         key_r = [NSString stringWithFormat:@"eload%d_setting_10_700_ma_r_%d",channel,site];
     }
    else if (value >700 && value <= 1300)
    {
        key_k = [NSString stringWithFormat:@"eload%d_setting_700_1300_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_setting_700_1300_ma_r_%d",channel,site];
    }
    else if (value >1300 && value <= 1950)
    {
        key_k = [NSString stringWithFormat:@"eload%d_setting_1300_1950_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_setting_1300_1950_ma_r_%d",channel,site];
        
    }
    else if (value > 1950)
    {
        key_k = [NSString stringWithFormat:@"eload%d_setting_1950_2500_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_setting_1950_2500_ma_r_%d",channel,site];
    }
    
    @try
    {
        if (key_k && key_r)
        {
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
    
    if (value * k + r <=0)
    {
        return 0;
    }
    return value * k + r;
    
}

+ (float)cal_eload_read_factor:(NSDictionary *)dic channel:(int)channel value:(float)value site:(int)site
{
    NSString *key_k = nil;
    NSString *key_r = nil;
    
    if (value <= 10)
    {
        key_k = [NSString stringWithFormat:@"eload%d_reading_1_10_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_reading_1_10_ma_r_%d",channel,site];
    }
    else if (value >10 && value <=700)
    {
        key_k = [NSString stringWithFormat:@"eload%d_reading_10_700_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_reading_10_700_ma_r_%d",channel,site];
    }
    else if (value >700 && value <= 1300)
    {
        key_k = [NSString stringWithFormat:@"eload%d_reading_700_1300_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_reading_700_1300_ma_r_%d",channel,site];
    }
    else if (value >1300 && value <= 1950)
    {
        key_k = [NSString stringWithFormat:@"eload%d_reading_1300_1950_ma_k_%d",channel,site];
        key_r = [NSString stringWithFormat:@"eload%d_reading_1300_1950_ma_r_%d",channel,site];
    }
    else if (value >1950)
      {
          key_k = [NSString stringWithFormat:@"eload%d_reading_1950_2500_ma_k_%d",channel,site];
          key_r = [NSString stringWithFormat:@"eload%d_reading_1950_2500_ma_r_%d",channel,site];
      }
    
    float k = 1;
    float r = 0;
    
    @try
    {
        if (key_k && key_r)
        {
            if (dic[key_k])
            {
                k = [dic[key_k] floatValue];
            }
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
    return value * k + r;
    
}

+ (float)cal_ADC_zero_read_factor:(NSDictionary *)dic content:(NSString *)content value:(float)value site:(int)site
{
    NSString *channel = [self get_channel:content];
    if (!channel)
    {
        return value;
    }
    NSString *ch = nil;
    if ([channel isEqualToString:@"AI1"])
    {
        ch = @"A";
    }
    else if ([channel isEqualToString:@"AI2"])
    {
        ch = @"B";
    }
    else if ([channel isEqualToString:@"AI3"])
    {
        ch = @"C";
    }
    else if ([channel isEqualToString:@"AI4"])
    {
        ch = @"D";
    }
    else if ([channel isEqualToString:@"AI5"])
    {
        ch = @"E";
    }
    else if ([channel isEqualToString:@"AI6"])
    {
        ch = @"F";
    }
    else if ([channel isEqualToString:@"AI7"])
    {
        ch = @"G";
    }
    else if ([channel isEqualToString:@"AI8"])
    {
        ch = @"H";
    }
    
    NSString *key_r = [NSString stringWithFormat:@"ADC_%@_Zero_reading_r_%d",ch,site];
    
    float k = 1;
    float r = 0;
    
    @try
    {
        if (key_r)
        {
            if (dic[key_r])
            {
                r = [dic[key_r] floatValue];
            }
        }
    }
    @catch (NSException *exception)
    {
        k = 1;
        r = 0;
    }
    
    
    //[self writeCalibrationData:[NSString stringWithFormat:@"[factor] k: %f ; r: %f ",k,r] atSite:site];
    return value * k - r;
    
}

@end
