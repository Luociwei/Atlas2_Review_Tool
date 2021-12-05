//
//  GeneralConfig.m
//  FCTFixture
//
//  Created by ben on 2019/2/12.
//  Copyright © 2019 Jackie wang. All rights reserved.
//

#import "GeneralConfig.h"

@interface GeneralConfig ()
{
# pragma mark - Invisible variables
    NSDictionary *_generateData;
}

@end

@implementation GeneralConfig

+(GeneralConfig *) instance {
    static GeneralConfig *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[GeneralConfig alloc] init];
    });
    
    return _instance;
}

-(instancetype) init
{
    self = [super init];
    if (self) {
        [self loadProfile];
    }
    return self;
}

- (void)loadProfile {
    NSString *path=@"/Users/gdlocal/Library/Atlas2/supportFiles/GeneralConfig.json";

    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data)
        {
            _generateData = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingAllowFragments error:nil];
            return;
        }
        
       
    }
    //default value
    _generateData =@{
                    @"SelectedFixture" : @1,
                    @"Fixture List" : @[
                        @[
                        @{
                            @"slot" : @"1",
                            @"MLB" : @[
                            @"/tmp/dev/DUT10",
                            @"115200"
                            ],
                            @"MCU" : @[
                            @"usbserial-MCU10",
                            @"115200"
                            ],
                            @"DCSD" : @{
                            @"Macmini7,1" : @[ @"0x14710000" ],
                            @"Macmini6,2" : @[ @"0x1a131000" ],
                            @"Macmini6,1" : @[ @"0x1a131000" ],
                            @"Macmini8,1" : @[ @"0x14310000" ],
                            }
                        },
                        @{
                            @"slot" : @"2",
                            @"MLB" : @[
                            @"/tmp/dev/DUT11",
                            @"115200"
                            ],
                            @"MCU" : @[
                            @"usbserial-MCU11",
                            @"115200"
                            ],
                            @"DCSD" : @{
                            @"Macmini7,1" : @[ @"0x14720000" ],
                            @"Macmini6,2" : @[ @"0x1a132000" ],
                            @"Macmini6,1" : @[ @"0x1a132000" ],
                            @"Macmini8,1" : @[ @"0x14320000" ],
                            }
                        },
                        @{
                            @"slot" : @"3",
                            @"MLB" : @[
                            @"/tmp/dev/DUT12",
                            @"115200"
                            ],
                            @"MCU" : @[
                            @"usbserial-MCU12",
                            @"115200"
                            ],
                            @"DCSD" : @{
                            @"Macmini7,1" : @[ @"0x14730000" ],
                            @"Macmini6,2" : @[ @"0x1a133000" ],
                            @"Macmini6,1" : @[ @"0x1a133000" ],
                            @"Macmini8,1" : @[ @"0x14330000" ],
                            }
                        },
                        @{
                            @"slot" : @"4",
                            @"MLB" : @[
                            @"/tmp/dev/DUT13",
                            @"115200"
                            ],
                            @"MCU" : @[
                            @"usbserial-MCU13",
                            @"115200"
                            ],
                            @"DCSD" : @{
                            @"Macmini7,1" : @[ @"0x14740000" ],
                            @"Macmini6,2" : @[ @"0x1a134000" ],
                            @"Macmini6,1" : @[ @"0x1a134000" ],
                            @"Macmini8,1" : @[ @"0x14340000" ],
                            }
                        }
                        ]
                    ]
                };
    
}

-(NSString *) uartPath:(int)slot {
    NSString *_path;
    @synchronized (@"reading") {
//        NSInteger selectedIndex = [[_generateData objectForKey:@"SelectedFixture"] intValue];
        NSArray *arr = [_generateData objectForKey:@"Fixture List"][0];
        NSDictionary *slotDic = [arr objectAtIndex:slot-1];
        NSArray *mlbArr = slotDic[@"MLB"];
//        NSArray *uartArr = mlbDic[@"UART"];
//        NSArray *xavierArr = mlbDic[@"XAVIER"];
        _path = [mlbArr objectAtIndex:0];
    }
    
    return _path;
}

-(NSString *) mlbPath:(int)slot {
    NSString *_path;
    @synchronized (@"reading") {
        //        NSInteger selectedIndex = [[_generateData objectForKey:@"SelectedFixture"] intValue];
        NSArray *arr = [_generateData objectForKey:@"Fixture List"][0];
        NSDictionary *slotDic = [arr objectAtIndex:slot-1];
        NSArray *mcuArr = slotDic[@"MCU"];
        _path = [mcuArr objectAtIndex:0];
    }
    
    return _path;
}

-(NSString*)macmini_hardware_version
{
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    NSString* cmd = [NSString stringWithFormat:@"system_profiler SPHardwareDataType"]; // if you want to find usb port name ,prelikestring = cu.usb*
    
    NSArray* arguments = [NSArray arrayWithObjects:@"-c" ,cmd , nil];
    [task setArguments:arguments];
    
    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle* file = [pipe fileHandleForReading];
    [task launch];
    [task waitUntilExit];
    NSString* hardware_info = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"Model Identifier:\\s+(\\w+,\\w+)" options:0 error:nil];
    NSTextCheckingResult *ckResult = [regex firstMatchInString:hardware_info options:0 range:NSMakeRange(0, hardware_info.length)];
    NSString* macmini_v = @"Macmini7,1";
    if (ckResult.range.location != NSNotFound)
    {
        macmini_v = [hardware_info substringWithRange:[ckResult rangeAtIndex:ckResult.numberOfRanges - 1]];
    }
    
    return macmini_v;
}

-(NSString *)locationID:(int)slot {
    NSString *_path;
    @synchronized (@"reading") {
        //        NSInteger selectedIndex = [[_generateData objectForKey:@"SelectedFixture"] intValue];
        NSArray *arr = [_generateData objectForKey:@"Fixture List"][0];
        NSDictionary *slotDic = [arr objectAtIndex:slot-1];
        NSDictionary *dcsdDic = slotDic[@"DCSD"];
        _path = [dcsdDic objectForKey:[self macmini_hardware_version]][0];
    }
    
    return _path;
}

@end
