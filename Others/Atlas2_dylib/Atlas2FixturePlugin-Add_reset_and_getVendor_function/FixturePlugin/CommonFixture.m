
#import "CommonFixture.h"
#include "DFUFixture.h"

@interface CommonFixture()
{
    int _vendorId;
    NSString *_selfDomain;
    NSString *_serialnumber;
    NSString *_dylibVersion;
    void *_fixtureController;
    NSDictionary *_functionTable;
    NSDictionary *_constantTable;
}
@end

@implementation CommonFixture

//@synthesize stationName     = _stationName;

- (instancetype)initWithGroupId:(int)groupId error:(NSError **)error;
{
    self = [super init];
    if (self) {
        _serialnumber = @"";
        _dylibVersion = @"v0.0.1";
        _selfDomain = @"MTRPCDataChannel";

        _fixtureController = create_fixture_controller(groupId);

        _functionTable = @{
               @"is_board_detect" : @[@[ATKSelector(is_board_detect:error:),ATKNumber]],
               @"check_board_detect" : @[@[ATKSelector(check_board_detect:error:),ATKNumber]],
               @"init":@[@[ATKSelector(init:)]],
               @"reset":@[@[ATKSelector(reset:)]],
               @"get_version":@[@[ATKSelector(get_version:)]],
               @"fixture_open":@[@[ATKSelector(fixture_open:)]],
               @"fixture_close":@[@[ATKSelector(fixture_close:)]],
               @"fixture_engage":@[@[ATKSelector(fixture_engage:)]],
               @"fixture_disengage":@[@[ATKSelector(fixture_disengage:)]],
               @"enter_dfu" : @[@[ATKSelector(enter_dfu:error:),ATKNumber]],
               @"exit_dfu" : @[@[ATKSelector(exit_dfu:error:),ATKNumber]],
               @"set_uart_signal_on" : @[@[ATKSelector(set_uart_signal_on:error:),ATKNumber]],
               @"enter_diags" : @[@[ATKSelector(enter_diags:error:),ATKNumber]],
               @"enter_iboot" : @[@[ATKSelector(enter_iboot:error:),ATKNumber]],
               @"led_red_on" : @[@[ATKSelector(led_red_on:error:),ATKNumber]],
               @"led_green_on" : @[@[ATKSelector(led_green_on:error:),ATKNumber]],
               @"led_inprogress_on" : @[@[ATKSelector(led_inprogress_on:error:),ATKNumber]],
               @"led_gotoFA_on" : @[@[ATKSelector(led_gotoFA_on:error:),ATKNumber]],
               @"led_panic_on" : @[@[ATKSelector(led_panic_on:error:),ATKNumber]],
               @"led_off" : @[@[ATKSelector(led_off:error:),ATKNumber]],
               @"set_target_temp" : @[@[ATKSelector(set_target_temp:site:error:),ATKNumber,ATKNumber]],
               @"get_target_temp" : @[@[ATKSelector(get_target_temp:error:),ATKNumber]],
               @"dut_power_on" : @[@[ATKSelector(dut_power_on:error:),ATKNumber]],
               @"dut_power_off" : @[@[ATKSelector(dut_power_off:error:),ATKNumber]],
               @"usb_on" : @[@[ATKSelector(usb_on:error:),ATKNumber]],
               @"usb_off" : @[@[ATKSelector(usb_off:error:),ATKNumber]],
               @"ace_provisioning_power_on" : @[@[ATKSelector(ace_provisioning_power_on:error:),ATKNumber]],
               @"ace_provisioning_power_off" : @[@[ATKSelector(ace_provisioning_power_off:error:),ATKNumber]],
               @"relay_switch" : @[@[ATKSelector(relay_switch:state:site:error:),ATKString,ATKString,ATKNumber]],
               @"batt_on" : @[@[ATKSelector(batt_on:error:),ATKNumber]],
               @"batt_off" : @[@[ATKSelector(batt_off:error:),ATKNumber]],
               @"get_serial_number" : @[@[ATKSelector(get_serial_number:)]],
               @"waitForFixtureToClose" : @[@[ATKSelector(waitForFixtureToClose:site:error:),ATKNumber,ATKNumber]],
               @"isFixtureClosed" : @[@[ATKSelector(isFixtureClosed:error:), ATKNumber]],
               @"getUsbLocation" : @[@[ATKSelector(getUsbLocation:error:), ATKNumber]],
               @"getVendorId" : @[@[ATKSelector(getVendorId:)]],
               @"getVendor" :@[@[ATKSelector(getVendor:)]],
               @"getHostModel" : @[@[ATKSelector(getHostModel:)]],
               @"isFanOk" : @[@[ATKSelector(isFanOk:error:), ATKNumber]],
               @"setFanSpeed" : @[@[ATKSelector(setFanSpeed:site:error:), ATKNumber, ATKNumber]],
               @"getFanSpeed" : @[@[ATKSelector(getFanSpeed:error:), ATKNumber]],
               @"read_voltage" : @[@[ATKSelector(read_voltage:site:error:), ATKString, ATKNumber]],
               @"read_gpio" : @[@[ATKSelector(read_gpio:site:error:), ATKString, ATKNumber]],
               @"teardown" : @[@[ATKSelector(teardown:)]],
        };
                                    
        _constantTable = @{};
    }
    return self;
}

