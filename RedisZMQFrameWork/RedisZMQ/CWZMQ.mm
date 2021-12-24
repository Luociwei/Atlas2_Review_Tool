//
//  CWZMQ.m
//  Atlas2_Review_Tool
//
//  Created by ciwei luo on 2021/12/11.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "CWZMQ.h"
#import "Client.h"
//#define  cpk_zmq_addr           @"tcp://127.0.0.1:3100"
@interface CWZMQ ()

@end


@implementation CWZMQ{
    Client *zmqClient;
//    NSString *f
}

+(void)load{
    system("/usr/bin/ulimit -n 8192");
}

-(instancetype)initWithURL:(NSString *)url{
    if (self == [super init]) {
        zmqClient = [[Client alloc] init];   // connect CPK zmq for PythonTest.py
        [zmqClient CreateRPC:url withSubscriber:nil];
        [zmqClient setTimeout:10*1000];
    }
    
    return self;
    
}

-(instancetype)initWithURL:(NSString *)url pythonFile:(NSString *)filePath{
    if (self == [super init]) {
        zmqClient = [[Client alloc] init];   // connect CPK zmq for PythonTest.py
        [zmqClient CreateRPC:url withSubscriber:nil];
        [zmqClient setTimeout:10*1000];
        
        [self lanuchPythonFile:filePath];
    }
    
    return self;
    
}

-(instancetype)initWithURL:(NSString *)url pythonFile:(NSString *)filePath launchPath:(NSString *)launchPath{
    if (self == [super init]) {
        zmqClient = [[Client alloc] init];   // connect CPK zmq for PythonTest.py
        [zmqClient CreateRPC:url withSubscriber:nil];
        [zmqClient setTimeout:20*1000];
        
        [self lanuchPythonFile:filePath launchPath:launchPath];
    }
    
    return self;
    
}

-(void)lanuchPythonFile:(NSString *)filePath launchPath:(NSString *)launchPath{
    
    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
//    NSString * launchPath = [resourcePath stringByAppendingString:@"/Python/NewEnv/pythonProject/bin/python3.10"];
    
    NSString * arg = [resourcePath stringByAppendingPathComponent:@"/Python/pythonProject/main.py"];
    NSString *logCmd = @"ps -ef |grep -i python |grep -i main.py |grep -v grep|awk '{print $2}' | xargs kill -9";
    system([logCmd UTF8String]); //杀掉PythonTest.py 进程
    [self execute_withTask:launchPath withPython:arg];
    
}


-(void)lanuchPythonFile:(NSString *)filePath{
    
    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString * launchPath = [resourcePath stringByAppendingString:@"/Python/NewEnv/pythonProject/bin/python2.7"];
    
    NSString * arg = [resourcePath stringByAppendingPathComponent:@"/Python/pythonProject/main.py"];
    NSString *logCmd = @"ps -ef |grep -i python |grep -i main.py |grep -v grep|awk '{print $2}' | xargs kill -9";
    system([logCmd UTF8String]); //杀掉PythonTest.py 进程
    [self execute_withTask:launchPath withPython:arg];
    
}



-(int)execute_withTask:(NSString*) szcmd withPython:(NSString *)arg{
    
    if (!szcmd) return -1;
    NSTask * task = [[NSTask alloc] init];
    [task setLaunchPath:szcmd];
    [task setArguments:[NSArray arrayWithObjects:arg, nil]];
    [task launch];
    return 0;
}

-(BOOL)send:(id)msg{
    BOOL b_result = NO;

    if([msg isKindOfClass:[NSString class]]){
        NSString *msg_str = [NSString stringWithString:msg];
        b_result = [self sendString:msg_str];

    } else if ([msg isKindOfClass:[NSArray class]] || [msg isKindOfClass:[NSDictionary class]]) {
        
        NSString *valueStr = [self jsonSerialize:msg];
        b_result = [self sendString:valueStr];
        
    }
    else{
        NSString *msg_str = [NSString stringWithFormat:@"%@",msg];
        b_result = [self sendString:msg_str];
    }

    return b_result;

}

-(BOOL)sendString:(NSString *)msg{
    int r = [zmqClient SendCmd:msg];
    return r > 0;
}

-(NSString *)read{
	return [self read:1000*1024];
}

-(NSString *)read:(NSInteger)size{
    if (size<=0) {
        size = 1024;
    }
    NSString * retStr = [zmqClient RecvRquest:size];
    
    if (([retStr containsString:@"["]&&[retStr containsString:@"]"])||([retStr containsString:@"{"]&&[retStr containsString:@"}"])) {
        
        return [self jsonStringUnserialize:retStr];
    }else{
        return retStr;
    }
}


+(void)shutdown{
    NSString *logCmd = @"ps -ef |grep -i python |grep -i main.py |grep -v grep|awk '{print $2}' | xargs kill -9";
    system([logCmd UTF8String]); //杀掉PythonTest.py 进程
}

-(BOOL)sendMessage:(NSString *)name event:(NSString *)event params:(NSArray *)params{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setObject:name forKey:@"name"];
    [dict setObject:event forKey:@"event"];
    [dict setObject:params forKey:@"params"];
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingFragmentsAllowed error:nil];
//    NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSLog(@"sendMessage:%@",strJson);
    return [self send:dict];
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
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingFragmentsAllowed error:nil];

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
