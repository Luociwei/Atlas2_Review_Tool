//
//  NSString+Extension.m
//  Smart_Charge
//
//  Created by Louis Luo on 2017/8/5.
//  Copyright © 2017 Innorev. All rights reserved.
//

#import "NSString+Extension.h"
#import "Alert.h"

@implementation NSString (Extension)

-(NSString *)cw_getSubstringFromIndex:(NSInteger)fromIndex toLength:(NSInteger)length
{
    if (self.length<(fromIndex+length)) {
        [Alert cw_RemindException:@"Error" Information:@"length beyond bounds"];
        NSLog(@"length beyond bounds");
        return @"";
    }
    NSString *mutStr = [self substringFromIndex:fromIndex];
    NSString *returnString = [mutStr substringToIndex:length];
    return returnString;
}

-(NSString *)cw_getSubstringFromString:(NSString *)from toLength:(NSInteger)length
{
    
    NSString *returnString = nil;
    
    if ([self containsString:from]) {
        NSRange range1 = [self rangeOfString:from];
        NSRange range2 = NSMakeRange(range1.location+range1.length, length);
        if (range1.location+range1.length+length<=self.length) {
            returnString = [self substringWithRange:range2];
        }else{
            NSLog(@"length beyond bounds");
            [Alert cw_RemindException:@"Error" Information:@"length beyond bounds"];
        }
        
    }else{
        [Alert cw_RemindException:@"Error" Information:[NSString stringWithFormat:@"%@ not found %@",self,from]];
        NSLog(@"%@ not found %@",self,from);
    }
    
    return returnString;
    
}

-(NSString *)cw_getSubstringFromStringToEnd:(NSString *)from
{
    NSString *returnString = nil;
    
    if ([self containsString:from]) {
        NSRange range = [self rangeOfString:from];
        returnString = [self substringFromIndex:range.location+range.length];
    }else{
        [Alert cw_RemindException:@"Error" Information:[NSString stringWithFormat:@"%@ not found %@",self,from]];
        NSLog(@"%@ not found %@",self,from);
    }
    
    return returnString;
}

-(NSString *)cw_getStringBetween:(NSString *)from and:(NSString *)to
{
    NSString *mutString = @"";
    if([self containsString:from]&&[self containsString:to])
    {
        
        NSRange range1 = [self rangeOfString:from];
        NSRange range2 = [self rangeOfString:to];
        
        NSInteger tempLength =range2.location-range1.location-range1.length;
        NSRange range = {range1.location+range1.length,tempLength};
        mutString = [self substringWithRange:range];
        
    }
    return mutString;
}

-(NSString *)cw_getStringBetween:(NSString *)from toLength:(NSInteger)legth separate:(NSString *)separate index:(NSInteger)index
{
    NSString *tempString = nil;
    tempString = [self cw_getSubstringFromString:from toLength:legth];
    NSString *returnString = [tempString cw_getSubstringSeparate:separate index:index];
    return returnString;
}
//cw_getSubstringFromStringToEnd

-(NSString *)cw_getSubstringFromStringToEnd:(NSString *)from separate:(NSString *)separate index:(NSInteger)index
{
    NSString *tempString = [self cw_getSubstringFromStringToEnd:from];
    NSString *returnString = [tempString cw_getSubstringSeparate:separate index:index];
    return returnString;
}

-(NSString *)cw_getStringBetween:(NSString *)from and:(NSString *)to separate:(NSString *)separate index:(NSInteger)index
{
    NSString *tempString = nil;
    if (to==nil) {
        tempString = [self cw_getSubstringFromStringToEnd:from];
    }else{
        tempString = [self cw_getStringBetween:from and:to];
    }
    
    NSString *returnString = [tempString cw_getSubstringSeparate:separate index:index];
    return returnString;
}

-(NSArray *)cw_componentsSeparatedByString:(NSString *)separate
{
    NSArray *mutArray=nil;
    if([self containsString:separate])
    {
        mutArray = [self componentsSeparatedByString:separate];
    }else{
        [Alert cw_RemindException:@"Error" Information:[NSString stringWithFormat:@"%@ not found %@",self,separate]];
        NSLog(@"%@ not found %@",self,separate);
    }
    return mutArray;
}

