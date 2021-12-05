//
//  FCTFixture.m
//  FCTFixture
//
//  Created by RyanGao on 2020/10/02.
//  Copyright © 2020年 RyanGao. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "plistParse.h"
#import "USBDevice.h"
#import "FCTFixture.h"
#import "RPCController.h"
#import "Calibration.h"

#define add_calibration 1

int g_SLOTS = 0;
BOOL g_out_flag  = NO;
BOOL g_auto_flag = YES;
dispatch_queue_t g_queue = NULL;

NSMutableDictionary * cmdDic = NULL;
NSMutableDictionary * globalDic = NULL;


//***********calibration function start

int read_calibration_data(void* controller, int site)
{
    #ifdef add_calibration
    RPCController *fixture = (__bridge RPCController *)controller;
    NSDictionary *calAddr = [Calibration readCalAddress];
    
    for (NSString *strKey in [calAddr allKeys])
    {
        NSString *eeprom_cmd = [NSString stringWithFormat:@"eeprom.read(testbase,cat32,%@,16)",calAddr[strKey]];
        NSString *ret = [fixture WriteReadString:eeprom_cmd atSite:site-1 timeOut:5000];
        [Calibration writeCalibrationData:[NSString stringWithFormat:@"[cmd - uut%d]: %@\r\n[result - uut%d]: %@\r\n",site,eeprom_cmd,site,ret]];
        float k = [[fixture stringMatch:ret withCount:0] floatValue];
        if (k<=0.95|| k>=1.05){ k=1;}
        float r = [[fixture stringMatch:ret withCount:1] floatValue];
        
        NSString *key_k = [NSString stringWithFormat:@"%@_k_%d",strKey,site];
        NSString *key_r = [NSString stringWithFormat:@"%@_r_%d",strKey,site];
        [globalDic setValue:[NSNumber numberWithFloat:k] forKey:key_k];
        [globalDic setValue:[NSNumber numberWithFloat:r] forKey:key_r];
        
        NSString *cal_data = [NSString stringWithFormat:@"[uut%d]:\r\n%@:%f\r\n%@:%f\r\n",site,key_k,k,key_r,r];
        [Calibration writeCalibrationData:cal_data];
    }
    #endif
    return 0;
}

//***********calibration function end

