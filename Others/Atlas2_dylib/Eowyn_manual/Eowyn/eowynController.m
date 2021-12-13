//
//  eowynContoller.m
//  Eowyn
//
//  Created by gdlocal on 2021/6/17.
//  Copyright © 2021 gdlocal. All rights reserved.
//

#import "eowynController.h"

#define ADDR_24LC01             0xA0 >> 1    //eeprom address,0xA0 = Write address and 0xA1 is the read address.
#define I2C_SPEED               100000
#define I2C_SLAVE_ADDRESS7      0x30 >> 1

#define kBufferSize 20

@implementation eowynController

-(id)init{
    self = [super init];
    if (self)
    {
        if (interface)
        {
            //[interface release];
        }
        interface =nil;
    }
    return self;
}

-(void)LED
{
    //[eowyn release];
    //    [connector release];
    //[interface release];
    //[super dealloc];
}

-(BOOL)connectWithIP:(NSString *)connectIP
{
    @try {
       
        NSError * myError = nil;
        interface = [[ATDeviceSocketInterface alloc] initWithIPAddress:connectIP];
        if(interface)
        {
            NSLog(@"==>>>%@",interface);
            if(![interface openWithError:&myError])
            {
                //ip如未ping通，调用此open函数，程序会卡死。
                return NO;
            }
        }else{
            
            return NO;
        }
        
    } @catch (NSException *exception) {
  
        @throw exception;
        return NO;
    }

    eowyn = [[ATDeviceEowyn alloc] initWithCommunicationInterface:interface];
    return YES;
}


-(void)close
{
    [interface close];
}

-(BOOL)configEuropeanConnector
{
    /*NSError * myError = nil;
    BOOL success = NO;
    connector = [ [ATDCarbonEuropeanConnector alloc] init];
    success = [connector addPinWithRow:EuropeanPortRowC andPin:12 andType:GPIO_Mode_AF_OD_NoPull_GPIO_AF_I2C2 andError:&myError];

    //Configure the I2C1
    //i2c 1 SCL
    success = [connector addPinWithRow:EuropeanPortRowB andPin:12 andType:GPIO_Mode_AF_OD_NoPull_GPIO_AF_I2C1 andError:&myError];
    //i2c 1 SDA
    success = [connector addPinWithRow:EuropeanPortRowA andPin:12 andType:GPIO_Mode_AF_OD_NoPull_GPIO_AF_I2C1 andError:&myError];

//    NSLog(@"Start I2C write and then read Demo. It requires a 24C02 epprom and Carbon FW 0.0.8 or above");

    if(myError){ NSLog(@"Failed to add pins %@", [myError localizedDescription]); return NO;}

    //now configure the 2 pins
    [Eowyn configureEuropeanConnector:connector andError:&myError];
    if(myError){  NSLog(@"Error configure pins %@", [myError localizedDescription]); return NO;}
     */
    return YES;
}



-(BOOL)configI2C
{
    NSError * myError = nil;
    BOOL success = NO;
//    uint8_t i2cId = 1;
    success = [eowyn configureI2C: 1
                          andMode: ATDFixtureI2CModeI2C
                       andI2cAddr: 0x30 >> 1
                    andClockSpeed: 100000
                     andEnableAck: YES
                    andAckAddress: ATDFixtureI2CAckAddressMode7bit
                         andError: &myError];
    
    
    if(myError || !success)
    {
        
//        [self show_log_debug:[NSString stringWithFormat:@"Error configure I2C 2 %@", [myError localizedDescription]]];
        return NO;
        
    }
    return YES;
}

//-(unsigned char *)cw_stringToHex:(NSString *)hexStr{
//    int len = hexStr.length;
//    unsigned char aucKey[3] ;
//    memset(aucKey, 0, 3);
//
//    int idx = 0;
//    for (int j=0; j<len; j+=2)
//    {
//        NSString *mut_hexStr = [hexStr substringWithRange:NSMakeRange(j, 2)];
//        NSScanner *scanner = [NSScanner scannerWithString:mut_hexStr];
//        unsigned long long longValue ;
//        [scanner scanHexLongLong:&longValue];
//        unsigned char c = longValue;
//        aucKey[idx] = c;
//        idx++;
//    }
//
//    return aucKey;
//}


