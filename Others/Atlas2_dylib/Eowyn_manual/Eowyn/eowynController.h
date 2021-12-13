//
//  eowynContoller.h
//  Eowyn
//
//  Created by gdlocal on 2021/6/17.
//  Copyright © 2021 gdlocal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <ATDeviceElements/ATDeviceEowyn.h>
#import <ATDeviceElements/ATDeviceElements.h>

NS_ASSUME_NONNULL_BEGIN

@interface eowynController : NSObject
{
    ATDeviceBusInterface* interface;
    ATDeviceEowyn * eowyn;
}

-(id)init;
-(BOOL)connectWithIP:(NSString *)connectIP;
-(BOOL)configEuropeanConnector;
-(BOOL)configI2C;
-(BOOL)writeIO:(NSInteger)iOIndex value:(ATDeviceDIOType)value;
-(ATDeviceDIOType)readIO:(NSInteger)iOIndex;
-(BOOL)writeI2C:(NSString *)writeData writeadd:(int)add writelen:(int)length;
-(int)readI2C:(int)readadd readlen:(int)len;
//-(float)readTempI2C:(int)readadd readlen:(int)len;
-(int)readFanI2C:(int)readadd readlen:(int)len;
-(int)readDUTI2C:(int)readadd readlen:(int)len;
-(NSString *)getBinaryByHex:(NSString *)hex;

-(BOOL)writeI2C:(uint8_t *)writeData writeadd:(int)add writelen:(int)length busId:(int)busId;
-(BOOL)writeI2CWithString:(NSString *)writeString writeadd:(int)add writelen:(int)length busId:(int)busId;
-(NSString *)readI2CWithString:(NSString *)writeString writeadd:(int)add writelen:(int)length busId:(int)busId;

-(int)readI2C:(int)readadd readlen:(int)len busId:(int)busId;
-(unsigned char *)readI2C_arr:(int)readadd readlen:(int)len busId:(int)busId;
-(NSString *)readI2C_STR:(int)readadd readlen:(int)len busId:(int)busId;

-(ATDeviceDIOType)readDutIO:(NSInteger)iOIndex;
-(void)close;
-(ATDeviceDIOType)readIO:(NSInteger)iOIndex printLog:(BOOL)printLog;
-(ATDeviceDIOType)readDutIO:(NSInteger)iOIndex printLog:(BOOL)printLog;

@end

NS_ASSUME_NONNULL_END