void writeFixtureLog(NSString *strContent,int i)
{
    NSDateFormatter* DateFomatter = [[NSDateFormatter alloc] init];
    [DateFomatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS "];
    NSString* timeFlag = [DateFomatter stringFromDate:[NSDate date]];

    NSString * pathLogFile = [[cmdDic objectForKey:kFIXTUREHWLog] objectForKey:[NSString stringWithFormat:@"UUT%d",i]];
    if (pathLogFile)
    {
        [plistParse checkLogFileExist:pathLogFile];
        [plistParse writeLog2File:pathLogFile withTime:timeFlag andContent:strContent];
    }
        
}


void create_global_object(RPCController* controller)
{
    
    if (!g_queue)
    {
        g_queue = dispatch_queue_create("com.FCTFixture.global_queue", DISPATCH_QUEUE_SERIAL);

    }
}

void* create_fixture_controller(int index)
{
    writeFixtureLog([NSString stringWithFormat:@"create_fixture_controller start,index : %d\r\n",index],0);
    if(cmdDic)
    {
        [cmdDic removeAllObjects];
    }
    else
    {
        cmdDic = [[NSMutableDictionary alloc]init];
       
    }
    
    if (globalDic)
    {
        [globalDic removeAllObjects];
    }
    else
    {
         globalDic = [[NSMutableDictionary alloc]init];
    }
    
    
    [cmdDic setDictionary:[plistParse readAllCMD]];
    writeFixtureLog([NSString stringWithFormat:@"cmdDic:%@\r\n",[NSString stringWithFormat:@"%@",cmdDic]],0);
    if([cmdDic count]>0)
    {
        g_SLOTS = [[cmdDic objectForKey:kFIXTURESLOTS]intValue];
    }
    if (g_SLOTS<1)
    {
        return nil;
    }
    NSMutableArray *ipPorts = [NSMutableArray array];
    for (int i=0; i<g_SLOTS; i++)
    {
        NSString * ipPort = [[cmdDic objectForKey:kFIXTUREPORT] objectForKey:[NSString stringWithFormat:@"UUT%d",i]];
        [ipPorts addObject:ipPort];
    }
    writeFixtureLog([NSString stringWithFormat:@"create_fixture_controller , ip: %@, index : %d\r\n",ipPorts,index],index-1);
    RPCController *controller = [[RPCController alloc] initWithSlots:g_SLOTS withAddr:ipPorts];
    create_global_object(controller);
    
    return (__bridge_retained void *)controller;
}

void release_fixture_controller(void* controller)
{
    system("pkill -9 virtualport");
    system("pkill -9 usbfs");
    system("pkill -9 usbfs-2.4.20");
    if(cmdDic)
    {
        [cmdDic removeAllObjects];
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    for (int i=0; i<4; i++) {
        [fixture uartShutdown:i];
    }
    [fixture Close];
    
}


/////////////////////////////////////////////////////

int executeAction(void *controller,NSString * key, int site)
{
    if(site<1)
        return -1;

    RPCController *fixture = (__bridge RPCController *)controller;
    id list = [cmdDic objectForKey:key];
    if ([list isEqual:@[@""]] || [list isEqual:@""] || list == NULL)
    {
        return 0;
    }
    NSArray * arr = [cmdDic objectForKey:key];
    for (int j=0; j<[arr count]; j++)
    {
        NSString *subCmd =[arr objectAtIndex:j];
        if ([[subCmd uppercaseString] containsString:@"DELAY:"])
        {
            NSArray *arryDelay=[[arr objectAtIndex:j] componentsSeparatedByString:@":"];
             if ([[arryDelay[0] uppercaseString] isEqual:@"DELAY"])
             {
                 [NSThread sleepForTimeInterval:[arryDelay[1] doubleValue]];
             }
        }
        else if (![subCmd length]){
            continue;
        }
        else
        {
            NSString *ret = [fixture WriteReadString:subCmd atSite:site-1 timeOut:6000];
            if (j==[arr count]-1)
            {
                writeFixtureLog([NSString stringWithFormat:@"[cmd] %@, [result] %@\r\n",[arr objectAtIndex:j],ret],site-1);
            }
            else
            {
                writeFixtureLog([NSString stringWithFormat:@"[cmd] %@, [result] %@",[arr objectAtIndex:j],ret],site-1);
            }
            
        }
        
    }
    return 0;
}
///////////////////////////////


const char * executeRpcAction(void *controller,NSString * strCmd, int timeout,int site)
{
    if(site<1)
    {
       writeFixtureLog([NSString stringWithFormat:@"[cmd] %@, [result] Err: site<1\r\n",strCmd],site-1);
       return "Err: site<1";
    }
    RPCController *fixture = (__bridge RPCController *)controller;

    if([strCmd length]<1)
    {
        writeFixtureLog([NSString stringWithFormat:@"[cmd] %@, [result] Err: cmd is empty\r\n",strCmd],site-1);
        return "Err: cmd is empty";
    }

    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:timeout];
    ret = [ret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    writeFixtureLog([NSString stringWithFormat:@"[cmd] %@, [result] %@\r\n",strCmd,ret],site-1);
    return [ret UTF8String];
}

//////////////////////////////
int executeAllAction(void *controller,NSString * key)
{
    /*for (int i=0; i<4; i++)
    {
        executeAction(controller,key, i+1);
    }*/
    return 0;
}
///////////////////////////////////////////////////////

const char * const get_vendor(void* controller)
{
    return "Suncode";
}

int get_vendor_id(void* controller)
{
    return 1;
}

const char * const get_serial_number(void* controller, const char* board, int site)
{
    NSString *cmd;
    NSString *board_name = [NSString stringWithUTF8String:board];
    if ([board_name isEqualToString:@"testbase"]){
        cmd = [NSString stringWithFormat:@"eeprom.read(%@,cat32,%@,16)",board_name,@"0x0A70"];
    }
    else{
        cmd = [NSString stringWithFormat:@"eeprom.read(%@,cat32,%@,16)",board_name,@"0x00"];

    }
//    NSString *cmd = [@"eeprom.read(testbase,cat32,0x0A70,16)";
    writeFixtureLog([NSString stringWithFormat:@"get_serial_number, cmd: %@, site: %d,board:%@",cmd,site,board_name],site-1);
    int timeout = 5000;
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:cmd atSite:site-1 timeOut:timeout];
    
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:@"LA\\w*#\\w*" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *results = [regular matchesInString:ret options:0 range:NSMakeRange(0, ret.length)];
    NSString * val = @"";
    for(NSTextCheckingResult *result in results)
    {
        val = [ret substringWithRange:result.range];
    }
    
    writeFixtureLog([NSString stringWithFormat:@"[result] %@\r\n",val],site-1);
    return [val UTF8String];
}

const char * const get_carrier_serial_number(void* controller, int site)
{
    if(site<1)
    {
        writeFixtureLog([NSString stringWithFormat:@"get_carrier_serial_number, site : %d \r\n",site],site-1);
        return "-1";
    }
    
    writeFixtureLog([NSString stringWithFormat:@"get_carrier_serial_number, 20201006 , site : %d\r\n",site],site-1);
    return "20201006";
    
}

const char* const get_error_message(int status,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"get_error_message, status : %d \r\n",status],1);
    switch (status) {
        case 0:
            return "Successful";
        case (-1):
            return "No exist serial port.";
        case (-2):
            return "Failed to open serial port.";
        case (-3):
            return "Communication timeout.";
        case (-4):
            return "Invalid command.";
        case (-5):
            return "Failed to execute command.";
        case (-101):
            return "No implementate this function.";
        case (-6):
            return "Failed to init controller.";
        case (-7):
            return "Failed to reset controller.";
        default:
            return "Unexcepted error.";
            break;
    }
    return "Unexcepted error.";

}

const char* const get_version(void* controller)
{
    NSString *ver = @"dylib_v1.0";
    writeFixtureLog(ver,0);
    return [ver UTF8String];

}