unsigned char* stringFromHexString_2(NSString *hexString)
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
const char* stringFromHexString(NSString *hexString)
{
    //    NSString *str=[NSString stringWithCString:hexString encoding:NSUTF8StringEncoding];
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        //NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        NSScanner * scanner = [NSScanner scannerWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    return myBuffer;
}
//typedef NS_ENUM(uint8_t, ATDeviceDIOType) {
//    ATDeviceDIOLow = 0,
//    ATDeviceDIOHigh,
//    ATDeviceDIOToggle,
//    ATDeviceDIOFlash,
//    ATDeviceDIOUnknown = 0xFF
//
//};
-(NSString *)ATDeviceDIOType_to_stirng:(ATDeviceDIOType)type{
    if (type == ATDeviceDIOLow) {
        return @"0(ATDeviceDIOLow)";
    }else if (type == ATDeviceDIOHigh){
        return @"1(ATDeviceDIOHigh)";
    }else if (type == ATDeviceDIOToggle){
        return @"2(ATDeviceDIOToggle)";
    }else if (type == ATDeviceDIOFlash){
        return @"3(ATDeviceDIOFlash)";
    }else if (type == ATDeviceDIOUnknown){
        return @"0xFF(ATDeviceDIOUnknown)";
    }
    
    return [NSString stringWithFormat:@"%d(ATDeviceDIOUnknown)",type];
}

//-(void)show_log_uart:(NSString *)string
//{
//    NSLog(@"%@",string);
//}
//-(void)show_log_debug:(NSString *)string
//{
//    NSLog(@"%@",string);
//}
//-(void)show_log:(NSString *)string type:(NSString *)type
//{
//    NSLog(@"%@ %@",string,type);
//
//}

-(NSString *)write_iOIndex_to_stirng:(NSInteger)iOIndex
{
    if (iOIndex == 8)
    {
        return @"8(IN_GPIO)";
    }else if (iOIndex == 9)
    {
        return @"9(OUT_GPIO)";
    }else if (iOIndex == 10)
    {
        return @"10(UP_GPIO)";
    }else if (iOIndex == 11)
    {
        return @"11(DOWN_GPIO)";
    }else if (iOIndex == 12)
    {
        return @"12(elect_magnet)";
    }else if (iOIndex == 13)
    {
        return @"13(FAN_IN_GPIO)";
    }else if (iOIndex == 14)
    {
        return @"14(FAN_OUT_GPIO)";
    }
    
    return [NSString stringWithFormat:@"%ld(Unknown)",(long)iOIndex];
}

//#define IN_GPIO                     8
//#define OUT_GPIO                    9
//#define UP_GPIO                     11
//#define DOWN_GPIO                   10
//#define elect_magnet                12
//#define FAN_IN_GPIO                 13
//#define FAN_OUT_GPIO                14
-(BOOL)writeIO:(NSInteger)iOIndex value:(ATDeviceDIOType)value
{
    @synchronized(self) {
        NSError * myError = nil;
        [eowyn writeDigitalOutput:iOIndex andValue:value andError:&myError];
        if(myError)
        {
            return NO;
        }
        return YES;
    }
}
//#define UP_SENSOR                   0
//#define DOWN_SENSOR                 1
//#define IN_SENSOR                   2
//#define OUT_SENSOR                  3
//#define RESET_SENSOR                4
//#define FAN_IN_SENSOR               5
//#define FAN_OUT_SENSOR              6

-(NSString *)read_iOIndex_to_stirng:(NSInteger)iOIndex{
    if (iOIndex == 0) {
        return @"0(UP_SENSOR)";
    }else if (iOIndex == 1){
        return @"1(DOWN_SENSOR)";
    }else if (iOIndex == 2){
        return @"2(IN_SENSOR)";
    }else if (iOIndex == 3){
        return @"3(OUT_SENSOR)";
    }else if (iOIndex == 4){
        return @"4(RESET_SENSOR)";
    }else if (iOIndex == 5){
        return @"5(FAN_IN_SENSOR)";
    }else if (iOIndex == 6){
        return @"6(FAN_OUT_SENSOR)";
    }
    
    return [NSString stringWithFormat:@"%ld(Unknown)",(long)iOIndex];
}
-(ATDeviceDIOType)readIO:(NSInteger)iOIndex
{
    
    @synchronized(self) {
        
        NSError * myError = nil;
        ATDeviceDIOType iOType = [eowyn readDigitalInput:iOIndex andError:&myError];

        if(myError)
        {
            return ATDeviceDIOUnknown;
            
        }
        return iOType;
    }
}

