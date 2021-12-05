#import "plistParse.h"

@implementation plistParse

+(NSDictionary*)parsePlist:(NSString *)file
{
    if(!file)
        file = @"/usr/local/lib/DFUFixtureCmd.plist";
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:file];
    return dic;
}

+(NSDictionary *)readAllCmdsWithFile:(NSString *)file
{
    if (!file.length) {
        file=@"/Users/gdlocal/Library/Atlas/supportFiles/DFUFixtureCmd.plist";
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:file])
    {
//        NSString *path = [[NSBundle mainBundle]pathForResource:@"DFUFixtureCmd.plist" ofType:nil];
//
        NSDictionary * dic = [[NSDictionary alloc] initWithContentsOfFile:file];
        NSLog(@"-->file exist at path:%@",file);
        NSLog(@"%@",dic);
        return dic;
    }
    else
    {
        NSDictionary *dic=@{kFIXTUREPORT:@{//@"UUT0":@"/dev/cu.usbserial",  //debug
                                    @"UUT0":@"/dev/cu.usbserial-MCUAA",
                                    @"UUT1":@"/dev/cu.usbserial-MCUAB",
                                    @"UUT2":@"/dev/cu.usbserial-MCUAC",
                                    @"UUT3":@"/dev/cu.usbserial-MCUAD",
                                    @"UUT4":@"/dev/cu.usbserial-MCUBA",
                                    @"UUT5":@"/dev/cu.usbserial-MCUBB",
                                    @"UUT6":@"/dev/cu.usbserial-MCUBC",
                                    @"UUT7":@"/dev/cu.usbserial-MCUBD"},
                            kFIXTURESETTING:@"115200,8,n,1",
                            kFIXTURESLOTS:@"8", 
                            
                            kAPPLEIDOFF:@[@"IO SET(3,BIT11=0,BIT12=0,BIT13=0)"],
                            kAPPLEIDON:@[@"IO SET(3,BIT11=1,BIT12=1,BIT13=1)"],
                            
                            kBATTERYPOWEROFF:@[@"IO SET(2,BIT14=0,BIT15=0)"],
                            kBATTERYPOWERON:@[@"IO SET(2,BIT14=1,BIT15=1)"],
                            
                            kCONNDETGNDOFF:@[@""],
                            kCONNDETGNDON:@[@""],
                            
                            kDUTPOWEROFF:@[@""],
                            kDUTPOWERON:@[@""],
                            
                            kFORCEDFUOFF:@[@"IO SET(6,BIT16=0,BIT14=0,BIT15=0,BIT3=0,BIT5=0,BIT11=0)",
                                           @"IO SET(3,BIT12=0,BIT13=0,BIT25=0)",
                                           @"IO SET(1,BIT20=1)"],
                            
                            kFORCEDFUON:@[@"IO SET(1,BIT25=0)",
                                          @"IO SET(8,BIT20=0,BIT3=0,BIT5=0,BIT11=0,BIT12=0,BIT13=0,BIT14=0,BIT15=0)",
                                          @"IO SET(1,BIT25=0)",
                                          @"IO SET(8,BIT20=0,BIT3=0,BIT5=0,BIT11=0,BIT12=0,BIT13=0,BIT14=0,BIT15=0)",
                                          @"Delay:0.5",
                                          @"IO SET(8,BIT14=1,BIT15=1,BIT3=1,BIT5=0,BIT11=1,BIT12=1,BIT13=1)",
                                          @"IO SET(8,BIT14=1,BIT15=1,BIT3=1,BIT5=0,BIT11=1,BIT12=1,BIT13=1)",
                                          @"IO SET(1,BIT25=1)",
                                          @"IO SET(1,BIT25=1)"],
                            
                                                      
                            kFORCEDIAGSOFF:@[@"IO SET(6,BIT16=0,BIT14=0,BIT15=0,BIT3=0,BIT5=0,BIT11=0)",
                                             @"IO SET(3,BIT12=0,BIT13=0,BIT25=0)",
                                             @"IO SET(1,BIT20=1)"],
                            
                            kFORCEDIAGSON:@[@"IO SET(1,BIT25=0)",
                                            @"IO SET(1,BIT25=0)",
                                            @"IO SET(8,BIT20=1,BIT3=0,BIT5=0,BIT11=0,BIT12=0,BIT13=0,BIT14=0,BIT15=0)",
                                            @"IO SET(8,BIT20=1,BIT3=0,BIT5=0,BIT11=0,BIT12=0,BIT13=0,BIT14=0,BIT15=0)",
                                            @"Delay:0.5",
                                            @"IO SET(8,BIT14=1,BIT15=1,BIT3=1,BIT5=0,BIT11=1,BIT12=1,BIT13=1)",
                                            @"IO SET(8,BIT14=1,BIT15=1,BIT3=1,BIT5=0,BIT11=1,BIT12=1,BIT13=1)",
                                            @"IO SET(1,BIT25=1)",
                                            @"IO SET(1,BIT25=1)"],
                            
                            kFORCEIBOOTOFF:@[@""],
                            kFORCEIBOOTON:@[@""],
                            
                            kHI5OFF:@[@""],
                            kHI5ON:@[@""],
                            
                            kINIT:@[@"IO SET(8,BIT20=1,BIT3=0,BIT5=0,BIT11=0,BIT12=0,BIT13=0,BIT14=0,BIT15=0)",
                                    @"IO SET(1,BIT25=0)"],
                            
                            kLEDSTATE:@{kFAIL:@[@"IO SET(3,BIT22=0,BIT23=1,BIT24=1)",
                                                @"IO SET(3,BIT22=0,BIT23=1,BIT24=1)"],
                                        
                                        kFAILGOTOFA:@[@"IO SET(3,BIT22=0,BIT23=0,BIT24=0)",
                                                      @"IO SET(3,BIT22=0,BIT23=0,BIT24=0)"],
                                        
                                        kINPROCESS:@[@"IO SET(3,BIT22=1,BIT23=0,BIT24=1)",
                                                     @"IO SET(3,BIT22=1,BIT23=0,BIT24=1)"],
                                        
                                        kOFF:@[@"IO SET(3,BIT22=1,BIT23=1,BIT24=1)",
                                               @"IO SET(3,BIT22=1,BIT23=1,BIT24=1)"],
                                        
                                        kPANIC:@[@"IO SET(3,BIT22=1,BIT23=1,BIT24=1)",
                                                 @"IO SET(3,BIT22=1,BIT23=1,BIT24=1)"],
                                        
                                        kPASS:@[@"IO SET(3,BIT22=1,BIT23=1,BIT24=0)",
                                                @"IO SET(3,BIT22=1,BIT23=1,BIT24=0)"]},
                            
                            kRESET:@[@"IO SET(6,BIT16=0,BIT14=0,BIT15=0,BIT3=0,BIT5=0,BIT11=0)",
                                     @"IO SET(3,BIT12=0,BIT13=0,BIT25=0)",
                                     @"IO SET(1,BIT25=0)",
                                     @"IO SET(1,BIT20=1)"],
                            
                            kSERIAL:@"TBD",
                            
                            kUARTPATH:@{@"UUT0":@"/dev/cu.usbserial-0001A",
                                        @"UUT1":@"/dev/cu.usbserial-0001B",
                                        @"UUT2":@"/dev/cu.usbserial-0001C",
                                        @"UUT3":@"/dev/cu.usbserial-0001D",
                                        @"UUT4":@"/dev/cu.usbserial-0002A",
                                        @"UUT5":@"/dev/cu.usbserial-0002B",
                                        @"UUT6":@"/dev/cu.usbserial-0002C",
                                        @"UUT7":@"/dev/cu.usbserial-0002D"},
                            
                            kUARTSIGNALOFF:@[@""],
                            kUARTSIGNALON:@[@""],
                            
                            kUSBLOCATION:@{@"UUT0":@"0xfd131000",
                                           @"UUT1":@"0xfd132000",
                                           @"UUT2":@"0xfd133000",
                                           @"UUT3":@"0xfd134000",
                                           @"UUT4":@"0xfa121000",
                                           @"UUT5":@"0xfa122000",
                                           @"UUT6":@"0xfa123000",
                                           @"UUT7":@"0xfa124000"},
                            
                            kUSBPOWEROFF:@[@"IO SET(1,BIT25=0)"],
                            kUSBPOWERON:@[@"IO SET(1,BIT8=1)",
                                          @"IO SET(1,BIT25=1)"],
                            
                            kUSBSIGNALOFF:@[@""],
                            kUSBSIGNALON:@[@""],
                            
                            kVENDER:@"IA",
                            kVERSION:@"2.1"  //YP 20161108
                            
                            };
        
        NSLog(@"-->file not exist at path:%@",file);
        return dic;
    }
}

@end