int init(void* controller)
{
    system("pkill -9 virtualport");
    system("pkill -9 usbfs-2.4.20");
    system("rm /tmp/FCT_calibration_Suncode.txt");
    
    g_out_flag = YES;
    writeFixtureLog(@"init",0);
    writeFixtureLog(@"init",1);
    writeFixtureLog(@"init",2);
    writeFixtureLog(@"init",3);
    RPCController *fixture = (__bridge RPCController *)controller;
    for (int i=0; i<4; i++)
    {
        [fixture uartShutdown:i];
        reset(controller,i+1);
        read_calibration_data(controller,i+1);
    }
    
    return 0;
}

int reset(void* controller, int site)
{
    writeFixtureLog([NSString stringWithFormat:@"reset, site: %d\r\n",site],site-1);
    NSString *bit_name = @"reset";
    int timeout = 5000;

    RPCController *fixture = (__bridge RPCController *)controller;
    if ([cmdDic objectForKey:bit_name])
    {
        NSArray *valArr = [cmdDic objectForKey:bit_name];
        for (int i=0; i<[valArr count]; i++)
        {
            NSString *strCmd = valArr[i];
            NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:timeout];
            writeFixtureLog([NSString stringWithFormat:@"[cmd] %@, [result] %@\r\n",strCmd,ret],site-1);
        }
        
    }
    return 0;
}

const char * get_calibration_addr(void* controller)
{
    NSString *name = @"CalibrationAddr";
    NSString *returnVal = @"";
    if ([cmdDic objectForKey:name])
    {
        NSMutableString *str = [NSMutableString string];
        NSArray *valArr = [cmdDic objectForKey:name];
        for (int i=0; i<[valArr count]; i++)
        {
            [str appendString:[NSString stringWithFormat:@"%@;",valArr[i]]];
        }
        returnVal  = [NSString stringWithFormat:@"%@",str];
    }
    
    return [returnVal UTF8String];
}

const char * relay_switch(void* controller, const char* net_name, const char * state, int site)
{
    NSString *bit_name = [NSString stringWithFormat:@"%s",net_name];
    NSString *bit_state = [NSString stringWithFormat:@"%s",state];
    writeFixtureLog([NSString stringWithFormat:@"relay_switch, net_name: %s  state:%s  site: %d,bit_state:%@",net_name,state,site,bit_state],site-1);
    if(site<1)
    {
        return "site<1";
    }
    RPCController *fixture = (__bridge RPCController *)controller;

    if([bit_name length]<1 || [bit_state length]<1)
    {
        return "Err,maybe empty net_name or state";
    }
    if ([cmdDic objectForKey:bit_name])  //如果dic 里面 存在对照关系，就去替换。目的：为了和其他厂商兼容的net name
    {
        bit_name = [cmdDic objectForKey:bit_name];
    }
    NSString *strCmd = [NSString stringWithFormat:@"io.relay_switch(%@,%@)",bit_name,bit_state];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
    return [ret UTF8String];
}

float read_voltage(void* controller, const char* net_name,const char* mode,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"read_voltage, net_name: %s, mode: %s, site: %d",net_name,mode,site],site-1);
    NSString *bit_name = [NSString stringWithFormat:@"%s",net_name];
    NSString *type = [NSString stringWithUTF8String:mode];
    
    if(site<1)
    {
        return -1;
    }
    
    if ([cmdDic objectForKey:bit_name])  //如果dic 里面 存在对照关系，就去替换。目的：为了和其他厂商兼容的net name
    {
        bit_name = [cmdDic objectForKey:bit_name];
    }
    
    NSString *option = @"nor";
    int count = 1;
    int sample_rate = 10000;
    int measure_time = 70;
    float sleep_time = 0.01;  //切换relay 后，等待时间，单位s， 再去测量。
    if (([type containsString:@";"] && [bit_name isEqualToString:@"USB_CURRENT_BIG"]) || ([type containsString:@";"] && [bit_name isEqualToString:@"USB_TARGET_CURRENT"]))
    {
        sleep_time = 0.12;
    }
    
    
    
    if ([bit_name isEqualToString:@"PPLED_OUT"] || [bit_name isEqualToString:@"PPLED_BACK_REG"])
    {
        measure_time = 500;
    }
    else if ([bit_name isEqualToString:@"DENSE_CURRENT"] || [bit_name isEqualToString:@"SPARSE_CURRENT"] || [bit_name isEqualToString:@"ROSALINE_CURRENT"] || [bit_name isEqualToString:@"TITUS_A_CURRENT"] || [bit_name isEqualToString:@"TITUS_B_CURRENT"])
    {
        measure_time = 500;
    }
     else if([bit_name isEqualToString:@"BATT_CURRENT_BIG"] || [bit_name isEqualToString:@"USB_TARGET_CURRENT"] || [bit_name isEqualToString:@"USB_CURRENT_BIG"])
     {
         measure_time = 100;
     }
    if ([[NSString stringWithUTF8String:mode] containsString:@"Hibernation"])
    {
        measure_time = 400;
    }
    
    NSString *strCmd = [NSString stringWithFormat:@"blade.dmm(%@,%@,%d,%d,%d,%f)",bit_name,option,sample_rate,count,measure_time,sleep_time];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
    NSString *vlotage = [fixture stringMatch:ret withCount:0];

