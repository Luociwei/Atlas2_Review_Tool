//
//  fixtureControl.m
//  Eowyn
//
//  Created by gdlocal on 2021/6/17.
//  Copyright © 2021 gdlocal. All rights reserved.
//

#import "fixtureControl.h"


#define IN_GPIO 8
#define OUT_GPIO 9
#define DOWN_GPIO 10
#define UP_GPIO 11

#define elect_magnet 13
#define FAN_IN_GPIO 13
#define FAN_OUT_GPIO 14

#define UP_SENSOR 0
#define DOWN_SENSOR 1
#define IN_SENSOR 2
#define OUT_SENSOR 3
#define RESET_SENSOR 4
#define FAN_IN_SENSOR 5
#define FAN_OUT_SENSOR 6

#define GPIO_ON ATDeviceDIOHigh
#define GPIO_OFF ATDeviceDIOLow
#define IN_OUT_SENSOR_ON 1
#define IN_OUT_SENSOR_OFF 0
#define UP_DOWN_SENSOR_ON 1
#define UP_DOWN_SENSOR_OFF 0
#define FAN_IN_OUT_SENSOR_ON 1
#define FAN_IN_OUT_SENSOR_OFF 0

#define IN_STATE 1
#define OUT_STATE 2
#define DOWN_STATE 3
#define UNREADY_STATE 4

#define DUT1_STATE 5
#define DUT2_STATE 6
#define DUT3_STATE 7
#define DUT4_STATE 8


@implementation fixtureControl


-(id)init
{
    self = [super init];
    if (self)
    {
        m_lock = [[NSLock alloc]init];
        GPIO = @{
                 @"IN_GPIO": @8,
                 @"OUT_GPIO": @9,
                 @"DOWN_GPIO": @10,
                 @"UP_GPIO": @11,
                 
                 @"UP_SENSOR":@0,
                 @"DOWN_SENSOR": @1,
                 @"IN_SENSOR": @2,
                 @"OUT_SENSOR": @3,
                 @"RESET_SENSOR": @4,
                 @"FAN_IN_SENSOR": @5,
                 @"FAN_OUT_SENSOR": @6,
                 
                 @"DUT1_STATE": @5,
                 @"DUT2_STATE": @6,
                 @"DUT3_STATE": @7,
                 @"DUT4_STATE": @8,
                 @"GPIO_ON":@"ATDeviceDIOHigh",
                 @"GPIO_OFF":@"ATDeviceDIOLow"
                 };
        
        logPath = nil;

    }
    return self;
    
}

-(BOOL)initialI2C:(eowynController * )eowyn :(NSString *)connectIP
{
    BOOL success = NO;
    success = [eowyn connectWithIP:connectIP];
    if(!success) return NO;
    [eowyn configI2C];
    return YES;
}

-(BOOL)PingIPAddress:(NSString *)ip
{
    NSString *txtPath = @"/vault/Atlas/SunCode_FixtureControlIP.txt";
    NSString *pingIP = [NSString stringWithFormat:@"/sbin/ping -c 2 %@ > %@",ip,txtPath];
    system([pingIP UTF8String]);
    NSString *retPing =  [NSString stringWithContentsOfFile:txtPath encoding:NSUTF8StringEncoding error:nil];
    if ([retPing rangeOfString:@"received, 0.0% packet loss"].location != NSNotFound)
    {
        return YES;
    }
    return NO;
}

-(void)writeFixtureLogs:(NSString *)str
{
    if(logPath)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY_MM_dd"];
        NSDate *datenow = [NSDate date];
        NSString *currentTimeString = [formatter stringFromDate:datenow];
        NSString *filePath=[NSString stringWithFormat:@"%@_%@.txt",logPath,currentTimeString];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:filePath];
        if (!fh)
        {
            NSFileManager *fm=[NSFileManager defaultManager];
            [fm createFileAtPath:filePath contents:nil attributes:nil];
            fh = [NSFileHandle fileHandleForWritingAtPath:filePath];
        }
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        NSDate *datenow2 = [NSDate date];
        NSString *currentTimeString2 = [formatter stringFromDate:datenow2];
        
        [fh seekToEndOfFile];
        [fh writeData:[[NSString stringWithFormat:@"%@ \t%@\r\n",currentTimeString2,str]  dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
        //[formatter release];
    }
    
}


-(int)initFixtureControl:(NSString *)ip withLogPath:(NSString *)path
{
    eowyn = [[eowynController alloc] init];
    ipOk = [self PingIPAddress:ip];
    logPath = path;
    if (ipOk)
    {
        for (int i=0; i<3; i++)
        {
            BOOL success = [self initialI2C:eowyn :ip];
            if(success)
            {
                NSLog(@"Connect success for IP %@",ip);
                break;
            }
            if (i==2)
            {
                if(!success)
                {
                    NSLog(@"ERROR,Connect Fail for IP %@",ip);
                    return -1;
                }
            }
            [NSThread sleepForTimeInterval:0.5];
        }
    }
    else
    {
        NSLog(@"ping IP %@ failed,error!!!",ip);
    }
    return 0;
}



#pragma mark command list


