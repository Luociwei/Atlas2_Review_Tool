//
//  FCTFixture.m
//  FCTFixture
//
//  Created by PRM-JinHui.Huang on 2021/8/15.
//

#import <Foundation/Foundation.h>
#import "FCTFixture.h"
#import "PlistReader.h"
#import "RPCController.h"


int SLOTS = 1;
NSDictionary *RPCCommandDict = NULL;
NSDictionary *HWConfig = NULL;
NSMutableDictionary * cmd = NULL;
PlistReader *PRMTopologyReader = NULL;
dispatch_queue_t g_queue = NULL;
BOOL rpcConnected; // if rpc connected

float vpp[] = {0,0,0,0};
float freq[] = {0,0,0,0};
float duty[] = {0,0,0,0};


bool isFloat(NSString *string){
    NSScanner *scan = [NSScanner scannerWithString:string];
    float val;
    return [scan scanFloat:&val] && [scan isAtEnd];
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
    // load command map plist file
    PRMTopologyReader = [[PlistReader alloc] init];
    SLOTS = [[PRMTopologyReader getItemsByKey: @"SLOTS"] intValue];
    if (!SLOTS) SLOTS = 1;
    RPCCommandDict = [PRMTopologyReader getItemsByKey:@"RPCCommandTable"];
    HWConfig = [PRMTopologyReader getItemsByKey:@"HW"];
    RPCController *controller = [[RPCController alloc] init];
    for (int i = 0; i < SLOTS; i++) {
        system([[NSString stringWithFormat:@"ping -t 1 169.254.1.%i", 32+i] UTF8String]);
        NSDictionary *uutInfo = [HWConfig objectForKey: [@"UUT" stringByAppendingFormat:@"%u", i]];
        NSDictionary *xavierInfo = [uutInfo objectForKey:@"Xavier"];
        
        NSString *xavierIP = [xavierInfo objectForKey:@"IP"];
        NSUInteger xavierPort = [[xavierInfo objectForKey:@"PORT"] intValue];
        NSString *pathLogFile = [uutInfo objectForKey:@"HW_LOG"];
        for (int j = 0; j < SLOTS; j++) {
            BOOL ret = [controller createRPCClient:xavierIP andPort:xavierPort andLogPath:pathLogFile];
            // check if create rpc connected
            if (ret) {
                rpcConnected = YES;
                break;
            }else{
                rpcConnected = NO;
                NSLog(@"Can not connect to %@, retry: %d times...", xavierIP, i);
                usleep(3000000);
                continue;
            }
        }
        // if one connected fail, break;
        if(!rpcConnected){
            break;
        }
        
    }
    create_global_object(controller);
    return (__bridge_retained void *)controller;
}


void release_fixture_controller(void* controller)
{
    RPCController *fixture = (__bridge RPCController *)controller;
    for (int i = 0; i < SLOTS; i++) {
        [fixture uartShutdown:i];
        [fixture hwlog:@"release_fixture_controller\n" andSite:i];
    }
    [fixture close];
}


int init(void *controller){
    RPCController *fixture = (__bridge RPCController *)controller;
    system("ps -ef | grep virtualport | grep -v grep | cut -b 7-12 | xargs kill -9");
    for (int i = 0; i < SLOTS; i++) {
        [fixture uartShutdown:i];
    }
    return 0;
}

int reset(void* controller, int site){
    // mix reset
    if(!rpcConnected){
        NSLog( @"init fail");
        return -1;
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture rpcCall:@"reset.reset()" atSite: site - 1 timeOut:5000];
    if ([ret isEqualToString:@"done"]){
        return 0;
    }
    else
        return -1;
}


const char * const get_vendor(void* controller){
    // vendor name
    NSString *vendor = @"PRM";
    return [vendor UTF8String];
}

const char * const get_version(void* controller){
    // dylib version
    return "v1.0.1";
}