//    if ([bit_name isEqualToString:@"BATT_CURRENT_BIG"] && ([vlotage floatValue]<60) && [[NSString stringWithUTF8String:mode] containsString:@"Hibernation"])
//    {
//        bit_name =@"BATT_CURRENT_SMALL";
//        measure_time = 400;
//        relay_switch(controller, "BATT_MODE_CTL", "SMALL",site);
//        [NSThread sleepForTimeInterval:1.0];
//        NSString *strCmd = [NSString stringWithFormat:@"blade.dmm(%@,%@,%d,%d,%d,%f)",bit_name,option,sample_rate,count,measure_time,sleep_time];
//        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
//        RPCController *fixture = (__bridge RPCController *)controller;
//        NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
//        writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
//        vlotage = [fixture stringMatch:ret withCount:0];
//        relay_switch(controller, "BATT_MODE_CTL", "BIG",site);
//
//    }
    
    if ([bit_name isEqualToString:@"BATT_CURRENT_SMALL"] )  //   小电流模式测试完，强制切换到大电流模式
    {
        NSString * cmdIO = @"blade.measure_table_relay_on(BATT_CURRENT_BIG)";
        NSString *res = [fixture WriteReadString:cmdIO atSite:site-1 timeOut:5000];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]:%@,[result]: %@",cmdIO,res],site-1);
    }
    else if ([bit_name isEqualToString:@"USB_CURRENT_SMALL"])  //   小电流模式测试完，强制切换到大电流模式
    {
        NSString * cmdIO = @"blade.measure_table_relay_on(USB_CURRENT_BIG)";
        NSString *res = [fixture WriteReadString:cmdIO atSite:site-1 timeOut:5000];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]:%@,[result]: %@",cmdIO,res],site-1);
    }
    float returnVal = [vlotage floatValue];
    

    
     // ************for gain  factor*****************
    if ([type containsString:@";"])
    {
        float gainV = 1;
        @try
        {
            gainV = [[type componentsSeparatedByString:@";"][1] floatValue];
            writeFixtureLog([NSString stringWithFormat:@"[gain]:%f",gainV],site-1);
        }
        @catch (NSException *exception)
        {
            writeFixtureLog([NSString stringWithFormat:@"[gain error]:%@",exception],site-1);
        }
        
        returnVal = returnVal* gainV;
    }
    
    // ************如果是小电流模式，都不掉用系数，直接return*****************
//    if ([bit_name isEqualToString:@"BATT_CURRENT_SMALL"] || [type containsString:@"Hibernation"])
//    {
//        return returnVal;
//    }
    
     // ************for add calibration factor*****************
    if ([type containsString:@"zero"])
    {
        returnVal = [Calibration cal_ADC_zero_read_factor:globalDic content:ret value:returnVal site:site];
    }
    else if ([bit_name containsString:@"LED"] && ![bit_name containsString:@"STROBE_LED_CURRENT"])
    {
        NSLog(@"do nothing");
    }
    else if ([bit_name containsString:@"USB_TARGET_CURRENT"])
    {
        NSString *level = @"5V";
        if ([type containsString:@"9000"] || [type containsString:@"9V"])
        {
            level = @"9V";
        }
        else if ([type containsString:@"12000"] || [type containsString:@"12V"])
        {
            level = @"12V";
        }
        else if ([type containsString:@"15000"] || [type containsString:@"15V"])
        {
            level = @"15V";
        }
        returnVal = [Calibration cal_target_current_factor:globalDic level:level value:returnVal site:site];
        
    }
     else if ([bit_name containsString:@"BATT_CURRENT"])
     {
         returnVal = [Calibration cal_ibatt_factor:globalDic value:returnVal site:site];
     }
     else if ([bit_name containsString:@"USB_CURRENT"])
     {
         returnVal = [Calibration cal_ibus_factor:globalDic value:returnVal site:site];
     }
     else
     {
         returnVal = [Calibration cal_ai1_8_factor:globalDic content:ret value:returnVal site:site];
     }
    
     writeFixtureLog([NSString stringWithFormat:@"[after calibration] : %f",returnVal],site-1);
     return returnVal;
}