-(NSString *)SendReadString:(NSString *)cmd
{
    [self writeFixtureLogs:[NSString stringWithFormat:@"[send] : %@",cmd]];
    if (!ipOk)
    {
        NSLog(@"ping failed: %@",cmd);
        return [NSString stringWithFormat:@"%@ failed*_*",cmd];
    }

    [m_lock lock];
    if ([cmd containsString:@"fixture_init"])
    {
        [self fixture_up];
        [self fixture_out];
        [m_lock unlock];
        return @"done";
    }
    else if ([cmd containsString:@"force_press"] ||[cmd containsString:@"force_close"] )
    {
          [self fixture_in];
          [self fixture_down];
          [m_lock unlock];
          return @"done";
          
      }
    else if ([cmd containsString:@"force_release"] || [cmd containsString:@"force_open"])
    {
          [self fixture_up];
          int result  = [self fixture_out];
          [m_lock unlock];

          if (result == 0)
         {
             return @"done";

         }
         else
         {
             return @"error";

         }
        
    }
    
    else if ([cmd containsString:@"force_in"])
    {
        [self fixture_in];
        [m_lock unlock];
        return @"done";
    }
    else if ([cmd containsString:@"force_out"])
    {
        
        [self fixture_out];
        [m_lock unlock];
       return @"done";
    }
    else if ([cmd containsString:@"force_up"])
    {
        [self fixture_up];
        [m_lock unlock];
        return @"done";
    }
    else if ([cmd containsString:@"force_down"])
    {
        
        [self fixture_down];
        [m_lock unlock];
       return @"done";
    }
    
    else if ([cmd containsString:@"press"] ||[cmd containsString:@"close"])
    {
       
        int in_result = [self fixture_in];
        int down_result = -1;
        if (in_result == 0)
        {
            down_result  = [self fixture_down];
        }
        [m_lock unlock];
        if (down_result == 0)
        {
            return @"done";
        }
        else
        {
            return @"error";
        }
        
    }
    else if ([cmd containsString:@"release"]||[cmd containsString:@"open"])
    {
        
        [self fixture_up];
        [self fixture_out];
        [m_lock unlock];
        return @"done";
    }
    else if ([cmd containsString:@"in"])
    {
        
        [self fixture_in];
        [m_lock unlock];
        return @"done";
    }
    else if ([cmd containsString:@"out"])
    {
        [self fixture_out];
        [m_lock unlock];
        return @"done";
    }
    else if ([cmd containsString:@"up"])
    {
        [self fixture_up];
        [m_lock unlock];
        return @"done";
    }
    else if ([cmd containsString:@"down"])
    {
        [self fixture_down];
        [m_lock unlock];
       return @"done";
    }
    else if ([cmd containsString:@"elect_magnet_off"])
    {
       [self writeIO:elect_magnet value:GPIO_OFF];
       [m_lock unlock];
       return @"done";
    }
    else if ([cmd containsString:@"elect_magnet_on"])
    {
       [self writeIO:elect_magnet value:GPIO_ON];
       [m_lock unlock];
       return @"done";
    }
    else if ([[cmd lowercaseString] containsString:@"get_dut1_status"])
    {
        ATDeviceDIOType io_status = [self readDutIO:DUT1_STATE];
        //NSLog(@"get_dut1_status: cmd %@ %d",cmd,io_status);
        [m_lock unlock];
        return [NSString stringWithFormat:@"%d",io_status];
    }
    else if ([[cmd lowercaseString] containsString:@"get_dut2_status"])
    {
        ATDeviceDIOType io_status = [self readDutIO:DUT2_STATE];
        [m_lock unlock];
        return [NSString stringWithFormat:@"%d",io_status];
    }
    else if ([[cmd lowercaseString] containsString:@"get_dut3_status"])
    {
        ATDeviceDIOType io_status = [self readDutIO:DUT3_STATE];
        [m_lock unlock];
        return [NSString stringWithFormat:@"%d",io_status];
    }
    else if ([[cmd lowercaseString] containsString:@"get_dut4_status"])
    {
        ATDeviceDIOType io_status = [self readDutIO:DUT4_STATE];
        [m_lock unlock];
        return [NSString stringWithFormat:@"%d",io_status];
    }
    else if ([[cmd lowercaseString] containsString:@"led"])
    {
        NSString *strx = nil;
        NSString *stry = nil;
        NSString *strz = nil;
        
        NSString *apattern = @"(\\D+)led(\\D+)(\\d)";
        NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:apattern options:NSRegularExpressionCaseInsensitive error:nil];
        //获取匹配结果
        NSArray *results = [regular matchesInString:cmd options:0 range:NSMakeRange(0, cmd.length)];
        for (NSTextCheckingResult *result in results) {
            strx = [cmd substringWithRange:[result rangeAtIndex:1]];
            stry = [cmd substringWithRange:[result rangeAtIndex:2]];
            strz = [cmd substringWithRange:[result rangeAtIndex:3]];
        }
        if(strx && stry && strz)
        {
            [self SetLedWithColor:strx uut:strz];
        }
        [m_lock unlock];
        return @"done";
    }
    else if ([[cmd lowercaseString] containsString:@"read sensor"])  // for automation line
    {
        ATDeviceDIOType up_sensor = [self readIO:UP_SENSOR];
        if (up_sensor == ATDeviceDIOUnknown)
        {
            [m_lock unlock];
            return @"0000*_*";
        }
        ATDeviceDIOType in_sensor = [self readIO:IN_SENSOR];
        if (in_sensor == ATDeviceDIOUnknown)
        {
            [m_lock unlock];
            return @"0000*_*";
        }
        ATDeviceDIOType down_sensor = [self readIO:DOWN_SENSOR];
        if (down_sensor == ATDeviceDIOUnknown)
        {
            [m_lock unlock];
            return @"0000*_*";
        }
        ATDeviceDIOType out_sensor = [self readIO:OUT_SENSOR];
        if (out_sensor == ATDeviceDIOUnknown)
        {
            [m_lock unlock];
            return @"0000*_*";
        }
        [m_lock unlock];
        NSString *ret = [NSString stringWithFormat:@"%d%d%d%d*_*",down_sensor,up_sensor,in_sensor,out_sensor];
        return ret;
    }
    /*else if ([[cmd lowercaseString] containsString:@"fixture_reset_button"])  // for check fixture reset button is press or not
    {
        ATDeviceDIOType reset_status = [self readIO:RESET_SENSOR];
        if (reset_status)   // 1 is means not press button; 0 is means press button
        {
            start_time = [[NSDate date]timeIntervalSince1970];
        }
        double now_time = [[NSDate date]timeIntervalSince1970];
        if (now_time - start_time>5)  // bigger than 5 s
        {
            start_time = [[NSDate date]timeIntervalSince1970];
            [self SendReset];
            [self fixture_up];
            [self fixture_out];
            start_time = [[NSDate date]timeIntervalSince1970];
        }
        [m_lock unlock];
        return [NSString stringWithFormat:@"%d",reset_status];
    }*/
    else
    {
        [m_lock unlock];
        return @"command not support";
    }
    
}