- (BOOL)teardown:(NSError **)error
{
    @synchronized (_fixtureController) {
        release_fixture_controller(_fixtureController);
        return YES;
    }
}

- (BOOL)is_board_detect:(NSNumber*)site error:(NSError **)error
{
    @synchronized (_fixtureController) {
        return is_board_detected(_fixtureController, site.intValue);
    }
}

- (NSNumber *)check_board_detect:(NSNumber*)site error:(NSError **)error
{
    @synchronized (_fixtureController) {
        int result = 0;
        if (is_board_detected(_fixtureController, site.intValue)) {
            result = 1;
        }
        return [NSNumber numberWithInt:result];
    }
}

-(BOOL)init:(NSError **)error
{
    ATKLog("function:init\n");
    int ret_v = -1;
    ret_v = init(_fixtureController);
    if (ret_v != 0) {
        *error = [self createErrorWithCode:ret_v];
    }
    ATKLog("function:init status : %d\n",ret_v);
    return ret_v == 0;
}

-(BOOL)reset:(NSError **)error
{
    int ret_v = -1;
    @synchronized (_fixtureController) {
        ret_v = reset(_fixtureController);
    }
    if (ret_v != 0) {
        *error = [self createErrorWithCode:ret_v];
    }
    ATKLog("function:reset status : %d\n",ret_v);
    return ret_v == 0;
}

-(NSNumber *)getFanSpeed:(NSNumber *)site error:(NSError **)error
{
    int speed = -1;
    @synchronized (_fixtureController) {
        speed = get_fan_speed(_fixtureController, [site intValue]);
    }
    if (speed < 0) {
        *error = [self createErrorWithCode:speed];
    }
    return [NSNumber numberWithInt:speed];
}

-(BOOL)setFanSpeed:(NSNumber *)speed site:(NSNumber *)site error:(NSError **)error
{
    bool status = false;
    if (!speed || [speed intValue] < 0)
    {
        ATKLogError("setFanSpeed Current Slot: %d, target speed invalid or not set: %@", [site intValue], speed);
    }
    else
    {
        @synchronized (_fixtureController) {
            status = set_fan_speed(_fixtureController, [speed intValue], [site intValue]);
        }
    }
    if (status != 0) {
        *error = [self createError:@"setFanSpeed return false " code:status];
    }
    return status == 0;
}


-(NSNumber *)isFanOk:(NSNumber *)site error:(NSError **)error
{
    bool status = false;
    ATKLog("start isFanOk Current Slot: %d", [site intValue]);
    @synchronized (_fixtureController) {
            status = is_fan_ok(_fixtureController, [site intValue]);
        }
    if (!status) {
        *error = [self createError:@"isFanOk return false " code:status];
    }
    return [NSNumber numberWithBool:status];
}


-(NSNumber *)getVendorId:(NSError **)error
{
    return [NSNumber numberWithInt:get_vendor_id()];
}


-(NSString *)getHostModel:(NSError **)error
{
    NSString *host = getHostModel();
    ATKLog("HostModel: %@",host);
    return host;
}