-(NSString *)cw_getSubstringSeparate:(NSString *)separate index:(NSInteger)index
{
    NSMutableString *mutString = [NSMutableString stringWithString:self];
    NSArray *mutArray;
    if([mutString containsString:separate])
    {
        mutArray = [mutString componentsSeparatedByString:separate];
    }else{
        [Alert cw_RemindException:@"Error" Information:[NSString stringWithFormat:@"%@ not found %@",mutString,separate]];
        NSLog(@"%@ not found %@",mutString,separate);
    }
    NSString *returnString;
    if (mutArray.count>index) {
        returnString = [mutArray objectAtIndex:index];
    }else{
        [Alert cw_RemindException:@"Error" Information:[NSString stringWithFormat:@"index %ld beyond bounds,NSArray:%@",index,self]];
        NSLog(@"index %ld beyond bounds,NSArray:%@",index,self);
    }
    return returnString;
}


-(NSString *)cw_deleteSpecialCharacter:(NSString *)chargcter
{
    return [self stringByReplacingOccurrencesOfString:chargcter withString:@""];
}

+(NSString *)cw_returnJoinStringWithArray:(NSArray *)array
{
    NSMutableString *mutStr = [NSMutableString string];
    int index = 0;
    for (NSString *str in array) {
        if (index == 0) {
            [mutStr appendString:[NSString stringWithFormat:@"%@",str]];
        }else{
            
            [mutStr appendString:[NSString stringWithFormat:@",%@",str]];
        }
        index++;
    }
    [mutStr appendString:@"\n"];
    return (NSString *)mutStr;
}


+(id)cw_getDataWithJosnFile:(NSString *)configfile
{
    //NSString *configfile = [[NSBundle mainBundle] pathForResource:@"EEEECode" ofType:@"json"];
    NSString* items = [NSString stringWithContentsOfFile:configfile encoding:NSUTF8StringEncoding error:nil];
    NSData *data= [items dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    return jsonObject;
}

+(id)cw_getDataWithPathForResource:(NSString *)fileName
{
    
    NSArray *array = nil;
    if ([fileName containsString:@"."]) {
        array = [fileName componentsSeparatedByString:@"."];
        if (array.count!=2) {
            [Alert cw_RemindException:@"Error" Information:@"wrong file name"];
            NSLog(@"wrong file name");
            return @"";
        }
    }else{
        [Alert cw_RemindException:@"Error" Information:@"wrong file name"];
        NSLog(@"wrong file name");
        return @"";
    }
    NSString *name = array[0];
    NSString *type = array[1];
    id data=nil;
    NSString *configfile = [[NSBundle mainBundle] pathForResource:name ofType:type];
    if ([type isEqualToString:@".txt"]|| [type containsString:@".plist"] || [type containsString:@".csv"]) {
        
    }else if ([type containsString:@".json"]){
        data=[self cw_getDataWithJosnFile:configfile];
    }
    
    return data;
}

+(NSString *)cw_getResourcePath{
    return [[NSBundle mainBundle] resourcePath];
}

+(NSString *)cw_getDesktopPath
{
    NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)lastObject];
    return desktopPath;
    //     NSString *eCodePath=[desktopPath stringByDeletingLastPathComponent];
}
+(NSString *)cw_getUserPath
{
    NSString *desktopPath = [self cw_getDesktopPath];
    
    NSString *userPath=[desktopPath stringByDeletingLastPathComponent];
    return userPath;
}


+(NSMutableArray *)cw_getFileNameListInDirPath:(NSString *)filePath str1:(NSString *)str1 {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *de = [fm enumeratorAtPath:filePath];
    NSString *f;
    NSMutableArray *fileNameList = [NSMutableArray array];
    
    while ((f = [de nextObject]))
    {
        if ([f containsString:str1]||[f containsString:str1.lowercaseString]) {
            // fqn = [filePath stringByAppendingPathComponent:f];
            
            [fileNameList addObject:f];
            
        }
    }
    
    
    return fileNameList;
}