-(void)fixture_cyliner_init
{
    ATDeviceDIOType up_sensor = [self readIO:UP_SENSOR];
    if (up_sensor == ATDeviceDIOUnknown)
    {
        return;
    }
    ATDeviceDIOType in_sensor = [self readIO:IN_SENSOR];
    if (in_sensor == ATDeviceDIOUnknown)
    {
        return ;
    }
    ATDeviceDIOType down_sensor = [self readIO:DOWN_SENSOR];
    if (down_sensor == ATDeviceDIOUnknown)
    {
        return ;
    }
    ATDeviceDIOType out_sensor = [self readIO:OUT_SENSOR];
    if (out_sensor == ATDeviceDIOUnknown)
    {
        return ;
    }
    NSString *ret = [NSString stringWithFormat:@"%d%d%d%d",down_sensor,up_sensor,in_sensor,out_sensor];
    if ([ret isEqualToString:@"0110"])
    {
        NSLog(@"up and in status");
    }
    else if ([ret isEqualToString:@"1010"])  // close
    {
        [self fixture_up];
    }
    else if ([ret isEqualToString:@"0101"])  // open
    {
        [self fixture_in];
    }
    
}

-(void)LED_Reset
{
    [eowyn writeI2CWithString:@"02ffff" writeadd:0x42 writelen:3 busId:0];
    current_low_state=@"ff";
    current_high_state=@"ff";
}

-(NSString *)charToString:(char )hex_char{
    
    NSString *mut_hex = [NSString stringWithFormat:@"%02x",hex_char];
    NSString *hex = @"";
    if (mut_hex.length==8 && [mut_hex containsString:@"ffffff"]) {
        hex=[mut_hex stringByReplacingOccurrencesOfString:@"ffffff" withString:@""];
    }
    return hex;
}
/**
 十六进制转换为二进制
 @param hex 十六进制数
 @return 二进制数
 */
- (NSString *)getBinaryByHex:(NSString *)hex {
//    NSString *hex = @"";
//    if (mut_hex.length==8 && [mut_hex containsString:@"ffffff"]) {
//        hex=[mut_hex stringByReplacingOccurrencesOfString:@"ffffff" withString:@""];
//    }
    NSMutableDictionary *hexDic = [NSMutableDictionary dictionary];//[[NSMutableDictionary alloc] initWithCapacity:16];
    [hexDic setObject:@"0000" forKey:@"0"];
    [hexDic setObject:@"0001" forKey:@"1"];
    [hexDic setObject:@"0010" forKey:@"2"];
    [hexDic setObject:@"0011" forKey:@"3"];
    [hexDic setObject:@"0100" forKey:@"4"];
    [hexDic setObject:@"0101" forKey:@"5"];
    [hexDic setObject:@"0110" forKey:@"6"];
    [hexDic setObject:@"0111" forKey:@"7"];
    [hexDic setObject:@"1000" forKey:@"8"];
    [hexDic setObject:@"1001" forKey:@"9"];
    [hexDic setObject:@"1010" forKey:@"A"];
    [hexDic setObject:@"1011" forKey:@"B"];
    [hexDic setObject:@"1100" forKey:@"C"];
    [hexDic setObject:@"1101" forKey:@"D"];
    [hexDic setObject:@"1110" forKey:@"E"];
    [hexDic setObject:@"1111" forKey:@"F"];
    
    NSString *binary = @"";
    for (int i=0; i<[hex length]; i++) {
        
        NSString *key = [hex substringWithRange:NSMakeRange(i, 1)];
        NSString *value = [hexDic objectForKey:key.uppercaseString];
        if (value) {
            
            binary = [binary stringByAppendingString:value];
        }
    }
    //[hexDic release];
    return binary;
}
/**
 二进制转换成十六进制
 
 @param binary 二进制数
 @return 十六进制数
 */
- (NSString *)getHexByBinary:(NSString *)binary {
    
    
    NSMutableDictionary *binaryDic = [NSMutableDictionary dictionary];//[[NSMutableDictionary alloc] initWithCapacity:16];
    [binaryDic setObject:@"0" forKey:@"0000"];
    [binaryDic setObject:@"1" forKey:@"0001"];
    [binaryDic setObject:@"2" forKey:@"0010"];
    [binaryDic setObject:@"3" forKey:@"0011"];
    [binaryDic setObject:@"4" forKey:@"0100"];
    [binaryDic setObject:@"5" forKey:@"0101"];
    [binaryDic setObject:@"6" forKey:@"0110"];
    [binaryDic setObject:@"7" forKey:@"0111"];
    [binaryDic setObject:@"8" forKey:@"1000"];
    [binaryDic setObject:@"9" forKey:@"1001"];
    [binaryDic setObject:@"A" forKey:@"1010"];
    [binaryDic setObject:@"B" forKey:@"1011"];
    [binaryDic setObject:@"C" forKey:@"1100"];
    [binaryDic setObject:@"D" forKey:@"1101"];
    [binaryDic setObject:@"E" forKey:@"1110"];
    [binaryDic setObject:@"F" forKey:@"1111"];
    
    if (binary.length % 4 != 0) {
        
        NSMutableString *mStr = [[NSMutableString alloc]init];;
        for (int i = 0; i < 4 - binary.length % 4; i++) {
            
            [mStr appendString:@"0"];
        }
        binary = [mStr stringByAppendingString:binary];
    }
    NSString *hex = @"";
    for (int i=0; i<binary.length; i+=4) {
        
        NSString *key = [binary substringWithRange:NSMakeRange(i, 4)];
        NSString *value = [binaryDic objectForKey:key];
        if (value) {
            
            hex = [hex stringByAppendingString:value];
        }
    }
    //[binaryDic release];
    return hex;
    
}

