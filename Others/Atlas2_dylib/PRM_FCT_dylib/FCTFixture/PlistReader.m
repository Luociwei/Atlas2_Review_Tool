//
//  PlistReader.m
//  FCTFixture
//
//  Created by Kim on 2021/8/15.
//  Copyright © 2021 PRM-JinHui.Huang. All rights reserved.
//

#import "PlistReader.h"

@implementation PlistReader

//-(id)initWithFilePath:(NSString *)plistFilePath{
//    if (self = [super init]) {
//        if (!plistFilePath)
//        {
//            NSLog(@"plist file path is necessary!!!");
//            return nil;
//        }
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        if ([fileManager fileExistsAtPath:plistFilePath])
//            _rootContents = [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
//        }
//    return self;
//}

-(id)init{
    if (self = [super init]){
        NSString *PRMTopologyPath = @"/vault/PRMTopology.plist";
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:PRMTopologyPath])
            _rootContents = [NSDictionary dictionaryWithContentsOfFile:PRMTopologyPath];
        else{
            _rootContents = @{
                              @"SLOTS" : @"4",
                              @"HW":@{
                                      @"UUT0":@{@"Xavier":@{@"IP":@"169.254.1.32",@"PORT":@"7801"},
                                                @"HW_LOG":@"/Users/gdlocal/Library/Logs/Atlas/active/group0-slot1/user/hw.txt"},
                                      @"UUT1":@{@"Xavier":@{@"IP":@"169.254.1.33",@"PORT":@"7801"},
                                                @"HW_LOG":@"/Users/gdlocal/Library/Logs/Atlas/active/group0-slot2/user/hw.txt"},
                                      @"UUT2":@{@"Xavier":@{@"IP":@"169.254.1.34",@"PORT":@"7801"},
                                                @"HW_LOG":@"/Users/gdlocal/Library/Logs/Atlas/active/group0-slot3/user/hw.txt"},
                                      @"UUT3":@{@"Xavier":@{@"IP":@"169.254.1.35",@"PORT":@"7801"},
                                                @"HW_LOG":@"/Users/gdlocal/Library/Logs/Atlas/active/group0-slot4/user/hw.txt"}},
                              @"RPCCommandTable":@{
                                // put your fixture command here !!!
                                @"vdm.change_tx_source_voltage(5*5000*3500*PP_HVE)": @"vdm.set_source_capabilities(5,PP_HVE,5000,3500,None)",
                                @"orion.io_set(TX_EN*0)": @"oab3.io_set(TX_EN,0)",
                                @"vdm_read_serial_number": @"vdm.read_serial_number()",
                                @"vdm.change_source_pdo_count(4)": @"vdm.change_source_pdo_count(4)",
                                @"uart_set.config(UUT*1000000*8*1*none*OFF)": @"uart_set.config(UUT,1000000,8,1,none)",
                                @"eload.enable(1)": @"eload.channel_enable(ch1)",
                                @"ace_programmer_erase_gd25xxx": @"ace_fwdl.program_erase(w25q128)",
                                @"eload_set_1_cc_0": @"eload.set_cc(ch1,0)",
                                @"uart_set.write(baud --set 115200\r\n)": @"uart_set.write(baud --set 115200\r\n)",
                                @"disable_usb_cable": @"vdm.write_register_by_address(50,PDO1: Max Voltage,2)",
                                @"uart_set.pin_contrl(UUT*disable)": @"uart_set.pin_control(disable)",
                                @"vdm.change_tx_source_voltage(4*5000*3500*PP_HVE)": @"vdm.set_source_capabilities(4,PP_HVE,5000,3500,None)",
                                @"ace_programmer_only": @"ace_fwdl.program_only(w25q128,/mix/addon/dut_firmware/ch1/J407-USBC-2.116.0.1-A1-19-P0-AP-S.bin,0)",
                                @"orion.io_set(PULL_DOWN*0)": @"oab3.io_set(PULL_DOWN,0)",
                                @"eload.set(1,cr,3.3)": @"eload.set_cr(ch1,3.3)",
                                @"pdm.disable()": @"pdm.disable()",
                                @"pdm.enable(1000,-25,2400000)": @"pdm.enable(1000,-25,2400000)",
                                @"5v_to_vdm_exit": @"vdm.set_source_capabilities(1,PP_HVE,5000,250,None)",
                                @"ace_programmer_erase_mx25v16": @"ace_fwdl.program_erase(mx25v16)",
                                @"pdm.enable(1000*-25*2400000)": @"pdm.enable(1000,-25,2400000)",
                                @"uart_set.write(\r\n)": @"uart_set.write(\r\n)",
                                @"get_xavier_ip": @"xavier.get_ip()",
                                @"uart_set.pin_contrl(UUT*enable)": @"uart_set.pin_control(enable)",
                                @"blade.frequency_measure_config(low)": @"psu.frequency_measure_config(low)",
                                @"iic_slave.salve_config(channel1*85)": @"iic_slave.salve_config(channel1,85)",
                                @"orion.aid_fw_control(SWITCH2HS)": @"oab3.communicate(SWITCH2HS)",
                                @"change_vdm_pdo_to_5": @"vdm.change_source_pdo_count(5)",
                                @"ace_program_readverify": @"ace_fwdl.program_readverify(w25q128,/mix/addon/dut_firmware/ch1/ACE_FW,0x00000000,0x7d780)",
                                @"change_vdm_pdo_to_4": @"vdm.change_source_pdo_count(4)",
                                @"orion.aid_fw_control(WAITFORID)": @"oab3.communicate(WAITFORID)",
                                @"eload_ch1_disable": @"eload.channel_disable(ch1)",
                                @"eload.set(1,cc,0)": @"eload.set_cc(ch1,0)",
                                @"uart_enable": @"uart_set.pin_control(enable)",
                                @"eload_disable1": @"eload.channel_disable(ch1)",
                                @"change_vdm_pdo_to_3": @"vdm.change_source_pdo_count(3)",
                                @"eload.set(2,cc,50)": @"eload.set_cc(ch2,50)",
                                @"vdm.change_source_pdo_count(1)": @"vdm.change_source_pdo_count(1)",
                                @"vdm.tps_write_register_by_addr(0x32,PDO1: Max Voltage,0x02)": @"vdm.write_register_by_address(50,PDO1: Max Voltage,2)",
                                @"eload.set(2,cc,0)": @"eload.set_cc(ch2,0)",
                                @"vdm.tps_write_register_by_addr(0x32*PDO1: Max Voltage*0x02)": @"vdm.write_register_by_address(50,PDO1: Max Voltage,2)",
                                @"change_vdm_pdo_to_2": @"vdm.change_source_pdo_count(2)",
                                @"ace_programmer_id": @"ace_fwdl.program_id(w25q128)",
                                @"eload.enable(2)": @"eload.channel_enable(ch2)",
                                @"vdm.change_tx_source_voltage(3*5000*3500*PP_HVE)": @"vdm.set_source_capabilities(3,PP_HVE,5000,3500,None)",
                                @"orion_aid_fw_control_start": @"orion.aid_fw_control(start)",
                                @"change_vdm_pdo_to_1": @"vdm.change_source_pdo_count(1)",
                                @"vdm.change_source_pdo_count(3)": @"vdm.change_source_pdo_count(3)",
                                @"uart_disable": @"uart_set.pin_control(disable)",
                                @"orion.io_set(PULL_UP*1)": @"oab3.io_set(PULL_UP,1)",
                                @"uart_set.config(UUT,115200,8,1,none,OFF)": @"uart_set.config(UUT,115200,8,1,none)",
                                @"uart_set.pin_contrl(SBELLATRIX*disable)": @"uart_set.pin_control(disable)",
                                @"eload.disable(1)": @"eload.channel_disable(ch1)",
                                @"eload_ch1_enable": @"eload.channel_enable(ch1)",
                                @"orion.orion_module_init()": @"oab3.reset()",
                                @"vdm.change_source_pdo_count(5)": @"vdm.change_source_pdo_count(5)",
                                @"uart_set.write(ABCD)": @"uart_set.write(ABCD)",
                                @"vdm.change_tx_source_voltage(2*5000*3500*PP_HVE)": @"vdm.set_source_capabilities(2,PP_HVE,5000,3500,None)",
                                @"vdm.show_tps_register_by_addr(0x34)": @"vdm.read_register_by_address(52)",
                                @"change_pdo2_to_9v2a": @"vdm.set_source_capabilities(2,PP_HVE,9000,2000,None)",
                                @"ace_reset_l": @"baseboard.gpio_set_level(ace_hearst,0)",
                                @"vdm.change_low_hearder(region1)": @"vdm.set_firmware_region_pointer(region1)",
                                @"pdm.enable(1000*-100*2400000)": @"pdm.enable(1000,-100,2400000)",
                                @"gpio.set(bit7=0)": @"baseboard.gpio_set_level(ace_hearst,0)",
                                @"eload004.read_serial_number()": @"eload_004.read_serial_number()",
                                @"eload.set(1,cc,400)": @"eload.set_cc(ch1,400)",
                                @"ace_programmer_erase_w25q128": @"ace_fwdl.program_erase(w25q128)",
                                @"bellatrix_uart_enable": @"uart_set.pin_control(enable)",
                                @"orion.io_set(TX_EN*1)": @"oab3.io_set(TX_EN,1)",
                                @"uart_set.pin_contrl(UUT,enable)": @"uart_set.pin_control(enable)",
                                @"bellatrix_uart_disable": @"uart_set.pin_control(disable)",
                                @"ace_reset_h": @"baseboard.gpio_set_level(ace_hearst,1)",
                                @"orion.io_set(PULL_DOWN*1)": @"oab3.io_set(PULL_DOWN,1)",
                                @"orion.width_measure_control(0)": @"oab3.aid_connect_set(disable)",
                                @"uart_set.write(EXIT)": @"uart_set.write(EXIT)",
                                @"vdm.change_tx_source_voltage(1*5000*3500*PP_HVE)": @"vdm.set_source_capabilities(1,PP_HVE,5000,3500,None)",
                                @"orion_aid_fw_control_stop": @"orion.aid_fw_control(stop)",
                                @"scope_read_serial_number": @"blade.read_serial_number()",
                                @"orion.aid_fw_control(stop)": @"oab3.close()",
                                @"eload.set(2,cc,450)": @"eload.set_cc(ch2,450)",
                                @"eload.disable(2)": @"eload.channel_disable(ch2)",
                                @"blade.frequency_measure_config(high)": @"psu.frequency_measure_config(high)",
                                @"uart_set.pin_contrl(SBELLATRIX*enable)": @"uart_set.pin_control(enable)",
                                @"eload_read_serial_number": @"eload_004.read_serial_number()",
                                @"orion.io_set(PULL_UP*0)": @"oab3.io_set(PULL_UP,0)",
                                @"vdm.change_low_hearder(region0)": @"vdm.set_firmware_region_pointer(region0)",
                                @"change_pdo_count_to_5": @"vdm.set_firmware_region_pointer(region0)",
                                @"scope007.read_serial_number()": @"blade.read_serial_number()",
                                @"oab3_read_serial_number": @"oab3.read_serial_number()",
                                @"uart_set.config(UUT*115200*8*1*none*OFF)": @"uart_set.config(UUT,115200,8,1,none)",
                                @"gpio.set(bit7=1)": @"baseboard.gpio_set_level(ace_hearst,1)",
                                @"orion.aid_fw_control(start)": @"oab3.open()",
                                @"vdm.change_source_pdo_count(2)": @"vdm.change_source_pdo_count(2)"
                                
                                  
                                  
                              }
                            
            };
        }
    }
    return self;
}

-(id)getItemsByKey:(NSString *)key{
    return [_rootContents objectForKey:key];
}



@end