-(NSString *)getVendor:(NSError **)error
{
    const char *str = get_vendor();
    NSString *vendor = [NSString stringWithUTF8String:str];
    ATKLog("Vendor: %@",vendor);
    return vendor;
}

-(BOOL)getUsbLocation:(NSNumber *)site error:(NSError **)error
{
    NSString *locationId;
    ATKLogDebug("start get usb Slot: %d", [site intValue]);
    @synchronized (_fixtureController) {
        const char *usbLocationId = get_usb_location(_fixtureController, [site intValue]);
        if (usbLocationId)
        {
            locationId = [[NSString stringWithUTF8String:usbLocationId] lowercaseString];
            ATKLog("got usblocation %@",locationId);
            return YES;
        }
        else
        {
            ATKLogError("failed to get usblocation");

            return NO;
        }
    }
}

- (BOOL)isFixtureClosed:(NSNumber *)site error:(NSError **)error
{
    bool status = false;
    @synchronized (_fixtureController) {
        status = is_fixture_closed(_fixtureController, [site intValue]);
        if (!status)
        {
            ATKLogDebug("is_fixture_closed return false Current Slot: %d status %d", [site intValue], status);
            *error = [self createError:@"is_fixture_closed return false " code:status];
        }
        status = is_fixture_engaged(_fixtureController, [site intValue]);
        if (!status)
        {
            ATKLogDebug("is_fixture_engaged return false Current Slot: %d status %d", [site intValue],status);
            *error = [self createError:@"is_fixture_engaged return false " code:status];
        }
    }
    return status;
}

-(BOOL)waitForFixtureToClose: (NSNumber *)waitCount site:(NSNumber*)site error:(NSError **)error
{
    bool status = false;
    int counter = 0;
    int interval = [waitCount intValue];
    if (!interval)
    {
        // Default wait for ((4m * 0.5s) + time to check) before failing the DUT
        interval = 480;
    }else{
        interval = interval * 2;
    }
    @synchronized (_fixtureController) {
        while (!status && counter < interval)
        {
            status = is_fixture_closed(_fixtureController, [site intValue]);
            if (!status)
            {
                ATKLogDebug("is_fixture_closed return false Current Slot: %d status %d", [site intValue], status);
                *error = [self createError:@"is_fixture_closed return false " code:status];
                
            }
            status = is_fixture_engaged(_fixtureController, [site intValue]);
            if (!status)
            {
                ATKLogDebug("is_fixture_engaged return false Current Slot: %d status %d", [site intValue], status);
                *error = [self createError:@"is_fixture_engaged return false " code:status];
              
            }
            counter++;
            [NSThread sleepForTimeInterval:0.5];
        }
    }
    return status;
}

-(NSString *)get_serial_number:(NSError **)error
{
    const char *str = get_serial_number(_fixtureController);
    NSString *SnNum = [NSString stringWithUTF8String:str];
    ATKLog("get_serialNumber Sn: %@",SnNum);
    return SnNum;
}

-(NSString*)get_version:(NSError **)error
{
    const char *str = get_version(_fixtureController);
    NSString *version = [NSString stringWithUTF8String:str];
    ATKLog("get_version Sn: %@",version);
    return version;
}