unsigned char* stringFromHexString_DYLIB(NSString *hexString)
{
    unsigned long len = hexString.length/2;
    unsigned char myBuffer[len] ;
    memset(myBuffer, 0, sizeof(myBuffer));
    int idx = 0;
    for (int j=0; j<[hexString length]; j+=2)
    {
        NSString *hexStr = [hexString substringWithRange:NSMakeRange(j, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:hexStr];
        unsigned long long longValue ;
        [scanner scanHexLongLong:&longValue];
        unsigned char c = longValue;
        myBuffer[idx] = c;
        idx++;
    }
    
    //?  myBuffer[idx]='\0';
    unsigned char *buffer = myBuffer;
    return buffer;
}


- (int)data2Int:(NSData *)data{
    Byte *byte = (Byte *)[data bytes];
    // 有大小端模式问题？
    return (byte[0] << 24) + (byte[1] << 16) + (byte[2] << 8) + (byte[3]);
}

-(NSData*)dataWithHexString:(NSString*)str{
    
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [NSMutableData data];//[[[NSMutableData alloc] initWithCapacity:8] autorelease];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
    
}
-(NSString *)HexString_Cal_AND:(NSString *)First SEC:(NSString *)Secend
{//*
    NSMutableString *Value_CMD = [NSMutableString string];
    NSString *c = [NSString stringWithFormat:@"%c",[First characterAtIndex:0]];
    unsigned long length = [First length];
    if([c  isEqual: @"0"]){
        NSLog(@"AND FUCNTION first_c NSString===%@",c);
        [Value_CMD appendString:[NSString stringWithFormat:@"%@",First]];
        NSData *data_1 =[self dataWithHexString:Value_CMD];
        NSData *data_2 =[self dataWithHexString:Secend];
        int data_1_int =[self data2Int:data_1];
        int data_2_int =[self data2Int:data_2];
        int data_3_int = data_1_int&data_2_int;
        
        NSString *sss_3b = [NSString stringWithFormat:@"%x",data_3_int];
        NSString *sss_4 = [sss_3b substringToIndex:(length-1)];
        NSString *cmd_result = @"0";
        cmd_result = [cmd_result stringByAppendingString:sss_4];
        return cmd_result;
    }else{
        NSLog(@"AND FUCNTION the first charect is not 0");
        NSData *data_1 =[self dataWithHexString:First];
        NSData *data_2 =[self dataWithHexString:Secend];
        int data_1_int =[self data2Int:data_1];
        int data_2_int =[self data2Int:data_2];
        int data_3_int = data_1_int&data_2_int;
        
        NSString *sss_3b = [NSString stringWithFormat:@"%02x",data_3_int];
        NSString *sss_4 = [sss_3b substringToIndex:length];
        NSString *cmd_result = @"";
        cmd_result = [cmd_result stringByAppendingString:sss_4];
        return cmd_result;
    }
    
}
-(NSString *)HexString_Cal_OR:(NSString *)First SEC:(NSString *)Secend
{//+
    NSMutableString *Value_CMD = [NSMutableString string];
    NSString *c = [NSString stringWithFormat:@"%c",[First characterAtIndex:0]];
    unsigned long length = [First length];
    if([c isEqual: @"0"])
    {
        [Value_CMD appendString:[NSString stringWithFormat:@"%@",First]];
        NSData *data_1 =[self dataWithHexString:Value_CMD];
        NSData *data_2 =[self dataWithHexString:Secend];
        int data_1_int =[self data2Int:data_1];
        int data_2_int =[self data2Int:data_2];
        int data_3_int = data_1_int|data_2_int;
        
        NSString *sss_3b = [NSString stringWithFormat:@"%x",data_3_int];
        NSString *sss_4 = [sss_3b substringToIndex:(length-1)];
        NSString *cmd_result = @"0";
        cmd_result = [cmd_result stringByAppendingString:sss_4];
        return cmd_result;
    }else{
        NSLog(@"OR FUCNTION the first charect is not 0");
        NSData *data_1 =[self dataWithHexString:First];
        NSData *data_2 =[self dataWithHexString:Secend];
        int data_1_int =[self data2Int:data_1];
        int data_2_int =[self data2Int:data_2];
        int data_3_int = data_1_int|data_2_int;
        
        NSString *sss_3b = [NSString stringWithFormat:@"%02x",data_3_int];
        NSString *sss_4 = [sss_3b substringToIndex:length];
        NSString *cmd_result = @"";
        cmd_result = [cmd_result stringByAppendingString:sss_4];
        return cmd_result;
    }
    
}

-(void)New_ledWithColor:(NSString *)color uut:(NSString *)uut
{
    //NSString *low_state_binary = @"FF";
    //NSString *high_state_binary = @"FF";
    NSString *head = @"02";
    
    NSString *Value_status = [eowyn readI2C_STR:0x48 readlen:2 busId:0];
    if (!Value_status)
    {
        return;
    }
    sleep(0.1);
    NSString *Value_slot1 = [eowyn readI2C_STR:0x42 readlen:2 busId:0];
    if (!Value_slot1)
    {
        return;
    }
    sleep(0.1);
    NSString *Value_slot2 = [eowyn readI2C_STR:0x44 readlen:2 busId:0];
    if (!Value_slot2)
    {
        return;
    }
    sleep(0.1);
    NSString *Value_slot3 = [eowyn readI2C_STR:0x46 readlen:2 busId:0];
    if (!Value_slot3)
    {
        return;
    }
    sleep(0.1);
    NSString *Value_slot4 = [eowyn readI2C_STR:0x4A readlen:2 busId:0];
    if (!Value_slot4)
    {
        return;
    }
    
    if (![Value_status.lowercaseString containsString:@"ff"] ||
        ![Value_slot1.lowercaseString containsString:@"ff"] ||
        ![Value_slot2.lowercaseString containsString:@"ff"] ||
        ![Value_slot3.lowercaseString containsString:@"ff"] ||
        ![Value_slot4.lowercaseString containsString:@"ff"])
    {
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x48 writelen:3 busId:0];
        sleep(0.05);
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x4A writelen:3 busId:0];
        sleep(0.05);
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x42 writelen:3 busId:0];
        sleep(0.05);
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x44 writelen:3 busId:0];
        sleep(0.05);
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x46 writelen:3 busId:0];

        sleep(0.2);
        Value_status = [eowyn readI2C_STR:0x48 readlen:2 busId:0];
        Value_slot1 = [eowyn readI2C_STR:0x42 readlen:2 busId:0];
        Value_slot2 = [eowyn readI2C_STR:0x44 readlen:2 busId:0];
        Value_slot3 = [eowyn readI2C_STR:0x46 readlen:2 busId:0];
        Value_slot4 = [eowyn readI2C_STR:0x4A readlen:2 busId:0];
        
    }
    if (!Value_status || !Value_slot1|| !Value_slot2|| !Value_slot3|| !Value_slot4)
    {
        return ;
    }
    
    Value_status = [head stringByAppendingString:Value_status];
    Value_slot1 = [head stringByAppendingString:Value_slot1];
    Value_slot2 = [head stringByAppendingString:Value_slot2];
    Value_slot3 = [head stringByAppendingString:Value_slot3];
    Value_slot4 = [head stringByAppendingString:Value_slot4];

    NSMutableString *cmd = [NSMutableString string];//[[NSMutableString alloc] init];
    int addr =0x02;
    [cmd appendString:[NSString stringWithFormat:@"%02x",addr]];
    
    /*if ([color.lowercaseString containsString:@"reset"]) {
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x42 writelen:3 busId:0];
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x44 writelen:3 busId:0];
        
        [eowyn writeI2CWithString:@"029F9F" writeadd:0x46 writelen:3 busId:0];
        return;
    }*/
    
    
    
    if ([uut containsString:@"1"])
    {
//        Value_slot1 = [self HexString_Cal_OR:Value_slot1 SEC:@"02FFFF"];
        
        if ([color containsString:@"red"])
        {
//            Value_slot1 = [self HexString_Cal_AND:Value_slot1 SEC:@"02EFFF"];
            
            [eowyn writeI2CWithString:@"02EFFF" writeadd:0x42 writelen:3 busId:0];//write green led
        }
        else if ([color containsString:@"green"])
        {
//            Value_slot1 = [self HexString_Cal_AND:Value_slot1 SEC:@"02DFFF"];
            [eowyn writeI2CWithString:@"02DFFF" writeadd:0x42 writelen:3 busId:0];//write green led
            
        }
        else if ([color containsString:@"blue"])
        {
//            Value_slot1 = [self HexString_Cal_AND:Value_slot1 SEC:@"02BFFF"];
            
            [eowyn writeI2CWithString:@"02BFFF" writeadd:0x42 writelen:3 busId:0];
        }
        else if ([color containsString:@"yellow"])
        {
            
//            Value_slot1 = [self HexString_Cal_AND:Value_slot1 SEC:@"027FFF"];
            
            [eowyn writeI2CWithString:@"027FFF" writeadd:0x42 writelen:3 busId:0];
        }
        else if ([color containsString:@"reset"] || [color containsString:@"off"])
        {
//            Value_slot1 = [self HexString_Cal_AND:Value_slot1 SEC:@"02FFFF"];
            [eowyn writeI2CWithString:@"02FFFF" writeadd:0x42 writelen:3 busId:0];
        }
        
    }
    else if ([uut containsString:@"2"])
    {
//        Value_slot2 = [self HexString_Cal_OR:Value_slot2 SEC:@"02FFFF"];
        
        if ([color containsString:@"red"])
        {
//            Value_slot2 = [self HexString_Cal_AND:Value_slot2 SEC:@"02EFFF"];
            [eowyn writeI2CWithString:@"02EFFF" writeadd:0x44 writelen:3 busId:0];//write green led
        }
        else if ([color containsString:@"green"])
        {
            
//            Value_slot2 = [self HexString_Cal_AND:Value_slot2 SEC:@"02DFFF"];
            [eowyn writeI2CWithString:@"02DFFF" writeadd:0x44 writelen:3 busId:0];//write green led
            
        }
        else if ([color containsString:@"blue"])
        {
//            Value_slot2 = [self HexString_Cal_AND:Value_slot2 SEC:@"02BFFF"];
            [eowyn writeI2CWithString:@"02BFFF" writeadd:0x44 writelen:3 busId:0];
        }
        else if ([color containsString:@"yellow"])
        {
//            Value_slot2 = [self HexString_Cal_AND:Value_slot2 SEC:@"027FFF"];
            [eowyn writeI2CWithString:@"027FFF" writeadd:0x44 writelen:3 busId:0];
        }
        else if ([color containsString:@"reset"]|| [color containsString:@"off"])
        {
//            Value_slot2 = [self HexString_Cal_AND:Value_slot2 SEC:@"02FFFF"];
            [eowyn writeI2CWithString:@"02FFFF" writeadd:0x44 writelen:3 busId:0];
        }
        
        
    }
    else if ([uut containsString:@"3"])
    {
        Value_slot3 = [self HexString_Cal_OR:Value_slot3 SEC:@"02FFFF"];
        
        if ([color containsString:@"red"]) {
            Value_slot3 = [self HexString_Cal_AND:Value_slot3 SEC:@"02EFFF"];
            [eowyn writeI2CWithString:Value_slot3 writeadd:0x46 writelen:3 busId:0];//write green led
        }
        else if ([color containsString:@"green"])
        {
            Value_slot3 = [self HexString_Cal_AND:Value_slot3 SEC:@"02DFFF"];
            [eowyn writeI2CWithString:Value_slot3 writeadd:0x46 writelen:3 busId:0];//write green led
            
        }else if ([color containsString:@"blue"])
        {
            Value_slot3 = [self HexString_Cal_AND:Value_slot3 SEC:@"02BFFF"];
            [eowyn writeI2CWithString:Value_slot3 writeadd:0x46 writelen:3 busId:0];
        }else if ([color containsString:@"yellow"])
        {
            Value_slot3 = [self HexString_Cal_AND:Value_slot3 SEC:@"027FFF"];
            [eowyn writeI2CWithString:Value_slot3 writeadd:0x46 writelen:3 busId:0];
        }
        else if ([color containsString:@"reset"]|| [color containsString:@"off"])
        {
            Value_slot3 = [self HexString_Cal_AND:Value_slot3 SEC:@"02FFFF"];
            [eowyn writeI2CWithString:Value_slot3 writeadd:0x46 writelen:3 busId:0];
        }
        
    }
    else if ([uut containsString:@"4"])
    {
        Value_slot4 = [self HexString_Cal_OR:Value_slot4 SEC:@"02FFFF"];
        if ([color containsString:@"red"])
        {
            Value_slot4 = [self HexString_Cal_AND:Value_slot4 SEC:@"02EFFF"];
            [eowyn writeI2CWithString:Value_slot4 writeadd:0x4A writelen:3 busId:0];//write green led
        }
        else if ([color containsString:@"green"])
        {
            Value_slot4 = [self HexString_Cal_AND:Value_slot4 SEC:@"02DFFF"];
            [eowyn writeI2CWithString:Value_slot4 writeadd:0x4A writelen:3 busId:0];//write green led
            
        }
        else if ([color containsString:@"blue"])
        {
            Value_slot4 = [self HexString_Cal_AND:Value_slot4 SEC:@"02BFFF"];
            [eowyn writeI2CWithString:Value_slot4 writeadd:0x4A writelen:3 busId:0];
            
        }
        else if ([color containsString:@"yellow"])
        {
            Value_slot4 = [self HexString_Cal_AND:Value_slot4 SEC:@"027FFF"];
            [eowyn writeI2CWithString:Value_slot4 writeadd:0x4A writelen:3 busId:0];
        }
        else if ([color containsString:@"reset"]||[color containsString:@"off"])
        {
            Value_slot4 = [self HexString_Cal_AND:Value_slot4 SEC:@"02FFFF"];
            [eowyn writeI2CWithString:Value_slot4 writeadd:0x4A writelen:3 busId:0];
        }
        
        
    }
    else if ([uut containsString:@"5"])
    {
        
        Value_status = [self HexString_Cal_OR:Value_status SEC:@"020810"];
        if ([color containsString:@"red"])
        {
            Value_status = [self HexString_Cal_OR:Value_status SEC:@"02FEFF"];
            [eowyn writeI2CWithString:@"02FEFF" writeadd:0x48 writelen:3 busId:0];//write green led

        }
        else if ([color containsString:@"green"])
        {
            Value_status = [self HexString_Cal_OR:Value_status SEC:@"02FDFF"];
            [eowyn writeI2CWithString:@"02FDFF" writeadd:0x48 writelen:3 busId:0];//write green led

        }
        else if ([color containsString:@"blue"])
        {
            Value_status = [self HexString_Cal_OR:Value_status SEC:@"02FBFF"];
            [eowyn writeI2CWithString:@"02FBFF" writeadd:0x48 writelen:3 busId:0];//write green led

        }
        else if ([color containsString:@"yellow"])
        {
            Value_status = [self HexString_Cal_OR:Value_status SEC:@"02FF7F"];
            [eowyn writeI2CWithString:@"02FF7F" writeadd:0x48 writelen:3 busId:0];
        }
        else if ([color containsString:@"reset"]|| [color containsString:@"off"])
        {
            //Value_status = [self HexString_Cal_OR:Value_status SEC:@"02FF7F"];
            Value_status = [self HexString_Cal_AND:Value_status SEC:@"02FF7F"];
            [eowyn writeI2CWithString:@"02FFFF" writeadd:0x48 writelen:3 busId:0];
        }
    }
}