const char * const get_serial_number(void* controller, int site){
    // slot number: format projectCode_StationType_#StationNumber_SlotNumber      LA_FCT_#001_UUT1
    // read from base eeprom, so this serial numbrer must be writen to baseboard eeprom first
    if(!rpcConnected){
        return "init fail";
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture rpcCall:@"base_eeprom.read_id()" atSite:site - 1 timeOut:3000];
    return [ret UTF8String];
}


const char * const get_error_message(int status, int site){
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

const char * relay_switch(void* controller, const char* net_name, const char * state, int site){
    if(!rpcConnected){
        return "init fail";
    }
    if(site < 1)
        return "Error - site little than 1";
    // "net_name,state" must exist in /mix/addon/driver/project/redirectIOMap.json or io_map.json,
    // this function search key in redirectIOMap.json first and then io_map.json, if not found, will raise error
    // call mix relay.relay(net, subnet) function, this will log all the relate relay command into log
    NSString *net = [NSString stringWithUTF8String:net_name];
    NSString *subNet = [NSString stringWithUTF8String:state];
    
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture rpcCall:[NSString stringWithFormat:@"relay.relay(%@,%@)", net, subNet] atSite:site - 1 timeOut:3000];
    NSString *formatRet = [NSString stringWithFormat:@"[relay_switch] %s -> %s\n%@\n", net_name, state, ret];
    return [formatRet UTF8String];
}

float read_voltage(void* controller, const char* net_name,const char* mode,int site){
    // read vaoltage, only support one net_name, if this net_name must exist in /mix/addon/dirver/project/dmmMap.json
    if(!rpcConnected){
        NSLog(@"init fail");
        return -9999999.99;
    }
    if(site < 1)
        return -9999.99;
    NSString *net = [NSString stringWithUTF8String:net_name];
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = nil;
    if ([[net uppercaseString] hasPrefix:@"BATT_CURRENT_SMALL"]) {
        ret = [fixture rpcCall:[NSString stringWithFormat:@"dmm.read_batt_current(%@)", net] atSite:site - 1 timeOut:3000];
    }else{
        ret = [fixture rpcCall:[NSString stringWithFormat:@"dmm.read_voltage(%@)", net] atSite:site - 1 timeOut:3000];
    }

    return [ret floatValue];
}

float read_frequency(void* controller, const char* net_name,int ref_volt, int measure_time, const char*geer, int site){
    if(!rpcConnected){
        NSLog(@"init fail");
        return -9999999.99;
    }
    //geeer: 'low', 'mid', 'high'
    freq[site - 1] = 0.0;
    vpp[site - 1] = 0.0;
    duty[site - 1] = 0.0;
    NSString *net = [NSString stringWithUTF8String:net_name];
    RPCController *fixture = (__bridge RPCController *)controller;
    if ([[NSString stringWithUTF8String:net_name] hasPrefix:@"SPK"]) {
        [fixture rpcCall:[NSString stringWithFormat:@"relay.relay(%@)", net] atSite:site - 1 timeOut:3000];
    }
    else{
         [fixture rpcCall:[NSString stringWithFormat:@"relay.relay(%@,CONNECT)", net] atSite:site - 1 timeOut:3000];
    }
    NSString *cmd = NULL;
    if (ref_volt == 80) {
        ref_volt = 550;
    }
    usleep(200000);
    if ([[NSString stringWithUTF8String:geer] isEqualToString:@""]) {
        cmd = [NSString stringWithFormat:@"blade.ac_signal_measure(dfvw,%i,%i)", ref_volt, measure_time];
    }else{
        cmd = [NSString stringWithFormat:@"blade.ac_signal_measure(dfvw,%i,%i,%s)", ref_volt, measure_time, geer];
    }
    id rtn = [fixture rpcCall: cmd atSite:site - 1 timeOut:3000];
    if ([rtn isKindOfClass:[NSDictionary class]] && [rtn objectForKey:@"freq"] && [rtn objectForKey:@"duty"] && [rtn objectForKey:@"vpp"]) {
        NSArray *retFreq = [rtn objectForKey:@"freq"];
        freq[site - 1] = [retFreq[0] floatValue];
        NSArray *retVPP = [rtn objectForKey:@"vpp"];
        vpp[site - 1] = [retVPP[0] floatValue];
        NSArray *retDuty = [rtn objectForKey:@"duty"];
        duty[site - 1] = [retDuty[0] floatValue];
    }
    return freq[site - 1];
}
float read_frequency_duty(void* controller, const char* net_name,int ref_volt, int site){
    if(!rpcConnected){
        NSLog(@"init fail");
        return -9999999.99;
    }
    return duty[site - 1];
}
float read_frequency_vpp(void* controller, const char* net_name,int ref_volt, int site){
    if(!rpcConnected){
        NSLog(@"init fail");
        return -9999999.99;
    }
    return vpp[site - 1];
}

