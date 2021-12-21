//
//  CWRedis.m
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/12/11.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "CWRedis.h"
#import "RedisInterface.hpp"
@interface CWRedis ()

@end


@implementation CWRedis{
    RedisInterface *myRedis;
}

+(void)flushall{
    NSString *file_cli = [[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"redis-cli"] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
      file_cli = [file_cli stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
      file_cli = [file_cli stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    NSString *cli_Path = [NSString stringWithFormat:@"%@ flushall",file_cli];
    for (int i=0; i<3; i++)
    system([cli_Path UTF8String]);
}

+(void)shutDown
{
    NSString *file_cli = [[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"redis-cli"] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
      file_cli = [file_cli stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
      file_cli = [file_cli stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    NSString *cli_Path = [NSString stringWithFormat:@"%@ flushall",file_cli];
    for (int i=0; i<3; i++)
    system([cli_Path UTF8String]);
    
     NSString *cli_shutdown = [NSString stringWithFormat:@"%@ -p 6379 shutdown",file_cli];
     system([cli_shutdown UTF8String]);
    
    NSString *killRedis = @"ps -ef |grep -i redis-server |grep -v grep|awk '{print $2}' |xargs kill -9";
    system([killRedis UTF8String]);
    [NSThread sleepForTimeInterval:0.1];
    
    NSString *logCmd1 = @"ps -ef |grep -i python |grep -i main |grep -v grep|awk '{print $2}' |xargs kill -9";
    system([logCmd1 UTF8String]);
   

}

+(void)load{
    [self OpenRedisServer];
//    NSString *resorcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
}

+(void)OpenRedisServer
{
    NSString *file_cli = [[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"redis-cli"] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    
    file_cli = [file_cli stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
    file_cli = [file_cli stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    
//    NSString *cli_shutdown = [NSString stringWithFormat:@"%@ -p 6379 shutdown",file_cli];
//    system([cli_shutdown UTF8String]);
//    
//    [NSThread sleepForTimeInterval:0.2];
//    system([cli_shutdown UTF8String]);
//    [NSThread sleepForTimeInterval:0.4];
    
    NSString *killRedis = @"ps -ef |grep -i redis-server |grep -v grep|awk '{print $2}' |xargs kill -9";
    system([killRedis UTF8String]);
    system([killRedis UTF8String]);
    [NSThread sleepForTimeInterval:0.2];
    //NSString *file = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"redis-server&"] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    NSString *file_config = [[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"redis.conf"] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    NSString *file = [[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"redis-server"] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    
    file = [NSString stringWithFormat:@"%@ %@",file,file_config];
    
    file = [file stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
    file = [file stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    system([file UTF8String]);
    
//    NSString *cli_cmd1 = [NSString stringWithFormat:@"%@ config set stop-writes-on-bgsave-error no",file_cli];
//    system([cli_cmd1 UTF8String]);
//
//    NSString *cli_cmd2 = [NSString stringWithFormat:@"%@ config set stop-writes-on-bgsave-error no",file_cli];
//    system([cli_cmd2 UTF8String]);
    
    [NSThread sleepForTimeInterval:0.2];
    NSString *cli_Path = [NSString stringWithFormat:@"%@ flushall",file_cli];
    for (int i=0; i<3; i++)
        system([cli_Path UTF8String]);
    
}

-(BOOL)connect{
    
    myRedis = new RedisInterface();  // redis client connect
    myRedis->Connect();
    myRedis->SetString("test", "yes");
    const char *ret = myRedis->GetString("test");
    NSString *str_ret =[NSString stringWithUTF8String:ret];
    BOOL isConnected =[str_ret isEqualToString:@"yes"];
    return isConnected;
}

-(BOOL)setString:(NSString *)key value:(id)value{
    if (!key.length) {
        NSLog(@"func:redis.setString--the key_name inputted is null!!!");
        return NO;
    }
    NSString *valueStr = @"";
    if ([value isKindOfClass:[NSString class]]) {
        valueStr = (NSString *)value;
        
        
    }else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]){
        valueStr = [self jsonSerialize:value];
        
    }else{
        valueStr = [NSString stringWithFormat:@"%@",value];
        
    }
    if (valueStr.length) {
        BOOL b = myRedis->SetString(key.UTF8String, valueStr.UTF8String);
        return b;
    }else{
        NSLog(@"func:redis.setString--the value inputted is null!!!");
        return NO;
    }
    
    
}

-(id)get:(NSString *)key{
    if (!key.length) {
        NSLog(@"func:redis.get--the key_name inputted must be string!!!");
        return nil;
    }
    const char *ret = myRedis->GetString(key.UTF8String);
    NSString *retStr = [NSString stringWithUTF8String:ret];
    if (([retStr containsString:@"["]&&[retStr containsString:@"]"])||([retStr containsString:@"{"]&&[retStr containsString:@"}"])) {
        
        return [self jsonStringUnserialize:retStr];
    }else{
        return retStr;
    }
    
}
//将字典转换成json格式字符串,是否含\n这些符号
- (NSString *)jsonSerialize:(id)obj{
    
    //    BOOL isArrar =[obj isKindOfClass:[NSArray class]];
    //    BOOL isDict =[obj isKindOfClass:[NSDictionary class]];
    BOOL isValidJSONObject =[NSJSONSerialization isValidJSONObject:obj];
    
    if (!isValidJSONObject) {
        NSLog(@"%@", [NSString stringWithFormat:@"obj:%@--isValidJSONObject",obj]);
        return nil;
        
    }
    //    NSJSONWritingPrettyPrinted
    //    NSJSONWritingOptions option = isWritingPrinted ? NSJSONWritingPrettyPrinted : 0;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    
    NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return strJson;
    
}

// JSON字符串转化为字典
-(id)jsonStringUnserialize:(NSString *)str
{
    if (!str.length) {
        return nil;
    }
    
    NSData *jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                             options:NSJSONReadingMutableContainers
                                               error:&err];
    if(err)
    {
//        [Alert cw_RemindException:@"Error" Information:[NSString stringWithFormat:@"json解析失败：%@",err]];
        NSLog(@"json解析失败--string:%@--error:%@",self,err);
        return nil;
    }
    return dic;
}



@end
