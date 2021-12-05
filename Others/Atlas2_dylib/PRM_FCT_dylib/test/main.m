//
//  main.m
//  test
//
//  Created by Kim on 2021/8/15.
//  Copyright © 2021 PRM-JinHui.Huang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlistReader.h"
#import "FCTFixture.h"
#import "RPCController.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
//        system("ps -ef | grep virtualport | grep -v grep | cut -b 7-12 | xargs kill -9");
//        NSLog(@"command done");
        void *controller = create_fixture_controller(0);
        
//        const char * ret= fixture_command(controller, "get_xavier_ip", 100, 2);
//        NSLog(@"uut get_xavier_ip: %s", ret);
//        reset(controller, 1);
// /
        getAndWriteFile(controller, "/mix/addon/dut_firmware/ch1/J407-USBC-2.116.0.1-A1-19-P0-AP-S.bin", "/tmp/dut_firmware/CH1/111.bin", 1, 1000);
//        vdm_set_source_capabilities(controller, 2, "PP_HVE", 500, 100, "None", 1, 1000);
//        rpc_write_read(controller, "fwdl.program_erase(w25q128)", 10000, 1);
//        read_gpio_voltage(controller, "abc", 1);
//        fixture_command(controller, "vdm_read_register_by_address_0x32", 1000, 1);
//        set_battery_voltage(controller, 1, "1-10-1", 1);
//        const char* sn = get_serial_number(controller, 1);
//        NSLog(@"%s", sn);
//        const char* ip = fixture_command(controller, "get_ip", 1000, 1);
//        NSLog(@"%s", ip);
//        relay_switch(controller, "ZYNQ_I2C_EN", "DISCONNECT", 1);
//        read_voltage(controller, "BATT_SNS", 1);
//        hwLog(@"", 1);
//        const char* version = get_version(controller);
//        NSLog(@"%s", version);
//        BOOL check = dut_detect(controller, 1);
//        eload_set(controller, 1, "cc", 0.0, 1);
//        eload_set(controller, 1, "cr", 0.0, 1);
//        eload_set(controller, 1, "cv", 0.0, 1);
//        reset(controller, 1);
////
//        NSString *mode = @"1000-2000-200";
//        NSArray *array = [mode componentsSeparatedByString:@"-"];
//        NSLog(@"%@", array[0]);
        
    }
    return 0;
}