-(BOOL)relay_switch:(NSString *)netName state:(NSString *)state site:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = relay_switch(_fixtureController, [netName UTF8String],[state UTF8String],[site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(NSNumber *)read_voltage:(NSString *)netName site:(NSNumber *)site error:(NSError **)error
{
    float result = -1;
    @synchronized (_fixtureController) {
        result = read_voltage(_fixtureController, [netName UTF8String], [site intValue]);
    }
    if (result == -1) {
        *error = [self createErrorWithCode:-1];
    }
    return [NSNumber numberWithFloat:result];
}

-(NSNumber *)read_gpio:(NSString *)netName site:(NSNumber *)site error:(NSError **)error
{
    int result = -1;
    @synchronized (_fixtureController) {
        result = read_voltage(_fixtureController, [netName UTF8String], [site intValue]);
    }
    if (result == -1) {
        *error = [self createErrorWithCode:-1];
    }
    return [NSNumber numberWithInt:result];
}

-(BOOL)batt_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_battery_power(_fixtureController, TURN_ON, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)batt_off:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_battery_power(_fixtureController, TURN_OFF, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)usb_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_usb_power(_fixtureController, TURN_ON, [site intValue]);
    }

    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)usb_off:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_usb_power(_fixtureController, TURN_OFF, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)dut_power_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_dut_power(_fixtureController, TURN_ON, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)dut_power_off:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_dut_power(_fixtureController, TURN_OFF, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)set_target_temp:(NSNumber *)temperature site:(NSNumber *)site  error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_target_temp(_fixtureController,[temperature intValue], TURN_ON, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(NSNumber *)get_target_temp:(NSNumber *)site error:(NSError **)error
{
    int temp = -1;
    @synchronized (_fixtureController) {
        temp = get_target_temp(_fixtureController, [site intValue]);
    }
    if (temp < 0) {
        *error = [self createErrorWithCode:temp];
    }
    return [NSNumber numberWithInt:temp];
}

-(BOOL)led_red_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_led_state(_fixtureController, FAIL, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)led_green_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_led_state(_fixtureController, PASS, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)led_inprogress_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_led_state(_fixtureController, INPROGRESS, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)led_gotoFA_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_led_state(_fixtureController, FAIL_GOTO_FA, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)led_panic_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_led_state(_fixtureController, PANIC, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)led_off:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_led_state(_fixtureController, OFF, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}


-(BOOL)enter_diags:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_force_diags(_fixtureController, TURN_ON, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)enter_iboot:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_force_iboot(_fixtureController, TURN_ON, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)enter_dfu:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_force_dfu(_fixtureController, TURN_ON, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)exit_dfu:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_force_dfu(_fixtureController, TURN_OFF, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)set_uart_signal_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_uart_signal(_fixtureController, CLOSE_RELAY, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)ace_provisioning_power_on:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_ace_provisioning_power(_fixtureController, TURN_ON, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)ace_provisioning_power_off:(NSNumber *)site error:(NSError **)error
{
    int status = -1;
    @synchronized (_fixtureController) {
        status = set_ace_provisioning_power(_fixtureController, TURN_OFF, [site intValue]);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)fixture_engage:(NSError **)error
{
    int status = 0;
    @synchronized (_fixtureController) {
        status = fixture_engage(_fixtureController, 0);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)fixture_disengage:(NSError **)error
{
    int status = 0;
    @synchronized (_fixtureController) {
        status = fixture_disengage(_fixtureController, 0);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)fixture_open:(NSError **)error
{
    int status = 0;
    @synchronized (_fixtureController) {
        status = fixture_open(_fixtureController, 0);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(BOOL)fixture_close:(NSError **)error
{
    int status = 0;
    @synchronized (_fixtureController) {
        status = fixture_close(_fixtureController, 0);
    }
    if (status != 0) {
        *error = [self createErrorWithCode:status];
    }
    return status == 0;
}

-(NSError *)createError:(NSString *)failInfo code:(NSInteger)code{
    NSError *failureInfo;
    NSString *errorString = [NSString stringWithFormat:@"%@",failInfo];
    NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                               errorString, NSLocalizedDescriptionKey,
                               errorString, NSLocalizedFailureReasonErrorKey,
                               nil];
    failureInfo = [NSError errorWithDomain:_selfDomain
                                      code:code
                                  userInfo:userInfo];
    return failureInfo;
}

- (NSError *)createErrorWithCode:(NSInteger)code{
    NSError *failureInfo;
    const char* failInfo = get_error_message((int)code);
    NSString *errorString = [NSString stringWithUTF8String:failInfo];
    NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                               errorString, NSLocalizedDescriptionKey,
                               errorString, NSLocalizedFailureReasonErrorKey,
                               nil];
    failureInfo = [NSError errorWithDomain:_selfDomain
                                      code:code
                                  userInfo:userInfo];
    return failureInfo;
}
                                      
-(NSDictionary *)pluginFunctionTable
{
    return _functionTable;
}

-(NSDictionary *)pluginConstantTable
{
    return _constantTable;
}
@end