-(void)SetLedWithColor:(NSString *)color uut:(NSString *)uut{
//    NSString *OLD = [eowyn readI2C_STR:0x42 readlen:2 busId:0];
//    if(OLD){
//        [self ledWithColor:color uut:uut];
//    }else{
//        [self New_ledWithColor:color uut:uut];
//    }
    [self New_ledWithColor:color uut:uut];

}

-(void)ledWithColor:(NSString *)color uut:(NSString *)uut
{
    [eowyn writeI2CWithString:@"02ffff" writeadd:0x42 writelen:3 busId:0];
    sleep(0.02);
    [eowyn writeI2CWithString:@"02ffff" writeadd:0x44 writelen:3 busId:0];
    sleep(0.02);
    [eowyn writeI2CWithString:@"02ffff" writeadd:0x46 writelen:3 busId:0];
    sleep(0.02);
    //[eowyn writeI2CWithString:@"02ffff" writeadd:0x48 writelen:3 busId:0];
    //sleep(0.02);
    NSLog(@"the led board is OLD");
    if ([color containsString:@"reset"] || [color containsString:@"off"])
    {
       
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x42 writelen:3 busId:0];
        sleep(0.02);
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x44 writelen:3 busId:0];
        sleep(0.02);
        [eowyn writeI2CWithString:@"02FFFF" writeadd:0x46 writelen:3 busId:0];

        return;
    }
    
    NSString *low_state_binary = @"11111111";
    NSString *high_state_binary = @"11111111";
    if ([uut containsString:@"1"])
    {
        low_state_binary = @"11011111";//11111011
        
    }
    else if ([uut containsString:@"2"])
    {
        low_state_binary = @"10111111";
        
    }else if ([uut containsString:@"3"])
    {
        high_state_binary = @"11011111";
        
    }
    else if ([uut containsString:@"4"])
    {
        high_state_binary = @"10111111";
    }
    else if ([uut containsString:@"5"])
    {
        if ([color containsString:@"red"])
        {
            low_state_binary = @"11111110";
        }
        else if ([color containsString:@"green"])
        {
            low_state_binary = @"11111101";
        }
        else if ([color containsString:@"blue"])
        {
            low_state_binary = @"11111011";
        }
        
    }
    
    NSString *low_state = [self getHexByBinary:low_state_binary];
    NSString *high_state = [self getHexByBinary:high_state_binary];
    NSMutableString *cmd = [NSMutableString string];//[[NSMutableString alloc] init];
    int addr =0x02;
       // NSString *x42_cmd_1 = [NSString stringWithFormat:@"%02x",addr];
    [cmd appendString:[NSString stringWithFormat:@"%02x",addr]];
    [cmd appendString:low_state];
    [cmd appendString:high_state];
       
    if ([uut containsString:@"5"])
    {
        [eowyn writeI2CWithString:cmd writeadd:0x48 writelen:3 busId:0];
    }
    else
    {
           if ([color containsString:@"red"])
           {
               [eowyn writeI2CWithString:cmd writeadd:0x42 writelen:3 busId:0];
           }
           else if ([color containsString:@"green"])
           {
               [eowyn writeI2CWithString:cmd writeadd:0x44 writelen:3 busId:0];
           }
           else if ([color containsString:@"blue"])
           {
               [eowyn writeI2CWithString:cmd writeadd:0x46 writelen:3 busId:0];
           }
            else if ([color containsString:@"off"])
            {
                //[eowyn writeI2CWithString:cmd writeadd:0x46 writelen:3 busId:0];
                //[eowyn writeI2CWithString:@"02FFFF" writeadd:0x42 writelen:3 busId:0];
                //[eowyn writeI2CWithString:@"02FFFF" writeadd:0x44 writelen:3 busId:0];
                //[eowyn writeI2CWithString:@"02FFFF" writeadd:0x46 writelen:3 busId:0];
            }
    }
    //[cmd release];
    
}