+(NSMutableArray *)cw_getFileNameListInDirPath:(NSString *)filePath str1:(NSString *)str1 str2:(NSString *)str2{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *de = [fm enumeratorAtPath:filePath];
    NSString *f;
    NSMutableArray *fileNameList = [NSMutableArray array];
    
    while ((f = [de nextObject]))
    {
        if (([f containsString:str1]||[f containsString:str1.lowercaseString])&&([f containsString:str2]||[f containsString:str2.lowercaseString])) {
            // fqn = [filePath stringByAppendingPathComponent:f];
            
            [fileNameList addObject:f];
            
        }
    }
    
    
    return fileNameList;
}


+ (NSString *)cw_nowTimeWithMicrosecond:(BOOL)isMicrosecond
{
    
    NSString *dateFormat = isMicrosecond ? @"yyyy-MM-dd hh:mm:ss:SS" : @"yyyy-MM-dd hh:mm:ss";
    
    NSString *newDateString = [self cw_stringFromDate:[NSDate date] dateFormat:dateFormat];
    
    return newDateString;
}

+(NSString *)cw_stringFromCurrentDateTime
{
    return [self cw_stringFromDate:[NSDate date] dateFormat:@"yyyy-MM-dd"];
}

+(NSString *)cw_stringFromCurrentDateTimeWithSecond
{
    return [self cw_nowTimeWithMicrosecond:NO];
}

+(NSString *)cw_stringFromCurrentDateTimeWithMicrosecond
{
    return [self cw_nowTimeWithMicrosecond:YES];
}

+(time_t)cw_Time_tSince1970
{
    time_t tempTime;
    time(&tempTime);
    return tempTime;
}

+(NSDate *)cw_getDateFrom:(NSString *)dateStr dateFormat:(NSString *)dateFormat{
    if (!dateFormat.length) {
        dateFormat = @"yyyy-MM-dd hh:mm:ss";
    }
    //20210416_15-57-50.001-A772CC
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //需要设置为和字符串相同的格式
    [dateFormatter setDateFormat:dateFormat];
    NSDate *localDate = [dateFormatter dateFromString:dateStr];
    return localDate;
}