-(ATDeviceDIOType)readIO:(NSInteger)iOIndex printLog:(BOOL)printLog{
    NSError * myError = nil;
    ATDeviceDIOType iOType = [eowyn readDigitalInput:iOIndex andError:&myError];
    
    if (printLog)
    {
//        NSString *stirng_iOIndex =[self read_iOIndex_to_stirng:iOIndex];
//        NSString *string_value = [self ATDeviceDIOType_to_stirng:iOType];
//        [self show_log_uart:[NSString stringWithFormat:@"inputDigital:%@ readIOType:%@",stirng_iOIndex,string_value]];
    }

    
    if(myError){
        
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@",[myError localizedDescription]]];
        return ATDeviceDIOUnknown;
        
    }
    
    return iOType;
}


-(ATDeviceDIOType)readDutIO:(NSInteger)iOIndex
{
    NSError * myError = nil;
    ATDeviceDIOType iOType = [eowyn readDigitalInput:iOIndex andError:&myError];
    if(myError)
    {
        return ATDeviceDIOUnknown;
    }
    return iOType;
}

-(ATDeviceDIOType)readDutIO:(NSInteger)iOIndex printLog:(BOOL)printLog
{
    NSError * myError = nil;
    ATDeviceDIOType iOType = [eowyn readDigitalInput:iOIndex andError:&myError];
    if (printLog)
    {
//        NSString *string_value = [self ATDeviceDIOType_to_stirng:iOType];
//        [self show_log_uart:[NSString stringWithFormat:@"inputDigital:%ld readIOType:%@",(long)iOIndex,string_value]];
    }

    
    if(myError){
        
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@",[myError localizedDescription]]];
        return ATDeviceDIOUnknown;
        
    }
    
    return iOType;
}

-(BOOL)writeI2C:(uint8_t *)writeData writeadd:(int)add writelen:(int)length busId:(int)busId{
    NSError * myError = nil;
    //    uint8_t i2cId = 1;
    NSString *hex_string=@"0x";
    hex_string = [hex_string stringByAppendingFormat:@"%02x",add];
//    [self show_log_uart:[NSString stringWithFormat:@"busId:%d writeI2C:%s address:%@",busId,writeData,hex_string]];
    
    [eowyn i2cTransferWithBusId:busId address:add >> 1 andWriteLen:length andReadLen:0 andData:(uint8_t*)writeData andError: &myError];
    
    if(myError)
    {
        
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to write I2C %@", [myError localizedDescription]]];
        return NO;
    }
    return YES;
}


-(BOOL)writeI2CWithString:(NSString *)writeString writeadd:(int)add writelen:(int)length busId:(int)busId{
    NSError * myError = nil;
    
    NSString *hex_string=@"0x";
    hex_string = [hex_string stringByAppendingFormat:@"%02x",add];
//    [self show_log_uart:[NSString stringWithFormat:@"writeI2C:%@ address:%@",writeString,hex_string]];
    //change string to hex

    const char *data = stringFromHexString(writeString);

    [eowyn i2cTransferWithBusId:busId address:add >> 1 andWriteLen:3 andReadLen:0 andData:(uint8_t*)stringFromHexString(@"060000") andError: &myError];
    
    
    [eowyn i2cTransferWithBusId:busId address:add >> 1 andWriteLen:length andReadLen:0 andData:(uint8_t*)data andError: &myError];
    if(myError)
    {
        return NO;
    }
    return YES;
}

-(NSString *)readI2CWithString:(NSString *)writeString writeadd:(int)add writelen:(int)length busId:(int)busId{
    NSError * myError = nil;
    
    NSString *hex_string=@"0x";
    hex_string = [hex_string stringByAppendingFormat:@"%02x",add];
    //    [self show_log_uart:[NSString stringWithFormat:@"writeI2C:%@ address:%@",writeString,hex_string]];
    //change string to hex
    
    const char *data = stringFromHexString(writeString);
    
//    [eowyn i2cTransferWithBusId:busId address:add >> 1 andWriteLen:3 andReadLen:0 andData:(uint8_t*)stringFromHexString(@"060000") andError: &myError];
    
    
    [eowyn i2cTransferWithBusId:busId address:add >> 1 andWriteLen:0 andReadLen:length andData:(uint8_t*)data andError: &myError];
//    NSString *value = [[NSString stringWithFormat:@"%@"] data];
    NSString *value = [NSString stringWithUTF8String:data];

    if(myError)
    {
        return @"NO";
    }
    return value;
}