-(NSString *)getSubString:(NSString *)aString FromIndex:(NSInteger)fromIndex toLength:(NSInteger)length
{
    if ([aString length]<(fromIndex+length))
    {
        NSLog(@"length beyond bounds");
        return @"";
    }
    NSString *mutStr = [aString substringFromIndex:fromIndex];
    NSString *returnString = [mutStr substringToIndex:length];
    return returnString;
}

-(void)ledWithLowAddr:(int)low_addr high_addr:(int)high_addr uut:(NSString *)uut color:(NSString *)color
{
    
   if (!current_low_state.length && !current_high_state.length) {
        unsigned char *read_arr = [eowyn readI2C_arr:0x42 readlen:2 busId:0];
        unsigned char stat_low = read_arr[0];//low byte
        unsigned char stat_high = read_arr[1];//high byte
        current_low_state = [self charToString:stat_low];
        current_high_state = [self charToString:stat_high];
    }
    

    NSString *str_color_state = @"110";
    if ([color.lowercaseString containsString:@"red"])
    {
        str_color_state = @"110";
    }else if ([color.lowercaseString containsString:@"green"])
    {
        str_color_state = @"101";
    }else if ([color.lowercaseString containsString:@"blue"])
    {
        str_color_state = @"011";
    }
    
    NSString *binary_low= [self getBinaryByHex:current_low_state];
    NSString *binary_high= [self getBinaryByHex:current_high_state];

    if ([uut.lowercaseString containsString:@"uut1"])
    {
        
        NSString *binary_new = [binary_low stringByReplacingCharactersInRange:NSMakeRange(5, 3) withString:str_color_state];
         current_low_state = [self getHexByBinary:binary_new];

    } else if([uut.lowercaseString containsString:@"uut2"])
    {
        NSString *binary_new = [binary_low stringByReplacingCharactersInRange:NSMakeRange(2, 3) withString:str_color_state];
        current_low_state = [self getHexByBinary:binary_new];
  
    }
    else if([uut.lowercaseString containsString:@"uut3"])
    {
        NSString *str_color_state_1 = [self getSubString:str_color_state FromIndex:1 toLength:2];//index 1&2
        NSString *str_color_state_2 = [self getSubString:str_color_state FromIndex:0 toLength:1];
        
        NSString *binary_new_low = [binary_low stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:str_color_state_1];
        NSString *binary_new_high = [binary_high stringByReplacingCharactersInRange:NSMakeRange(7, 1) withString:str_color_state_2];
        current_low_state = [self getHexByBinary:binary_new_low];
        current_high_state = [self getHexByBinary:binary_new_high];
        
    }
    else if([uut.lowercaseString containsString:@"uut4"])
    {
        NSString *binary_new = [binary_high stringByReplacingCharactersInRange:NSMakeRange(4, 3) withString:str_color_state];
        current_high_state = [self getHexByBinary:binary_new];
        
    }
    else if([uut.lowercaseString containsString:@"fixture"])
    {
        NSString *binary_new = [binary_high stringByReplacingCharactersInRange:NSMakeRange(1, 3) withString:str_color_state];
        current_high_state = [self getHexByBinary:binary_new];
      
    }
    
    
    NSMutableString *x42_cmd = [NSMutableString string];//[[NSMutableString alloc] init];
    int addr =0x02;
    [x42_cmd appendString:[NSString stringWithFormat:@"%02x",addr]];
    [x42_cmd appendString: current_low_state];
    [x42_cmd appendString:current_high_state];
    [eowyn writeI2CWithString:x42_cmd writeadd:0x42 writelen:3 busId:0];
//    [self writeFixtureLogs:[NSString stringWithFormat:@"write string:%@, address:0x42, length:3, bus id: 0",x42_cmd]];
    //[x42_cmd release];
    
}

