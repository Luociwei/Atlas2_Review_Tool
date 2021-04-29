//
//  NSString+Extension.h
//  Smart_Charge
//
//  Created by Louis Luo on 2017/8/5.
//  Copyright © 2017 Innorev. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Extension)

/*
 NSString+Cut
 */
-(NSString *)cw_getStringBetween:(NSString *)from and:(NSString *)to;
-(NSString *)cw_getSubstringFromIndex:(NSInteger)fromIndex toLength:(NSInteger)length;
-(NSString *)cw_getSubstringFromStringToEnd:(NSString *)from;
-(NSString *)cw_getSubstringFromString:(NSString *)from toLength:(NSInteger)length;
-(NSString *)cw_deleteSpecialCharacter:(NSString *)chargcter;

+(NSString *)cw_returnJoinStringWithArray:(NSArray *)array;


-(NSArray *)cw_componentsSeparatedByString:(NSString *)separate;
-(NSString *)cw_getSubstringSeparate:(NSString *)separate index:(NSInteger)index;
-(NSString *)cw_getSubstringFromStringToEnd:(NSString *)from separate:(NSString *)separate index:(NSInteger)index;
-(NSString *)cw_getStringBetween:(NSString *)from and:(NSString *)to separate:(NSString *)separate index:(NSInteger)index;




/*
 NSString+Path
 */
+(NSString *)cw_getDesktopPath;

+(NSString *)cw_getUserPath;

+(NSString *)cw_getResourcePath;


+(NSMutableArray *)cw_getFileNameListInDirPath:(NSString *)filePath str1:(NSString *)str1;
+(NSMutableArray *)cw_getFileNameListInDirPath:(NSString *)filePath str1:(NSString *)str1 str2:(NSString *)str2;



/*
 NSString+Date
 */
+(NSString *)cw_stringFromCurrentDateTimeWithSecond;

+(NSString *)cw_stringFromCurrentDateTimeWithMicrosecond;

+(time_t)cw_Time_tSince1970;

+(NSString *)cw_stringFromDate:(NSDate *)date dateFormat:(NSString *)dateFormat;


+ (NSString *)cw_dictionaryToJSONString:(NSDictionary *)dictionary;
+ (NSString *)cw_arrayToJSONString:(NSArray *)array;


//进制转换
-(unsigned char)cw_stringToHex;
+(NSString *)cw_hexToString:(unsigned char *)hashword;
+ (NSString *)cw_getBinaryByHex:(NSString *)hex;
+ (NSString *)cw_getHexByBinary:(NSString *)binary;

//frame
+(NSString *)cw_NSStringFromRect:(NSRect)frame;

@end

NS_ASSUME_NONNULL_END