-(BOOL)writeI2C:(NSString *)writeData writeadd:(int)add writelen:(int)length
{
    NSError * myError = nil;
    //    uint8_t i2cId = 1;
    NSString *hex_string=@"0x";
    hex_string = [hex_string stringByAppendingFormat:@"%02x",add];
//    [self show_log_uart:[NSString stringWithFormat:@"writeI2C:%@ address:%@",writeData,hex_string]];
    //change string to hex
    const char *data = stringFromHexString(writeData);
    
    [eowyn i2cTransferWithAddress: add >> 1
                      andWriteLen: length
                       andReadLen: 0
                          andData: (uint8_t*)data
                         andError: &myError];
    
    if(myError){
        
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to write I2C %@", [myError localizedDescription]]];
        return NO;
    }
    return YES;
}

-(NSString *)getBinaryByHex:(NSString *)hex {
    
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


-(unsigned char *)readI2C_arr:(int)readadd readlen:(int)len busId:(int)busId
{
    unsigned char readData[kBufferSize] = {0};
    
    NSError * myError = nil;
    
    [eowyn i2cTransferWithBusId:busId address:readadd >> 1 andWriteLen:3 andReadLen:0 andData:(uint8_t*)stringFromHexString(@"06ffff") andError: &myError];
    
    [eowyn i2cTransferWithBusId:busId address:readadd >> 1 andWriteLen:0 andReadLen:len andData:(uint8_t*)readData andError: &myError];
    
    if(myError){
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@", [myError localizedDescription]]];
         return NULL;
        
    }
    unsigned char *read = readData;
    return read;
}

-(NSString *)charToString:(char )hex_char{
    
    NSString *mut_hex = [NSString stringWithFormat:@"%02x",hex_char];
    NSString *hex = @"";
    if (mut_hex.length==8 && [mut_hex containsString:@"ffffff"]) {
        hex=[mut_hex stringByReplacingOccurrencesOfString:@"ffffff" withString:@""];
    }
    return hex;
}
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

-(NSString *)readI2C_STR:(int)readadd readlen:(int)len busId:(int)busId
{
    unsigned char readData[kBufferSize] = {0};
    NSString *current_low_state;
    NSString *current_high_state;
    //NSMutableString *Value = [[NSMutableString alloc] init];
    NSMutableString *Value = [NSMutableString string];
    NSError * myError = nil;
    
    //    [eowyn i2cTransferWithBusId:busId address:readadd >> 1 andWriteLen:3 andReadLen:0 andData:(uint8_t*)stringFromHexString(@"06ffff") andError: &myError];
    
    [eowyn i2cTransferWithBusId:busId address:readadd >> 1 andWriteLen:0 andReadLen:len andData:(uint8_t*)readData andError: &myError];
    
    if(myError){
        //        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@", [myError localizedDescription]]];
        return NULL;
        
    }
    unsigned char *read = readData;
    
    unsigned char stat_low = read[0];//low byte
    unsigned char stat_high = read[1];//high byte
    current_low_state = [self charToString:stat_low];
    current_high_state = [self charToString:stat_high];
    NSString *binary_low= [self getBinaryByHex:current_low_state];
    NSString *binary_high= [self getBinaryByHex:current_high_state];
    //            Value = [binary_low stringByAppendingString:binary_high];
    NSString *low_state = [self getHexByBinary:binary_low];
    NSString *high_state = [self getHexByBinary:binary_high];
    [Value appendString:low_state];
    [Value appendString:high_state];
    
    return Value;
}

-(int)readI2C:(int)readadd readlen:(int)len busId:(int)busId
{
    char readData[kBufferSize] = {0};
    NSError * myError = nil;
    
    [eowyn i2cTransferWithBusId:busId address:readadd >> 1 andWriteLen:0 andReadLen:len andData:(uint8_t*)readData andError: &myError];
    
    if(myError){
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@", [myError localizedDescription]]];
        return -999;}
    
    return readData[1];
}

-(int)readI2C:(int)readadd readlen:(int)len
{
    char readData[kBufferSize] = {0};
    NSError * myError = nil;
    [eowyn i2cTransferWithAddress: readadd >> 1
                      andWriteLen: 0
                       andReadLen: len
                          andData: (uint8_t*)readData
                         andError: &myError];
    
    if(myError){
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@", [myError localizedDescription]]];
        return -999;}
    
    return readData[1];
}

-(int)readDUTI2C:(int)readadd readlen:(int)len
{
    char readData[kBufferSize] = {0};
    NSError * myError = nil;
    [eowyn i2cTransferWithAddress: readadd >> 1
                      andWriteLen: 0
                       andReadLen: len
                          andData: (uint8_t*)readData
                         andError: &myError];
    
    if(myError){
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@", [myError localizedDescription]]];
        
        return -999;}
    
    
    NSString *ret = [NSString stringWithFormat:@"%.2hhx",readData[1]];
    //NSMutableString *ret1 = [[NSMutableString alloc]init];
    NSMutableString *ret1 = [NSMutableString string];
    for (NSUInteger i=0; i<[ret length]; i++) {
        NSRange range = NSMakeRange(i, 1);
        NSString *str = [ret substringWithRange:range];
        [ret1 appendString:[self getBinaryByHex:str]];
    }
    
    NSMutableString *cmd = [NSMutableString string];
    int slot = 1;
    for (NSUInteger i=[ret1 length]-2; i>=0; i-=2) {
        NSRange range = NSMakeRange(i, 2);
        NSString *str = [ret1 substringWithRange:range];
        if([str containsString:@"1"]){
            [cmd appendString:[NSString stringWithFormat:@"place:DUT%d NO;",slot]];
        }else{
            [cmd appendString:[NSString stringWithFormat:@"place:DUT%d OK;",slot]];
        }
        if(i==0){// NSUInteger的值无负数
            break;
        }
        slot++;
    }
    [cmd appendString:@"DONE;"];
//    [self show_log_debug:[NSString stringWithFormat:@"%@",cmd]];
    
    
    //    NSArray* array = [cmd componentsSeparatedByString:@";"];
    //    for (int i=0; i<4; i++) {
    //        if([array[i] containsString:@"OK"]){
    //            NSLog(@"slot%d OK",i+1);
    //        }else{
    //            NSLog(@"slot%d NO",i+1);
    //        }
    //    }
    return readData[1];
}

-(int)readFanI2C:(int)readadd readlen:(int)len
{
    char readData[kBufferSize] = {0};
    NSError * myError = nil;
    //    uint8_t i2cId = 1;
    
    //    [eowyn i2cTransferWithBusId:i2cId
    //                         address:readadd >> 1//ADDR_24LC02's i2c address is 0xA0. Because I2C is 7 bit address, you need to shift 1 bit to right (0xA0 >> 1), before passing it to the API.
    //                     andWriteLen:0
    //                      andReadLen:len
    //                         andData:(uint8_t*)readData
    //                        andError:&myError];
    
    [eowyn i2cTransferWithAddress: readadd >> 1
                      andWriteLen: 0
                       andReadLen: len
                          andData: (uint8_t*)readData
                         andError: &myError];
    
    if(myError){
//        [self show_log_debug:[NSString stringWithFormat:@"Error Failed to read I2C %@", [myError localizedDescription]]];
        
        return -999;}
    
//    [self show_log_debug:@"READ:"];
//    [self show_log_debug:[NSString stringWithFormat:@"[0] 0x%x or %c",readData[0],readData[0]]];
    
//    [self show_log_debug:[NSString stringWithFormat:@"[1] 0x%x or %d",readData[1],readData[1]]];
    
    //    NSLog(@"[2] 0x%x or %c",readData[2],readData[2]);
    return readData[0];
}

void set_button_led(eowynController * eowyn ,NSString* mode){
    [eowyn writeI2C:@"01" writeadd:0x44 writelen:1];
    unsigned char stat = [eowyn readI2C:0x44 readlen:2];
    if ([mode isEqualToString:@"open"]){
        stat = stat | 0x08;
    }
    else if ([mode isEqualToString:@"close"]){
        stat = stat & 0xf7;
    }
    //    NSString *stat_string = [NSString stringWithFormat:@"%d",stat];
    //    NSString *add = @"02";
    //    unsigned long hex_stat = strtoul([add UTF8String],0,16) & strtoul([stat_string UTF8String],0,16);
    NSString *command = [NSString stringWithFormat:@"02%02x",stat];
    [eowyn writeI2C:command writeadd:0x44 writelen:2];
    
}
void runFanRpm(eowynController * eowyn){
    
    [eowyn writeI2C:@"0000" writeadd:0x58 writelen:2]; // Global Configuration
    [eowyn readI2C:0x58 readlen:2];
    
    [eowyn writeI2C:@"01bb" writeadd:0x58 writelen:2]; //PWM Frequency config when power on
    [eowyn readI2C:0x58 readlen:2];
    
    [eowyn writeI2C:@"02c8" writeadd:0x58 writelen:2]; //FAN1 Configuration
    [eowyn readI2C:0x58 readlen:2];
    [eowyn writeI2C:@"085e" writeadd:0x58 writelen:2]; //FAN1 Dynamics Configuration
    [eowyn readI2C:0x58 readlen:2];
    [eowyn writeI2C:@"501E" writeadd:0x58 writelen:2]; //FAN1 set speed
    [eowyn readI2C:0x58 readlen:2];
    [eowyn writeI2C:@"51A0" writeadd:0x58 writelen:2];
    [eowyn readI2C:0x58 readlen:2];
    
    //    [eowyn writeI2C:@"03c8" writeadd:0x40 writelen:2]; //FAN2 Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"095e" writeadd:0x40 writelen:2]; //FAN2 Dynamics Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"521E" writeadd:0x40 writelen:2]; //FAN2 set speed
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"53A0" writeadd:0x40 writelen:2];
    //    [eowyn readI2C:0x40 readlen:2];
    //
    //    [eowyn writeI2C:@"04c8" writeadd:0x40 writelen:2]; //FAN3 Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"0a5e" writeadd:0x40 writelen:2]; //FAN3 Dynamics Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"541E" writeadd:0x40 writelen:2]; //FAN3 set speed
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"55A0" writeadd:0x40 writelen:2];
    //    [eowyn readI2C:0x40 readlen:2];
    //
    //    [eowyn writeI2C:@"05c8" writeadd:0x40 writelen:2]; //FAN4 Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"0b5e" writeadd:0x40 writelen:2]; //FAN4 Dynamics Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"561E" writeadd:0x40 writelen:2]; //FAN4 set speed
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"57A0" writeadd:0x40 writelen:2];
    //    [eowyn readI2C:0x40 readlen:2];
    //
    //    [eowyn writeI2C:@"06c8" writeadd:0x40 writelen:2]; //FAN5 Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"0c5e" writeadd:0x40 writelen:2]; //FAN5 Dynamics Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"581E" writeadd:0x40 writelen:2]; //FAN5 set speed
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"59A0" writeadd:0x40 writelen:2];
    //    [eowyn readI2C:0x40 readlen:2];
    //
    //    [eowyn writeI2C:@"07c8" writeadd:0x40 writelen:2]; //FAN6 Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"0d5e" writeadd:0x40 writelen:2]; //FAN6 Dynamics Configuration
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"5a1E" writeadd:0x40 writelen:2]; //FAN6 set speed
    //    [eowyn readI2C:0x40 readlen:2];
    //    [eowyn writeI2C:@"5bA0" writeadd:0x40 writelen:2];
    //    [eowyn readI2C:0x40 readlen:2];
    //
    //    [eowyn writeI2C:@"0000" writeadd:0x44 writelen:2]; // Global Configuration
    //    [eowyn readI2C:0x44 readlen:2];
    //
    //    [eowyn writeI2C:@"01bb" writeadd:0x44 writelen:2]; //PWM Frequency config when power on
    //    [eowyn readI2C:0x44 readlen:2];
    //
    //    [eowyn writeI2C:@"02c8" writeadd:0x44 writelen:2]; //FAN7 Configuration
    //    [eowyn readI2C:0x44 readlen:2];
    //    [eowyn writeI2C:@"085e" writeadd:0x44 writelen:2]; //FAN7 Dynamics Configuration
    //    [eowyn readI2C:0x44 readlen:2];
    //    [eowyn writeI2C:@"501E" writeadd:0x44 writelen:2]; //FAN7 set speed
    //    [eowyn readI2C:0x44 readlen:2];
    //    [eowyn writeI2C:@"51A0" writeadd:0x44 writelen:2];
    //    [eowyn readI2C:0x44 readlen:2];
    
}
void resetled(eowynController * eowyn){
    
    [eowyn writeI2C:@"02ffff" writeadd:0x42 writelen:3];
    [eowyn writeI2C:@"020700" writeadd:0x44 writelen:3];
    
    [eowyn writeI2C:@"060000" writeadd:0x42 writelen:3];
    [eowyn writeI2C:@"06f0ff" writeadd:0x44 writelen:3];
    
    //    int stat = [eowyn readI2C:0x44 readlen:1];
    //    stat = stat & 0xf7;
    //
    //    NSString *command = [NSString stringWithFormat:@"02%.2x",stat];
    //    [eowyn writeI2C:command writeadd:0x44 writelen:2];
    //    [eowyn writeI2C:@"06" writeadd:0x44 writelen:1];
    //    stat = [eowyn readI2C:0x44 readlen:1];
    //    stat = stat & 0xf7;
    //    command = [NSString stringWithFormat:@"06%.2x",stat];
    //    [eowyn writeI2C:command writeadd:0x44 writelen:2];
    
    
}
BOOL check_timeout(eowynController * eowyn ,int iOIndex,int stat,int timeout){
    uint32 start = [[NSDate date]timeIntervalSince1970];
    while (true) {
        ATDeviceDIOType io_stat = [eowyn readIO:iOIndex];
        if (io_stat == stat){
            return YES;
        }
        uint32 end = [[NSDate date]timeIntervalSince1970];
        if (end - start > timeout){
            return NO;
        }
    }
}