float read_frequency(void* controller, const char* net_name,int ref_volt,int measure_time, const char*gear, int site)
//float read_frequency(void* controller, const char* net_name,int ref_volt,int site)
{
    NSString *gearStr = [NSString stringWithUTF8String:gear];
    if ([gearStr containsString:@"high"])
    {
        writeFixtureLog([NSString stringWithFormat:@"read_frequency, net_name: %s, door:%d, site: %d",net_name,ref_volt,site],site-1);
        NSString *bit_name = [NSString stringWithFormat:@"%s",net_name];
        if(site<1)
        {
            return -1.0;
        }
        RPCController *fixture = (__bridge RPCController *)controller;
        
        NSString * cmdIO = @"blade.measure_table_relay_on(CLK_Measure_Disable)";
        NSString *res1 = [fixture WriteReadString:cmdIO atSite:site-1 timeOut:5000];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@, [reult]: %@",cmdIO,res1],site-1);
        
        float sleep_time = 0.1;  //切换relay 后，等待时间，单位s， 再去测量。
        NSString *strCmd = [NSString stringWithFormat:@"blade.dmm_frequency(%@,-fd,%d,%f,%d)",bit_name,ref_volt,sleep_time,measure_time];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
        
        NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
        writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
        
        NSString *key = [NSString stringWithFormat:@"%@_%d",kFrequency,site]; //储存为全局变量，方便frequency_duty 和frequency_vpp解析
        [globalDic setValue:ret forKey:key];
        
        NSString *res2 = [fixture WriteReadString:cmdIO atSite:site-1 timeOut:5000];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@, [reult]: %@",cmdIO,res2],site-1);
        
        
        NSString *vlotage = [fixture stringMatch:ret withCount:0];
        return [vlotage floatValue];
    }
    else
    {
        writeFixtureLog([NSString stringWithFormat:@"read_frequency, net_name: %s, door:%d, site: %d",net_name,ref_volt,site],site-1);
        NSString *bit_name = [NSString stringWithFormat:@"%s",net_name];
        if(site<1)
        {
            return -1.0;
        }
        float sleep_time = 0.1;  //切换relay 后，等待时间，单位s， 再去测量。
        NSString *strCmd = [NSString stringWithFormat:@"blade.dmm_frequency(%@,-fdv,%d,%f,%d)",bit_name,ref_volt,sleep_time,measure_time];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
        RPCController *fixture = (__bridge RPCController *)controller;
        NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];

        NSString *key = [NSString stringWithFormat:@"%@_%d",kFrequency,site]; //储存为全局变量，方便frequency_duty 和frequency_vpp解析
        [globalDic setValue:ret forKey:key];

        writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
        NSString *vlotage = [fixture stringMatch:ret withCount:0];
        return [vlotage floatValue];
    }
}
float read_frequency_duty(void* controller, const char* net_name,int ref_volt,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"read_frequency_duty, net_name: %s, door:%d, site: %d",net_name,ref_volt,site],site-1);
    NSString *key = [NSString stringWithFormat:@"%@_%d",kFrequency,site];
    if ([globalDic valueForKey:key])
    {
        RPCController *fixture = (__bridge RPCController *)controller;
        NSString *origStr= [globalDic valueForKey:key];
        NSString *duty = [fixture stringMatch:origStr withCount:1];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@,\r\n[result]: %@",origStr,duty],site-1);
        if (duty)
        {
            return [duty floatValue];
        }
        else
        {
            return 0.0;
        }
        
    }
    return -1.0;
}
float read_frequency_vpp(void* controller, const char* net_name,int ref_volt,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"read_frequency_vpp, net_name: %s, door:%d, site: %d",net_name,ref_volt,site],site-1);
    NSString *key = [NSString stringWithFormat:@"%@_%d",kFrequency,site];
    if ([globalDic valueForKey:key])
    {
        RPCController *fixture = (__bridge RPCController *)controller;
        NSString *origStr= [globalDic valueForKey:key];
        NSString *vpp = [fixture stringMatch:origStr withCount:2];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@,\r\n[result]: %@",origStr,vpp],site-1);
        if (vpp)
        {
            return [vpp floatValue];
        }
        else
        {
            return 0.0;
        }
    }
    return -1.0;
}


const char *set_battery_voltage(void* controller,float volt_mv, const char * mode,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"set_battery_voltage, volt_mv: %f, mode:%s, site: %d",volt_mv,mode,site],site-1);
    if(volt_mv<-10 || volt_mv>4500)
    {
        return "ERR:VBATT SET Wrong";
    }
    if(volt_mv<0)
    {
        volt_mv = 0;
    }
    NSString *mode_type = [NSString stringWithUTF8String:mode];
    NSString *strCmd = @"";
    if ([mode_type containsString:@"-"])
    {
        NSArray *arrVal = [mode_type componentsSeparatedByString:@"-"];
        float start = [arrVal[0] floatValue];
        float stop = [arrVal[1] floatValue];
        float step = [arrVal[2] floatValue];
        
        stop = [Calibration vbatt_set_with_cal_factor:globalDic value:stop site:site];
        writeFixtureLog([NSString stringWithFormat:@"[after calibration] : %f",stop],site-1);
        strCmd = [NSString stringWithFormat:@"blade.dac_step_set(a,%d,%d,%d)",(int)(start+0.5),(int)(stop+0.5),(int)(step+0.5)]; ////四舍五入
    }
    else
    {
        volt_mv = [Calibration vbatt_set_with_cal_factor:globalDic value:volt_mv site:site];
        writeFixtureLog([NSString stringWithFormat:@"[after calibration] : %f",volt_mv],site-1);
        strCmd = [NSString stringWithFormat:@"blade.dac_set(a,%d)",(int)(volt_mv+0.5)]; //四舍五入
    }
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
    return [ret UTF8String];
    
}
const char *set_usb_voltage(void* controller,float volt_mv, const char * mode,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"set_usb_voltage, volt_mv: %f, mode:%s, site: %d",volt_mv,mode,site],site-1);
    if (volt_mv<0 || volt_mv>17500)
    {
        return "ERR:VBUS SET Wrong";
    }
    
    NSString *mode_type = [NSString stringWithUTF8String:mode];
    NSString *strCmd = @"";
    if ([mode_type containsString:@"-"])
    {
        NSArray *arrVal = [mode_type componentsSeparatedByString:@"-"];
        float start = [arrVal[0] floatValue];
        start = (start -1221)/4;
        if (start <0)
        {
            start = 0;
        }
        
        float stop = [arrVal[1] floatValue];
        stop = [Calibration usb_set_with_cal_factor:globalDic value:stop site:site];
        writeFixtureLog([NSString stringWithFormat:@"[after calibration:] : %f",stop],site-1);
        stop = (stop-1221)/4;
        
        float step = [arrVal[2] floatValue];
        step = (step -1221)/4;
        
        strCmd = [NSString stringWithFormat:@"blade.dac_step_set(d,%d,%d,%d)",(int)(start+0.5),(int)(stop+0.5),(int)(step+0.5)];
    }
    else
    {
        if (volt_mv != 0)
        {
            volt_mv = [Calibration usb_set_with_cal_factor:globalDic value:volt_mv site:site];
            writeFixtureLog([NSString stringWithFormat:@"[after calibration:] : %f",volt_mv],site-1);

            volt_mv = ((volt_mv-1221)/4);
        }
        strCmd = [NSString stringWithFormat:@"blade.dac_set(d,%d)",(int)(volt_mv+0.5)];
    }
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
    return [ret UTF8String];
}