const char *dac_output(void* controller,float volt_mv, const char * mode,int site, char channel, BOOL needCal){
    if(!rpcConnected){
        return "init fail";
    }
    NSString *ret = NULL;
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *stepOutput = [NSString stringWithUTF8String:mode];
    if ([stepOutput containsString:@"-"]){
        NSArray *steps = [stepOutput componentsSeparatedByString:@"-"];
        if ([steps count] != 3){
            ret = [NSString stringWithFormat:@"Error - Invalid step mode: %s", mode];
            return [ret UTF8String];
        }else{
            float startVolt = [[NSString stringWithFormat:@"%@", steps[0]] floatValue];
            float stopVolt = [[NSString stringWithFormat:@"%@", steps[1]] floatValue];
            float stepVolt = [[NSString stringWithFormat:@"%@", steps[2]] floatValue];
            if (needCal) {
                startVolt = (startVolt - 1221.0) / 4.0;
                if (startVolt < 0) {
                    startVolt = 0;
                }
                stopVolt = (stopVolt - 1221.0) / 4.0;
                if (stopVolt < 0) {
                    stopVolt = 0;
                }
                stepVolt = (stepVolt - 1221.0) / 4.0;
            }
            NSString *command = [NSString stringWithFormat:@"psu.dac_step_set(%c,%f,%f,%f)", channel, startVolt , stopVolt, stepVolt];
            NSString *ret = [fixture rpcCall: command atSite:site - 1 timeOut:3000];
            return [ret UTF8String];
        }
    }
    else{
        if (needCal) {
            volt_mv = (volt_mv - 1221.0) / 4.0;
            if (volt_mv <= 0) {
                volt_mv = 0.0;
            }
        }
        NSString *command = [NSString stringWithFormat:@"psu.dac_set(%c,%f)",channel, volt_mv];
        NSString *ret = [fixture rpcCall: command atSite:site - 1 timeOut:3000];
        return [ret UTF8String];
    }
}


const char *set_battery_voltage(void* controller,float volt_mv, const char * mode,int site){
    return dac_output(controller, volt_mv, mode, site, 'c', false);
}


const char *set_usb_voltage(void* controller,float volt_mv, const char * mode,int site){
    return dac_output(controller, volt_mv, mode, site, 'b', true);
    
}
const char *set_eload_output(void* controller,float value_ma, const char * mode, int site){
    return dac_output(controller, value_ma, mode, site, 'a', false);
    
}
const char *set_pp5v0_output(void* controller,float volt_mv, const char * mode, int site){
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture rpcCall:@"relay.relay(PP_5V0_VDM,CONNECT)" atSite:site-1 timeOut:100];
    return [ret UTF8String];
//    return dac_output(controller, volt_mv, mode, site, 'd', true);
    
}