void uut1led(eowynController * eowyn,NSString* mode){
    
    [eowyn writeI2C:@"02" writeadd:0x42 writelen:1];
    unsigned char stat_1 = [eowyn readI2C:0x42 readlen:2];
    [eowyn writeI2C:@"01" writeadd:0x44 writelen:1];
    unsigned char stat_2 = [eowyn readI2C:0x44 readlen:2];
    
    if([mode isEqualToString:@"ready"]){                    //blue
        stat_1 = (stat_1 & 0xf1) + 0x06;
        stat_2 = stat_2 | 0x04;
        
    }else if([mode isEqualToString:@"idle"]){               //yellow
        stat_1 = stat_1 | 0x0e;
        stat_2 = stat_2 & 0xfb;
        
    }else if([mode isEqualToString:@"pass"]){               //green
        stat_1 = (stat_1 & 0xf1) + 0x0a;
        stat_2 = stat_2 | 0x04;
        
    }else if ([mode isEqualToString:@"fail"]){              //red
        stat_1 = (stat_1 & 0xf1) + 0x0c;
        stat_2 = stat_2 | 0x04;
        
    }else if ([mode isEqualToString:@"init"]){              //init
        stat_1 = stat_1 | 0x0e;
        stat_2 = stat_2 | 0x04;
        
    }else{
//        show_log(@"Error Mode!");
        return;
    }
    
    NSString *x42_cmd = [NSString stringWithFormat:@"03%02x",stat_1];
    NSString *x44_cmd = [NSString stringWithFormat:@"02%02x",stat_2];
//    show_log([NSString stringWithFormat:@"uut1led ledRecord_x42 %@",x42_cmd]);
//    show_log([NSString stringWithFormat:@"uut1led ledRecord_x44 %@",x44_cmd]);
    [eowyn writeI2C:x42_cmd writeadd:0x42 writelen:2];
    [eowyn writeI2C:x44_cmd writeadd:0x44 writelen:2];
}