const char *set_eload_output(void* controller,float value_ma, const char * mode, int site)
{
    writeFixtureLog([NSString stringWithFormat:@"set_eload_output, volt_mv: %f, mode:%s, site: %d",value_ma,mode,site],site-1);
    if (value_ma<0 || value_ma>3000)
    {
        return "ERR:ELOAD SET Wrong!";
    }
    
    NSString *mode_type = [NSString stringWithUTF8String:mode];
    NSString *strCmd= @"";
    if ([mode_type containsString:@"-"])
    {
        NSArray *arrVal = [mode_type componentsSeparatedByString:@"-"];
        float start = [arrVal[0] floatValue];
        float stop = [arrVal[1] floatValue];
        float step = [arrVal[2] floatValue];
        strCmd = [NSString stringWithFormat:@"blade.dac_step_set(b,%d,%d,%d)",(int)(start+0.5),(int)(stop+0.5),(int)(step+0.5)];
    }
    else
    {
        strCmd = [NSString stringWithFormat:@"blade.dac_set(b,%d)",(int)(value_ma+0.5)];
    }
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
    return [ret UTF8String];
}
const char *set_pp5v0_output(void* controller,float volt_mv, const char * mode, int site)
{
    writeFixtureLog([NSString stringWithFormat:@"set_pp5v0_output, volt_mv: %f, mode:%s, site: %d",volt_mv,mode,site],site-1);
    if (volt_mv<0 || volt_mv>5300)
    {
        return "ERR:PP5V0 SET Wrong";
    }
    
    NSString *mode_type = [NSString stringWithUTF8String:mode];
    NSString *strCmd = @"";
    if ([mode_type containsString:@"-"])
    {
        NSArray *arrVal = [mode_type componentsSeparatedByString:@"-"];
        float start = [arrVal[0] floatValue];
        start = (start -1221)/4;
        if (start <0)
        {
            start = 0;
        }

        float stop = [arrVal[1] floatValue];
        stop = (stop-1221)/4;
        
        float step = [arrVal[2] floatValue];
        step = (step -1221)/4;
        strCmd = [NSString stringWithFormat:@"blade.dac_step_set(c,%d,%d,%d)",(int)(start+0.5),(int)(stop+0.5),(int)(step+0.5)]; //四舍五入
    }
    else
    {
        if (volt_mv != 0)
        {
            volt_mv = ((volt_mv-1221)/4);
        }
        strCmd = [NSString stringWithFormat:@"blade.dac_set(c,%d)",(int)(volt_mv+0.5)];  //四舍五入
    }
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
    return [ret UTF8String];
}

const char *fixture_command(void* controller, const char* cmd, int timeout, int site)
{
    writeFixtureLog([NSString stringWithFormat:@"fixture_command, cmd: %s, site: %d",cmd,site],site-1);
    NSString *command = [NSString stringWithUTF8String:cmd];
    if ([cmdDic objectForKey:command])
    {
        command = [cmdDic objectForKey:command];
    }
    command = [command stringByReplacingOccurrencesOfString:@"*" withString:@","];
    return executeRpcAction(controller, command, timeout,site);
}

const char *rpc_write_read(void* controller, const char* rpccmd, int timeout, int site)
{
    writeFixtureLog([NSString stringWithFormat:@"rpc_write_read, rpc_cmd: %s, site: %d",rpccmd,site],site-1);
    return executeRpcAction(controller, [NSString stringWithFormat:@"%s",rpccmd], timeout,site);
}