+(NSString *)cw_stringFromDate:(NSDate *)date dateFormat:(NSString *)dateFormat
{
    if (!dateFormat.length) {
        dateFormat = @"yyyy-MM-dd hh:mm:ss";
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)cw_dictionaryToJSONString:(NSDictionary *)dictionary

{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //    NSString *jsonTemp = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    //    NSString *jsonResult = [jsonTemp stringByReplacingOccurrencesOfString:@" " withString:@""];
    return jsonString;
}


+ (NSString *)cw_arrayToJSONString:(NSArray *)array

{
    NSError *error = nil;
    //    NSMutableArray *muArray = [NSMutableArray array];
    //    for (NSString *userId in array) {
    //        [muArray addObject:[NSString stringWithFormat:@"\"%@\"", userId]];
    //    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //    NSString *jsonTemp = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    //    NSString *jsonResult = [jsonTemp stringByReplacingOccurrencesOfString:@" " withString:@""];
    //    NSLog(@"json array is: %@", jsonResult);
    return jsonString;
}

-(unsigned char)cw_stringToHex{
    NSInteger len = self.length;
    unsigned char aucKey[len/2] ;
    memset(aucKey, 0, sizeof(aucKey));
    
    int idx = 0;
    for (int j=0; j<len; j+=2)
    {
        NSString *hexStr = [self substringWithRange:NSMakeRange(j, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:hexStr];
        unsigned long long longValue ;
        [scanner scanHexLongLong:&longValue];
        unsigned char c = longValue;
        aucKey[idx] = c;
        idx++;
    }
    
    return aucKey[len/2];
}
//16进制转10进制
- (NSString *)ToDecimalWithHex:(NSString *)hex_str{
    NSString * temp10 = [NSString stringWithFormat:@"%lu",strtoul([hex_str UTF8String],0,16)];
    NSLog(@"心跳数字 10进制 %@",temp10);
    return temp10;
}

//  十进制转十六进制
- (NSString *)ToHexWithDecimalSystem:(uint16_t)decimal
{
    NSString *nLetterValue;
    NSString *str =@"";
    uint16_t ttmpig;
    NSString *n1;
    
    //    for (int i = 0; i<9; i++) {
    ttmpig=decimal%16;
    decimal=decimal/16;
    switch (ttmpig)
    {
        case 10:
            nLetterValue =@"A";break;
        case 11:
            nLetterValue =@"B";break;
        case 12:
            nLetterValue =@"C";break;
        case 13:
            nLetterValue =@"D";break;
        case 14:
            nLetterValue =@"E";break;
        case 15:
            nLetterValue =@"F";break;
        default:
            nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
            
    }
    //        str = [nLetterValue stringByAppendingString:str];
    
    if (decimal ==0) {
        str=[str stringByAppendingString:[NSString stringWithFormat:@"0%@",nLetterValue]];
        return str;
    }
    
    if(decimal >0 && decimal<=16){
        switch (decimal)
        {
            case 10:
                n1 =@"A";break;
            case 11:
                n1 =@"B";break;
            case 12:
                n1 =@"C";break;
            case 13:
                n1 =@"D";break;
            case 14:
                n1 =@"E";break;
            case 15:
                n1 =@"F";break;
            default:
                n1 = [NSString stringWithFormat:@"%u",decimal];
                
        }
        
        str = [n1 stringByAppendingString:nLetterValue];
    }
    
    return str;
}

//  十进制转二进制
+ (NSString *)toBinarySystemWithDecimalSystem:(NSString *)decimal{
    int num = [decimal intValue];
    int remainder = 0;      //余数
    int divisor = 0;        //除数
    NSString * prepare = @"";
    while (true){
        remainder = num%2;
        divisor = num/2;
        num = divisor;
        prepare = [prepare stringByAppendingFormat:@"%d",remainder];
        if (divisor == 0){
            break;
        }
    }
    NSString * result = @"";
    for (NSInteger i = prepare.length - 1; i >= 0; i --){
        result = [result stringByAppendingFormat:@"%@",
                  [prepare substringWithRange:NSMakeRange(i , 1)]];
        
    }
    
    return result;
    
}

//  二进制转十进制
+ (NSString *)toDecimalSystemWithBinarySystem:(NSString *)binary{
    int ll = 0 ;
    int  temp = 0 ;
    for (int i = 0; i < binary.length; i ++){
        temp = [[binary substringWithRange:NSMakeRange(i, 1)] intValue];
        temp = temp * powf(2, binary.length - i - 1);
        ll += temp;
    }
    
    NSString * result = [NSString stringWithFormat:@"%d",ll];
    return result;
}


//strtoul([add_str UTF8String],0,16)
-(unsigned char)cw_cStringToHex{
    return strtoul([self UTF8String],0,16);
}

+(NSString *)cw_hexToString:(unsigned char *)hashword{
    NSString *password = @"";
    long len = sizeof(hashword);
    for (int m = 0; m < len; m++) {
        unsigned long c = hashword[m];
        password = [password stringByAppendingFormat:@"%02lx",c];
    }
    return password;
}

/**
 十六进制转换为二进制
 @param hex 十六进制数
 @return 二进制数
 */
+ (NSString *)cw_getBinaryByHex:(NSString *)hex {
    //    NSString *hex = @"";
    //    if (mut_hex.length==8 && [mut_hex containsString:@"ffffff"]) {
    //        hex=[mut_hex stringByReplacingOccurrencesOfString:@"ffffff" withString:@""];
    //    }
    NSMutableDictionary *hexDic = [[NSMutableDictionary alloc] initWithCapacity:16];
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
    return binary;
}
/**
 二进制转换成十六进制
 
 @param binary 二进制数
 @return 十六进制数
 */
+ (NSString *)cw_getHexByBinary:(NSString *)binary {
    
    NSMutableDictionary *binaryDic = [[NSMutableDictionary alloc] initWithCapacity:16];
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
    return hex;
}


+(NSString *)cw_NSStringFromRect:(NSRect)frame{
    return NSStringFromRect(frame);
}
//            NSLog(@"%@",NSStringFromRect(tabVC.view.frame)) ;
//            NSLog(@"%@",NSStringFromRect([[NSScreen mainScreen] visibleFrame])) ;
//            tabVC.view.frame = [[NSScreen mainScreen] visibleFrame];
@end
