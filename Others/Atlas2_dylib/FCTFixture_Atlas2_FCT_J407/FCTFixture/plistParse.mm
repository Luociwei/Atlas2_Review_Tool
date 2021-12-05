#import "plistParse.h"

@implementation plistParse

+(NSDictionary*)parsePlist:(NSString *)file
{
    if(!file)
        file = @"/Users/gdlocal/Library/Atlas2/supportFiles/FCT_HWIO.plist";
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:file];
    return dic;
}

+(NSDictionary *)readAllCMD
{
    NSString *file=@"/Users/gdlocal/Library/Atlas2/supportFiles/FCT_HWIO_test.plist";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:file])
    {
        NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:file];
        NSLog(@"-->file exist at path:%@",file);
        return dic;
    }
    else
    {
        NSDictionary *dic=@{
                            kFIXTUREPORT:@{
                                    @"UUT0":@"169.254.1.32:7801",
                                    @"UUT1":@"169.254.1.33:7801",
                                    @"UUT2":@"169.254.1.34:7801",
                                    @"UUT3":@"169.254.1.35:7801"
                                    },
                            kFIXTURESLOTS:@"4",
    
                            kFIXTUREHWLog:@{
                                    @"UUT0":@"Users/gdlocal/Library/Logs/Atlas/active/group0-slot1/user/hw.txt",  //
                                    @"UUT1":@"/Users/gdlocal/Library/Logs/Atlas/active/group0-slot2/user/hw.txt",
                                    @"UUT2":@"/Users/gdlocal/Library/Logs/Atlas/active/group0-slot3/user/hw.txt",
                                    @"UUT3":@"/Users/gdlocal/Library/Logs/Atlas/active/group0-slot4/user/hw.txt",
                                    },
    
                            kVENDER:@"Suncode",

                            kRESET:@[@"uart_set.stop()",
                                    @"io.set(bit199=1;bit164=1)",
                                    @"gpio.get_safety_main_status()",
                                    @"gpio.get_safety_power_status()",
                                    @"io.set(bit66=0;bit386=0;bit50=0)",
                                    @"blade.dac_set(d,0)",
                                    @"blade.dac_set(a,0)",
                                    @"blade.dac_set(b,0)",
                                    @"blade.dac_set(c,0)",
                                    @"io.set(bit388=0)",
                                    @"pdm.disable()",
                                    @"gpio.set(bit7=0)",
                                    @"io.set(bit389=1;bit60=1;bit390=1)",
                                    @"eload.reset(1",
                                    @"eload.reset(2)",
                                    @"eload.set(1,cc,0)",
                                    @"eload.disable(1)",
                                    @"eload.set(2,cc,0)",
                                    @"eload.disable(2)",
                                    @"io.chip_set(cp1=0;cp3=0;cp4=0;cp5=0;cp6=0;cp7=0;cp8=0;cp9=0;cp11=0;cp12=0;cp13=0;cp14=0;cp15=0;cp16=0;cp25=0;cp26=0)",
                                    @"io.set(bit18=0;bit19=0;bit20=0;bit21=0;bit22=0;bit23=0;bit24=0;bit26=0;bit27=0;bit28=0;bit29=0;bit30=0;bit31=0;bit32=0)",
                                    @"vdm001.reset()",
                                    @"orion.io_set(TX_EN,1)",
                                    @"orion.io_set(PULL_UP,0)",
                                    @"orion.io_set(PULL_DOWN,0)",
                                    @"vdm.change_low_hearder(region0)",
                                    @"vdm.change_source_pdo_count(4)",
                                    @"vdm.tps_write_register_by_addr(0x32,PDO1: Max Voltage,0x02)",
                                    @"io.set(bit390=0)",
                                    @"uart_set.pin_contrl(UUT,disable)",
                                    @"uart_set.pin_contrl(SBELLATRIX,disable)",
                                    @"io.set(bit401=1)",
                                    @"io.set(bit12=1)",
                                    @"io.set(bit199=0;bit129=1;bit403=0;bit404=0;bit164=1)",
                                    @"io.set(bit85=1;bit87=0;bit86=0)",  //BL_LED_GAIN_SET   X1
                                    @"io.set(bit85=0)",                 //BL_LED_GAIN_SET","LOCK"
                                    @"io.set(bit100=1;bit102=0;bit101=0)",   //USB_TARGET_CURR_GAIN_SET    X1
                                    @"io.set(bit100=0)",                  //USB_TARGET_CURR_GAIN_SET","LOCK
                                    @"mcp47fe.output_volt_dc(1,4500)",   //vbus ocp. = 4.5A
                                    @"mcp47fe.output_volt_dc(3,4500)",   //batt ocp *2 = 9.0A
                                    @"mcp47fe.output_volt_dc(2,4500)",   //vbus ovp *4 = 18V
                                    @"mcp47fe.output_volt_dc(4,2300)",   //batt ovp *2 = 4.6V
                                    @"mcp47fe.output_volt_dc(6,2400)",   //batt uvp
                                    @"mcp47fe.output_volt_dc(5,1000)",  //vbus uvp *4 = 4V
                                    @"mcp4442.set_resistance(1,100000)",   //
                                    @"mcp4442.set_resistance(2,100000)",   //
                                    @"mcp4442.set_resistance(3,100000)",   //
                                    @"mcp4442.set_resistance(4,100000)",   //

                                    ],
                            

                        kvdm_read_serial_number:@"vdm001.read_serial_number()",
                        keload_read_serial_number:@"eload004.read_serial_number()",
                        kscope_read_serial_number:@"scope007.read_serial_number()",
                        koab3_read_serial_number:@"oab3.read_serial_number()",
                        kget_xavier_ip:@"xavier.get_ip()",
                        kuart_enable:@"uart_set.pin_contrl(UUT,enable)",
                        kbellatrix_uart_enable:@"uart_set.pin_contrl(SBELLATRIX,enable)",
                        kchange_vdm_pdo_to_1:@"vdm.change_source_pdo_count(1)",
                        kchange_vdm_pdo_to_2:@"vdm.change_source_pdo_count(2)",
                        k5v_to_vdm_exit:@"vdm.change_tx_source_voltage(1,5000,250,PP_HVE)",
                        kchange_pdo2_to_9v2a:@"vdm.change_tx_source_voltage(2,9000,2000,PP_HVE",
                        kchange_pdo_count_to_5:@"vdm.change_low_hearder(region0)",
                        kdisable_usb_cable:@"vdm.tps_write_register_by_addr(0x32,PDO1: Max Voltage,0x02)",
                        kace_reset_h:@"gpio.set(bit7=1)",
                        kace_reset_l:@"gpio.set(bit7=0)",
                        kace_programmer_id:@"ace_fwdl.programmer_id(w25q128)",
                        kace_programmer_erase_mx25v16:@"ace_fwdl.programmer_erase(ch1,mx25v16)",
                        kace_programmer_erase_gd25xxx:@"ace_fwdl.programmer_erase(ch1,gd25xxx)",
                        kace_programmer_erase_w25q128:@"ace_fwdl.programmer_erase(ch1,w25q128)",
                    kace_programmer_only_mx25v16:@"ace_fwdl.programmer_only(ch1,mx25v16,/mix/addon/dut_firmware/ch1/J407-USBC-2.116.0.3-P0_R-AP-S.bin)",
                    kace_programmer_only_gd25xxx:@"ace_fwdl.programmer_only(ch1,gd25xxx,/mix/addon/dut_firmware/ch1/J407-USBC-2.116.0.3-P0_R-AP-S.bin)",
                    kace_programmer_only_w25q128:@"ace_fwdl.programmer_only(ch1,w25q128,/mix/addon/dut_firmware/ch1/J407-USBC-2.116.0.3-P0_R-AP-S.bin)",
                        keload_enable1:@"eload.enable(1)",
                        keload_disable1:@"eload.disable(1)",
                        keload_set_1_cc_200:@"eload.set(1,cc,200)",
                        keload_set_1_cc_0:@"eload.set(1,cc,0)",
                        kace_program_readverify:@"ace_fwdl.program_readverify(ch1,w25q128,/mix/addon/dut_firmware/ch1/ACE_FW,0x00000000,0x7d780)",


                            };
        
        NSLog(@"-->file not exist at path:%@",file);
        return dic;
    }
}


+(void)checkLogFileExist:(NSString *)filePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL isExist = [fm fileExistsAtPath:filePath];
    if (!isExist)
    {
        BOOL ret = [fm createFileAtPath:filePath contents:nil attributes:nil];
        if (ret)
        {
            NSLog(@"create file is successful");
        }
        else
        {
            [fm createDirectoryAtPath:@"/vault/Atlas/FixtureLog/SunCode/" withIntermediateDirectories:YES attributes:nil error:&error];
            [fm createDirectoryAtPath:@"/vault/FixtureLog/SunCode/" withIntermediateDirectories:YES attributes:nil error:&error];
            [fm createFileAtPath:filePath contents:nil attributes:nil];
            NSLog(@"create folder and file is successful");
        }
    }
    else
    {
        NSLog(@"file already exit");
    }
}


+(void)writeLog2File:(NSString *)filePath withTime:(NSString *) testTime andContent:(NSString *)str
{
    NSFileHandle* fh=[NSFileHandle fileHandleForWritingAtPath:filePath];
    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@  %@\r\n",testTime,str] dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}


@end