const char *getAndWriteFile(void* controller,const char* target,const char* dest,int site,int timeout)
{
    writeFixtureLog([NSString stringWithFormat:@"getAndWriteFile, target: %s,dest: %s, site: %d",target,dest,site],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    return [[fixture getAndWriteFile:[NSString stringWithUTF8String:target] dest:[NSString stringWithUTF8String:dest] atSite:site-1 timeout:timeout] UTF8String];

}


int dut_detect(void* controller,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"dut_detect, site: %d",site],site-1);
    float value = read_voltage(controller,"DUT_DTETECT", "",site);
    if (value < 100)
    {
        return 1;
    }
    return -1;
}

const char * const get_fw_version(void* controller,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"get_fw_version, site: %d",site],site-1);
    NSString *strCmd = @"xavier.fw_version()";
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@",strCmd],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",ret],site-1);
    
     ret = [ret stringByReplacingOccurrencesOfString:@"\"" withString:@""];
     ret = [ret stringByReplacingOccurrencesOfString:@" " withString:@""];
    
     NSString *pattern = [NSString stringWithFormat:@"%@|%@|%@",@"Addon_J407_FCT_SC=\\d*",@"MIX_FW_PACKAGE=\\d*",@"PL_J407_FCT_SC=\\d*"];
     NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
     NSArray *results = [regular matchesInString:ret options:0 range:NSMakeRange(0, ret.length)];
     NSString *addon_ver = @"";
     NSString *package_ver = @"";
     NSString *pl_ver = @"";
     int i=0;
    for(NSTextCheckingResult *result in results)
    {

        if (i==0)
        {
            addon_ver = [ret substringWithRange:NSMakeRange(20, result.range.length-18)];
        }
        else if (i==1)
        {
            package_ver = [ret substringWithRange:NSMakeRange(result.range.location+15, result.range.length-15)];
        }
            
       else if (i==2)
       {
           pl_ver = [ret substringWithRange:NSMakeRange(result.range.location + 15, result.range.length-15)];
       }
        i++;
    }
    
    NSString *fw_ver = [NSString stringWithFormat:@"%@.%@.%@",addon_ver,package_ver,pl_ver];
    return [fw_ver UTF8String];
    
}


const char *eload_set(void* controller,int channel,const char * mode,float value, int site)
{
    writeFixtureLog([NSString stringWithFormat:@"eload_set, channel:%d, mode: %s, value: %f, site: %d",channel,mode,value,site],site-1);
    
    float setValue = value;
    if ([[NSString stringWithUTF8String:mode] isEqualToString:@"cc"])
    {
        setValue = [Calibration cal_eload_set_factor:globalDic channel:channel value:value site:site];
    }
    
    writeFixtureLog([NSString stringWithFormat:@"[after calibration] : %f",setValue],site-1);

    NSString *strCmd = [NSString stringWithFormat:@"eload.set(%d,%s,%f)",channel,mode,setValue];
    RPCController *fixture = (__bridge RPCController *)controller;
    
    NSString *ret1 = @"";
    NSString *ret2 = @"";
    if (value == 0)
    {
         ret1 = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
         writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@,[result]: %@",strCmd,ret1],site-1);
        
//         NSString *strCmd2 = [NSString stringWithFormat:@"eload.disable(%d)",channel];
//         ret2 = [fixture WriteReadString:strCmd2 atSite:site-1 timeOut:6000];
//         writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@ ,[result]: %@",strCmd2,ret2],site-1);
    }
    else
    {
//        NSString *strCmd2 = [NSString stringWithFormat:@"eload.enable(%d)",channel];
//        ret2 = [fixture WriteReadString:strCmd2 atSite:site-1 timeOut:6000];
//        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@ ,[result]: %@",strCmd2,ret2],site-1);
        
        ret1 = [fixture WriteReadString:strCmd atSite:site-1 timeOut:6000];
        writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@, [result]: %@",strCmd,ret1],site-1);
        [NSThread sleepForTimeInterval:0.005];
    }
    
    if ([ret1 containsString:@"ERR"]||[ret2 containsString:@"ERR"])
    {
        return "ERR";
    }
    return "DONE";
}

float read_gpio_voltage(void* controller,const char* net_name,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"read_gpio_voltage, net_name: %s, site: %d",net_name,site],site-1);
    NSString *io_connect = @"io.set(bit41=1;bit45=1;bit126=0;bit125=0;bit30=1;bit124=1;bit123=0;bit122=1)";
    RPCController *fixture = (__bridge RPCController *)controller;
    [fixture WriteReadString:io_connect atSite:site-1 timeOut:3000];
    
    NSString *adg2188_connect = @"adg2188.switch(adg2188_0,2,7,1)";
    [fixture WriteReadString:adg2188_connect atSite:site-1 timeOut:3000];
    
    NSString *vol_cmd = @"blade.adc_read(c,nor,G,10V,10000,1,10)";
    float FDFU = 0.0;
    for (int j=0; j<500; j++)
    {
        NSString *ret = [fixture WriteReadString:vol_cmd atSite:site-1 timeOut:3000];
        FDFU = [[fixture stringMatch:ret withCount:0] floatValue];
        if (FDFU>1200)
        {
            break;
        }
    }
    NSString * adg2188_disconnect = @"adg2188.switch(adg2188_0,2,7,0)";
    [fixture WriteReadString:adg2188_disconnect atSite:site-1 timeOut:3000];
    return FDFU;
    
}