-(BOOL)writeIO:(NSInteger)iOIndex value:(ATDeviceDIOType)value
{
    BOOL ret = [eowyn writeIO:iOIndex value:value];
    return ret;
}

-(ATDeviceDIOType)readIO:(NSInteger)iOIndex
{
    ATDeviceDIOType ret = [eowyn readIO:iOIndex];
    return ret;
}

-(ATDeviceDIOType)readDutIO:(NSInteger)iOIndex
{
    ATDeviceDIOType ret = [eowyn readDutIO:iOIndex];
    return ret;
}


-(int)fixture_in
{
    
    [self writeIO:elect_magnet value:GPIO_ON];//elect_magnet 12

    ATDeviceDIOType io_status = [self readIO:UP_SENSOR];
    if (io_status != UP_DOWN_SENSOR_ON)
    {   //#UP_DOWN_SENSOR_ON  1
        NSLog(@"UP SENSOR NO ON");
        return -1;
    }
    NSLog(@"UP SENSOR STATS IS: %d",io_status);
    [self writeIO:OUT_GPIO value:GPIO_OFF];
    [self writeIO:DOWN_GPIO value:GPIO_OFF];
    [self writeIO:IN_GPIO value:GPIO_ON];
    
    [NSThread sleepForTimeInterval:1];
    
    for (int i=0; i<30; i++)  // timeout 10*0.5 = 5s
    {
        ATDeviceDIOType up_sensor = [self readIO:UP_SENSOR];
        ATDeviceDIOType in_sensor = [self readIO:IN_SENSOR];

        if (in_sensor == IN_OUT_SENSOR_ON && up_sensor == UP_DOWN_SENSOR_ON)
        {
            NSLog(@"IN OK");
            return 0;
        }
        
        [NSThread sleepForTimeInterval:2];
    }
    NSLog(@"IN sensor timeout,error");
    return -2;
}