void uut4led(eowynController * eowyn,NSString* mode){                       //actually UUT2
    
    [eowyn writeI2C:@"01" writeadd:0x42 writelen:1];
    unsigned char stat_1 = [eowyn readI2C:0x42 readlen:2];
    [eowyn writeI2C:@"02" writeadd:0x42 writelen:1];
    unsigned char stat_2 = [eowyn readI2C:0x42 readlen:2];
    //    int stat = 0;
    //    NSString * x42_set = nil;
    //    NSString * x44_set = nil;
    
    if([mode isEqualToString:@"ready"]){                    //blue
        stat_1 = (stat_1 & 0xf8) + 0x03;
        stat_2 = stat_2 | 0x80;
        
        //        x42_set = @"02dfff";
        //        x44_set = @"02ffff";
        
    }else if([mode isEqualToString:@"idle"]){               //yellow
        stat_1 = stat_1 | 0x07;
        stat_2 = stat_2 & 0x7f;
        //        x42_set = @"02ffff";
        //        x44_set = @"02feff";
    }else if([mode isEqualToString:@"pass"]){               //green
        stat_1 = (stat_1 & 0xf8) + 0x05;
        stat_2 = stat_2 | 0x80;
        //        x42_set = @"02efff";
        //        x44_set = @"02ffff";
    }else if ([mode isEqualToString:@"fail"]){              //red
        stat_1 = (stat_1 & 0xf8) + 0x06;
        stat_2 = stat_2 | 0x80;
        //        x42_set = @"02f7ff";
        //        x44_set = @"02ffff";
    }else if ([mode isEqualToString:@"init"]){              //init
        stat_1 = stat_1 | 0x07;
        stat_2 = stat_2 | 0x80;
        
        //        ledRecord_x42 = [NSMutableString stringWithString:@"ffffffff"];
        //        ledRecord_x44 = [NSMutableString stringWithString:@"ffffffff"];
        //        x42_set = @"02ffff";
        //        x44_set = @"02ffff";
    }else{
        
//        show_log(@"Error Mode!");
        return;
    }
    NSString *x42_cmd = [NSString stringWithFormat:@"02%02x%02x",stat_1,stat_2];
//    show_log([NSString stringWithFormat:@"uut4led ledRecord_x42 %@",x42_cmd]);
    [eowyn writeI2C:x42_cmd writeadd:0x42 writelen:3];
}