float read_eload_current(void* controller,const char* net_name,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"read_eload_current, net_name: %s, site: %d",net_name,site],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *strCmd = [NSString stringWithFormat:@"blade.measure_table_relay_on(%s)",net_name];
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:5000];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@ [result]: %@",strCmd,ret],site-1);
    [NSThread sleepForTimeInterval:0.2];
    int ch = 1;
    NSString *netName = [NSString stringWithUTF8String:net_name];
    if ([netName containsString:@"2"])
    {
        ch = 2;
    }
    NSString *strCmd2 = [NSString stringWithFormat:@"eload.eload_read_current(%d)",ch];
    NSString *result = [fixture WriteReadString:strCmd2 atSite:site-1 timeOut:5000];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@\r\n[result] : %@",strCmd2,result],site-1);
    NSString *value = [fixture stringMatch:result withCount:0];
    writeFixtureLog([NSString stringWithFormat:@"[orig value] : %@",value],site-1);
    
    float retvalue = [Calibration cal_eload_read_factor:globalDic channel:ch value:[value floatValue] site:site];
    writeFixtureLog([NSString stringWithFormat:@"[after calibration] : %f",retvalue],site-1);

    return  retvalue;

}


float read_eload_cv_current(void* controller,const char* net_name,float value,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"read_eload_cv_current,net_name: %s, %f, site: %d",net_name,value,site],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *strCmd = [NSString stringWithFormat:@"blade.measure_table_relay_on(%s)",net_name];  //切 measure table IO
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:5000];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@ [result]: %@",strCmd,ret],site-1);
    
    NSString *strCmd1 = [NSString stringWithFormat:@"blade.dac_set(b,%d)",(int)value];
    NSString *ret1 = [fixture WriteReadString:strCmd1 atSite:site-1 timeOut:5000];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@ [result]: %@",strCmd1,ret1],site-1);
    
    NSString *strCmd2 = @"blade.set_cv(84,H)";
    NSString *ret2 = [fixture WriteReadString:strCmd2 atSite:site-1 timeOut:5000];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@ [result]: %@",strCmd2,ret2],site-1);
    
    NSString *result = [fixture stringMatch:ret2 withCount:0];
    return [result floatValue];
    
}

const char *set_dfu_mode(void* controller,int site)
{
    writeFixtureLog([NSString stringWithFormat:@"set_dfu_mode,site: %d",site],site-1);
    RPCController *fixture = (__bridge RPCController *)controller;
    
    
    [fixture WriteReadString:@"vdm.change_low_hearder(region0)" atSite:site-1 timeOut:5000];
    [fixture WriteReadString:@"vdm.change_source_pdo_count(2)" atSite:site-1 timeOut:5000];
    [fixture WriteReadString:@"vdm.tps_write_register_by_addr(0x32,PDO1: Max Voltage,0x02)" atSite:site-1 timeOut:5000];
    [fixture WriteReadString:@"vdm.change_tx_source_voltage(2,9000,2000,PP_HVE)" atSite:site-1 timeOut:5000];

    relay_switch(controller, "ACE_SBU_TO_ZYNQ_SWD", "NOCROSS",site);
    relay_switch(controller, "PPVBUS_USB_PWR", "TO_PP_EXT",site);
    relay_switch(controller, "VDM_VBUS_TO_PPVBUS_USB_EMI", "CONNECT",site);
    relay_switch(controller, "BATT_OUTPUT_CTL", "ON",site);
    [NSThread sleepForTimeInterval:0.01];
    set_battery_voltage(controller,2500,"",site);
    
    relay_switch(controller, "BATT_MODE_CTL", "BIG",site);
    relay_switch(controller, "VBUS_OUTPUT_CTL", "ON",site);
    
    [NSThread sleepForTimeInterval:0.01];
    set_usb_voltage(controller, 9000, "", site);
    writeFixtureLog([NSString stringWithFormat:@"[result]: %@",@"DONE"],site-1);
    return "DONE";
}

const char * vdm_set_source_capabilities(void* controller,int PDO_number, const char *source_switch, int voltage, int max_current, const char *peak_current, int site, int timeout)
{
    writeFixtureLog([NSString stringWithFormat:@"vdm_set_source_capabilities,PDO_number: %d,source_switch: %s,voltage: %d,max_current: %d,peak_current: %s,site: %d",PDO_number,source_switch,voltage,max_current,peak_current,site],site-1);
    //vdm.change_tx_source_voltage(1*5000*3500*PP_HVE)
    NSString *strCmd = [NSString stringWithFormat:@"vdm.change_tx_source_voltage(%d,%d,%d,%s)",PDO_number,voltage,max_current,source_switch];
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture WriteReadString:strCmd atSite:site-1 timeOut:5000];
    writeFixtureLog([NSString stringWithFormat:@"[cmd]: %@ \r\n[result]: %@",strCmd,ret],site-1);
    return "DONE";
    
}

const char *get_fixture_log(void* controller,int site)
{
    return "test::test";
}