-(int)fixture_down
{
    ATDeviceDIOType up_status = [self readIO:UP_SENSOR];
    ATDeviceDIOType in_status = [self readIO:IN_SENSOR];

    if (in_status == IN_OUT_SENSOR_ON && up_status == UP_DOWN_SENSOR_ON)
    {
        [NSThread sleepForTimeInterval:0.5];
 
        [self writeIO:UP_GPIO value:GPIO_OFF];
        [self writeIO:DOWN_GPIO value:GPIO_ON];
        [NSThread sleepForTimeInterval:1];
        for (int i=0; i<10; i++)  // timeout 10*0.5 = 5s
        {
            ATDeviceDIOType down_io_status = [self readIO:DOWN_SENSOR];
            if(down_io_status==UP_DOWN_SENSOR_ON)
            {
                NSLog(@"down_io_status is OK %hhu",down_io_status);
                return 0;
            }else
            {
                NSLog(@"down_io_status is NG %hhu",down_io_status);

            }
            [NSThread sleepForTimeInterval:0.5];
        }
        return -1;


        
    }
    else{
        NSLog(@"IN SENSOR IS NOT ON");
        return -1;
    }
    
}

-(int)fixture_up
{
    ATDeviceDIOType up_io_stat = [self readIO:UP_SENSOR];
    if (up_io_stat == UP_DOWN_SENSOR_ON)
    {
        return 0;
    }

    ATDeviceDIOType out_sensor = [self readIO:OUT_SENSOR];
     if (out_sensor == IN_OUT_SENSOR_ON )
     {
         return 0;
     }
    
    NSLog(@"Fixture will up");
    [self writeIO:DOWN_GPIO value:GPIO_OFF];
    [self writeIO:UP_GPIO value:GPIO_ON];
    [NSThread sleepForTimeInterval:0.5];
    for (int i=0; i<10; i++)  // timeout 10*0.5 = 5s
    {
        ATDeviceDIOType up_io_stat = [self readIO:UP_SENSOR];
        [NSThread sleepForTimeInterval:0.5];
        ATDeviceDIOType in_io_stat = [self readIO:IN_SENSOR];
        NSLog(@"the in sensor in fixture up is %hhu",in_io_stat);
        if (up_io_stat == UP_DOWN_SENSOR_ON)
        {
            return 0;
        }
        [NSThread sleepForTimeInterval:0.5];
    }
    return 0;
}

-(int)fixture_out
{
    ATDeviceDIOType io_status = [self readIO:UP_SENSOR];
    if (io_status != UP_DOWN_SENSOR_ON)
    {
        NSLog(@"UP SENSOR IS NOT ON");
        return -1;
    }
    [self writeIO:elect_magnet value:GPIO_OFF];
    [self writeIO:IN_GPIO value:GPIO_OFF];
    [self writeIO:OUT_GPIO value:GPIO_ON];
//    [NSThread sleepForTimeInterval:2];
//    [self writeIO:elect_magnet value:GPIO_ON];
    return 0;
}

@end