void uut3led(eowynController * eowyn,NSString* mode){                   //actually UUT3
    
    [eowyn writeI2C:@"01" writeadd:0x42 writelen:1];
    unsigned char stat_1 = [eowyn readI2C:0x42 readlen:2];
    [eowyn writeI2C:@"01" writeadd:0x44 writelen:1];
    unsigned char stat_2 = [eowyn readI2C:0x44 readlen:2];
    
    
    if([mode isEqualToString:@"ready"]){                    //blue
        stat_1 = (stat_1 & 0xc7) + 0x18;
        stat_2 = stat_2 | 0x01;
        
        
    }else if([mode isEqualToString:@"idle"]){               //yellow
        stat_1 = stat_1 | 0x38;
        stat_2 = stat_2 & 0xfe;
        
    }else if([mode isEqualToString:@"pass"]){               //green
        stat_1 = (stat_1 & 0xc7) + 0x28;
        stat_2 = stat_2 | 0x01;
        
    }else if ([mode isEqualToString:@"fail"]){              //red
        stat_1 = (stat_1 & 0xc7) + 0x30;
        stat_2 = stat_2 | 0x01;
        
    }else if ([mode isEqualToString:@"init"]){              //init
        stat_1 = stat_1 | 0x38;
        stat_2 = stat_2 | 0x01;
        
    }else{
//        show_log(@"Error Mode!");
        return;
    }
    
    NSString *x42_cmd = [NSString stringWithFormat:@"02%02x",stat_1];
    NSString *x44_cmd = [NSString stringWithFormat:@"02%02x",stat_2];
    
//    show_log([NSString stringWithFormat:@"uut3led ledRecord_x42 %@",x42_cmd]);
//    show_log([NSString stringWithFormat:@"uut3led ledRecord_x44 %@",x44_cmd]);
    
    [eowyn writeI2C:x42_cmd writeadd:0x42 writelen:2];
    [eowyn writeI2C:x44_cmd writeadd:0x44 writelen:2];
    
    
}