const char * eload_set(void* controller, int channel, const char* mode, float value, int site){
    if(!rpcConnected){
        return "init fail";
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *command = [NSString stringWithFormat:@"eload.set_%s(ch%i,%f)",mode, channel, value];
    NSString *ret = [fixture rpcCall: command atSite:site - 1 timeOut:3000];
    ret = [NSString stringWithFormat:@"%@", ret];
    return [ret UTF8String];
    
}
const char *fixture_command(void* controller, const char* cmd, int timeout, int site){
    if(!rpcConnected){
        return "init fail";
    }
    // fixture_command if for send command defind in plistReader.m,
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *key = [NSString stringWithUTF8String:cmd];
    [fixture hwlog:[NSString stringWithFormat:@"fixtrure_command key: %@", key] andSite:site - 1];
    NSString *rpcCommand = [RPCCommandDict objectForKey:key];
    NSString *ret = nil;
    if (!rpcCommand) {
        ret = [fixture rpcCall: [NSString stringWithUTF8String:cmd] atSite:site - 1 timeOut:timeout];
//        ret = [NSString stringWithFormat:@"ERROR-Invalid key: %@", key];
        [fixture hwlog:[NSString stringWithFormat:@"Invalid fixtrure_command %s, try to use rpc_write_read:%s  return: <-- %@\n",cmd, cmd, ret] andSite:site - 1];
        return [ret UTF8String];
    }
    else{
        ret = [fixture rpcCall: rpcCommand atSite:site - 1 timeOut:timeout];
        return [[NSString stringWithFormat:@"%@",ret] UTF8String];
        
    }
    
}


const char *rpc_write_read(void* controller, const char* rpccmd, int timeout, int site){
    if(!rpcConnected){
        return "init fail";
    }
    // use the rpccmd directly
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *ret = [fixture rpcCall: [NSString stringWithUTF8String:rpccmd] atSite:site - 1 timeOut:timeout];
    ret = [NSString stringWithFormat:@"%@", ret];
    return [ret UTF8String];
}

const char *getAndWriteFile(void* controller,const char* target,const char* dest,int site,int timeout){
    if(!rpcConnected){
        return "init fail";
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString * response = [fixture getAndWriteFile:[NSString stringWithUTF8String:target] dest:[NSString stringWithUTF8String:dest] atSite:site-1 timeout:timeout];
    return [[NSString stringWithFormat:@"%@",response] UTF8String];
    
}

int dut_detect(void* controller,int site){
    if(!rpcConnected){
        NSLog(@"init fail");
        return -1;
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *volt = [fixture rpcCall: @"dmm.read_voltage(DUT_DTETECT)" atSite:site - 1 timeOut:3000];
    if ([volt floatValue] < 100){
        return 1;
    }else{
        return -1;
    }
}

int get_vendor_id(void* controller){
    return 2;
}

const char * const get_fw_version(void* controller,int site){
    if(!rpcConnected){
        return "init fail";
    }
    RPCController *fixture = (__bridge RPCController *)controller;
//    NSError *err;
    NSString *result;
    id verson = [fixture rpcCall: @"xavier.fw_version()" atSite:site - 1 timeOut:3000];
    if ([verson isKindOfClass:[NSDictionary class]]) {
        NSString *mixFWPackage = NULL;
        NSString *pl = NULL;
        NSString *addon = NULL;
        for (NSString *key in [verson allKeys]) {
            if([key hasPrefix:@"MIX_FW_PACKAGE"])
                mixFWPackage = [verson objectForKey:key];
            else if ([key hasPrefix:@"Addon_"])
                addon = [verson objectForKey:key];
            else if ([key hasPrefix:@"PL_"])
                pl = [verson objectForKey:key];
        }
        result = [NSString stringWithFormat:@"%@.%@.%@", mixFWPackage, addon, pl];
    }
    else{
        result = [NSString stringWithFormat:@"%@", verson];
    }

    return [result UTF8String];
}


float read_gpio_voltage(void* controller,const char* net_name,int site){
    if(!rpcConnected){
        NSLog(@"init fail");
        return -999999.99;
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    [fixture hwlog:@"---> start read_gpio_voltage <---\n" andSite: site - 1];
    [fixture rpcCall:@"relay.relay(DMM_MUX_AIN5_CH7,Y_5_TO_ADC)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(BLADE_ADC_AIN5_MUX,CHANNEL_MUX_OUT)" atSite:site-1 timeOut:100];
    float volt = -9999;
    // GPIO_FORCE_DFU
    if ([[NSString stringWithUTF8String:net_name] isEqualToString:@""] || [[NSString stringWithUTF8String:net_name] isEqualToString:@"GPIO_FORCE_DFU"]){
        NSString *io = @"4-0-0;4-1-0;4-2-0;4-3-0;4-4-0;4-5-1;4-6-0;4-7-0";
        NSString *command = [NSString stringWithFormat: @"fixture.gpioarray_io_switch(%@)", io];
        [fixture rpcCall: command atSite:site - 1 timeOut:1000];
        
        for (int i = 0; i < 7; i++) {
            for (int j = 0; j < 100; j++) {
                [NSThread sleepForTimeInterval:0.05];
                NSString *ret = [fixture rpcCall:@"dmm.adc_voltage_measure(AVG,CH4,10V,10000,1,10)" atSite:site-1 timeOut:500];
                if (isFloat(ret)){
                    volt = [ret floatValue];
                    if (volt > 1220)
                        break;
                }else{
                    continue;
                }
            }
            if (volt > 1220)
                break;
            else{
                [fixture rpcCall:@"relay.relay(VDM_CC1,DISCONNECT)" atSite:site-1 timeOut:100];
                usleep(1000000);
                [fixture rpcCall:@"relay.relay(VDM_CC1,TO_ACE_CC1)" atSite:site-1 timeOut:100];
                usleep(500000);
            }
        }
        [fixture rpcCall: @"fixture.gpioarray_io_switch(4-5-0;4-3-0)" atSite:site - 1 timeOut:1000];
    }
    else if ([[NSString stringWithUTF8String:net_name] isEqualToString:@"GPIO_1V2_SOC2ACE_DFU_STATUS"]){
        [fixture rpcCall: @"fixture.gpioarray_io_switch(0-5-1)" atSite:site - 1 timeOut:1000];
        NSString *ret = [fixture rpcCall:@"dmm.adc_voltage_measure(AVG,CH4,10V,10000,1,10)" atSite:site-1 timeOut:50];
        [fixture rpcCall: @"fixture.gpioarray_io_switch(0-5-0)" atSite:site - 1 timeOut:1000];
        volt = [ret floatValue];
    }
    else{
//        [NSThread sleepForTimeInterval:0.5];
        NSString *ret = [fixture rpcCall:@"dmm.adc_voltage_measure(nor,CH4,10V,10000,1,10)" atSite:site-1 timeOut:50];
        volt = [ret floatValue];
        [fixture rpcCall: @"fixture.gpioarray_io_switch(24-5-0;24-3-0)" atSite:site - 1 timeOut:1000];
    }
    [fixture hwlog:@"---> end read_gpio_voltage <---\n" andSite: site - 1];
    return volt;
}


const char * vdm_set_source_capabilities(void* controller,int PDO_number, const char *source_switch, int voltage, int max_current, const char *peak_current, int site, int timeout){
    if(!rpcConnected){
        return "init fail";
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    if ([[NSString stringWithUTF8String:source_switch] isEqualToString:@"PP_5V_00"]){
        source_switch = "PP_5V";
    }
    if ([[NSString stringWithUTF8String:peak_current] isEqualToString:@""]) {
        peak_current = "None";
    }
    NSString *command = [NSString stringWithFormat:@"vdm.set_source_capabilities(%i,%s,%i,%i,%s)",PDO_number, source_switch, voltage, max_current, peak_current];
    NSString *ret = [fixture rpcCall: command atSite:site - 1 timeOut:timeout];
    ret = [NSString stringWithFormat:@"%@", ret];
    return [ret UTF8String];
}


float read_eload_cv_current(void* controller,const char* net_name,float value,int site){
    if(!rpcConnected){
        NSLog(@"init fail");
        return -999999.99;
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    [fixture rpcCall:@"relay.relay(BLADE_GND,CONNECT_TO_FIXTURE_GND)" atSite:site-1 timeOut:100];
    NSString *command = [NSString stringWithFormat:@"psu.dac_set(d,%f)", value];
    [fixture rpcCall:command atSite:site-1 timeOut:100];
    NSString *ret = [fixture rpcCall: @"fixture.read_eload_cv_current(110)" atSite:site - 1 timeOut:1000];
    float current = [ret floatValue];
    [fixture rpcCall: @"psu.dac_set(d,0)" atSite:site - 1 timeOut:1000];
    return current;
    
}

float read_eload_current(void* controller,const char* net_name,int site){
    if(!rpcConnected){
        NSLog(@"init fail");
        return -999999.99;
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    NSString *command = [NSString stringWithFormat:@"fixture.read_eload_current(%s)", net_name];
    NSString *ret = [fixture rpcCall: command atSite:site - 1 timeOut: 10000];
    ret = [NSString stringWithFormat:@"%@", ret];
    return [ret floatValue];
}


const char *set_dfu_mode(void* controller,int site){
    if(!rpcConnected){
        return "init fail";
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    [fixture hwlog:@"---> start set_dfu_mode <---\n" andSite: site - 1];
    
    [fixture rpcCall: @"vdm.set_firmware_region_pointer(region0)" atSite:site - 1 timeOut:1000];
    [fixture rpcCall: @"vdm.change_source_pdo_count(2)" atSite:site - 1 timeOut:1000];
    [fixture rpcCall: @"vdm.set_source_capabilities(2,PP_HVE,9000,2000)" atSite:site - 1 timeOut:1000];
    
    [fixture rpcCall:@"relay.relay(ACE_USB_TOP_CONN,TO_USB_HUB)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(ACE_SBU_TO_ZYNQ_SWD,NOCROSS)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(PSU_PPVBUS_POWER_MUX,PSU_PPVBUS_TO_PPVBUS_VDM_CONN_IN)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(PSU_PPVBUS_POWER_MUX_SNS,PSU_PPVBUS_TO_PPVBUS_VDM_CONN_IN_SNS)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(PPVBUS_EMI_USB_PMUX,PPVBUS_USB_EMI_TO_PPVBUS_VDM_CONN_OUT)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(IO_BATT_SENSE_SW,CONNECT)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(IO_PPVBUS_EMI_SW,CONNECT)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"relay.relay(HRESET_SWITCH,CONNECT)" atSite:site-1 timeOut:100];
    
    [fixture rpcCall:@"psu.batt_output_ctl(enable)" atSite:site-1 timeOut:100];
    [NSThread sleepForTimeInterval:0.01];
    
    [fixture rpcCall:@"psu.batt_output(2500)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"psu.batt_current_mode_ctl(normal)" atSite:site-1 timeOut:100];
    [fixture rpcCall:@"psu.usb_output_ctl(enable)" atSite:site-1 timeOut:100];
    [NSThread sleepForTimeInterval:0.1];
    
    [fixture rpcCall:@"psu.usb_output(9000)" atSite:site-1 timeOut:500];
    
    [fixture hwlog:@"---> end set_dfu_mode <---\n\n" andSite: site - 1];
    return "--PASS--";
}

const char *get_fixture_log(void* controller, int site){
    if(!rpcConnected){
        return "init fail";
    }
    RPCController *fixture = (__bridge RPCController *)controller;
    return [[fixture rpcSendRecvLogs][site - 1] UTF8String];
}