void uut2led(eowynController * eowyn,NSString* mode){
    
    [eowyn writeI2C:@"01" writeadd:0x42 writelen:1];
    unsigned char stat_1 = [eowyn readI2C:0x42 readlen:2];
    [eowyn writeI2C:@"02" writeadd:0x42 writelen:1];
    unsigned char stat_2 = [eowyn readI2C:0x42 readlen:2];
    [eowyn writeI2C:@"01" writeadd:0x44 writelen:1];
    unsigned char stat_3 = [eowyn readI2C:0x44 readlen:2];
    
    
    if([mode isEqualToString:@"ready"]){                    //blue
        stat_1 = stat_1 | 0xc0;
        stat_2 = stat_2 & 0xfe;
        stat_3 = stat_3 | 0x02;
        
        
    }else if([mode isEqualToString:@"idle"]){               //yellow
        stat_1 = stat_1 | 0xc0;
        stat_2 = stat_2 | 0x01;
        stat_3 = stat_3 & 0xfd;
        
    }else if([mode isEqualToString:@"pass"]){               //green
        stat_1 = (stat_1 & 0x3f) + 0x40;
        stat_2 = stat_2 | 0x01;
        stat_3 = stat_3 | 0x02;
        
    }else if ([mode isEqualToString:@"fail"]){              //red
        stat_1 = (stat_1 & 0x3f) + 0x80;
        stat_2 = stat_2 | 0x01;
        stat_3 = stat_3 | 0x02;
        
    }else if ([mode isEqualToString:@"init"]){              //init
        stat_1 = stat_1 | 0xc0;
        stat_2 = stat_2 | 0x01;
        stat_3 = stat_3 | 0x02;
        
    }else{
        
        
        return;
    }
    
    NSString *x42_cmd = [NSString stringWithFormat:@"02%02x%02x",stat_1,stat_2];
    NSString *x44_cmd = [NSString stringWithFormat:@"02%02x",stat_3];
    
//    show_log([NSString stringWithFormat:@"uut2led ledRecord_x42 %@",x42_cmd]);
//    show_log([NSString stringWithFormat:@"uut2led ledRecord_x44 %@",x44_cmd]);
    
    [eowyn writeI2C:x42_cmd writeadd:0x42 writelen:3];
    [eowyn writeI2C:x44_cmd writeadd:0x44 writelen:2];
}


@end
