//
//  Client.m
//  MainUI
//
//  Copyright © 2015年 ___sc Automation___. All rights reserved.
//

#import "Client.h"

//void * OnSubscriber(void * buf,long len,void * context)
//{
//
//    Client * pClient = (Client *)context;
//    NSString * str = [NSString stringWithUTF8String:(char *)buf];
//    [pClient OnSubscriberData:str];
//    return nullptr;
//}

@implementation Client
-(id)init
{
    self = [super init];
    if (self) {
        pRequester = new CRequester();
        pSubscriber = new CSubscriber();
        //pSubscriber->SetCallBack(OnSubscriber, self);
    }
    return self;
}

-(int)CreateRPC:(NSString *)ipRequest withSubscriber:(NSString *)ipSubscriber
{
    //Requester
    if  (ipRequest)
    {
        pRequester->close();
        pRequester->connect([ipRequest UTF8String]);
        pRequester->SetTimeOut(5*1000);
    }
    
    
    //Subscriber
    if (ipSubscriber) {
        pSubscriber->close();
        //pSubscriber->SetFilter("101");
        pSubscriber->connect([ipSubscriber UTF8String]);
    }
    
    return 0;
}

-(void)setTimeout:(int)timeout
{
    pRequester->SetTimeOut(timeout);
}
-(void)SetFilter:(NSString *)filter
{
    pSubscriber->SetFilter([filter UTF8String]);
}
-(int)SendCmd:(NSString *)cmd
{
    return pRequester->RequestString([cmd UTF8String],NO);
}

-(NSString *)RecvRquest
{
//    char * pbuffer = new char[10*1024*1024];
//    memset(pbuffer, 0, 10*1024*1024);
    char * pbuffer = new char[100*1024];
    memset(pbuffer, 0, 100*1024);
    int ret = pRequester->Recv(pbuffer, nullptr);
    if (ret<0) {
        delete[] pbuffer;
        return nil;
    }
    pbuffer[ret]=0; //add 0;
    NSString * response = [NSString stringWithUTF8String:pbuffer];
    delete[] pbuffer;
    return response;
}

-(NSString *)RecvRquest:(NSInteger)size
{
    char * pbuffer = new char[size];
    memset(pbuffer, 0, size);
    int ret = pRequester->Recv(pbuffer, nullptr);
    if (ret<0) {
        delete[] pbuffer;
        return nil;
    }
    pbuffer[ret]=0; //add 0;
    NSString * response = [NSString stringWithUTF8String:pbuffer];
    delete[] pbuffer;
    return response;
}

-(void)OnSubscriberData:(NSString *)msg
{
}
+(NSString *)CreateRequestString:(NSDictionary *)dic
{
    NSError *error = nil;
    NSString *jsonString=nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if([jsonData length] > 0 && error == nil) {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSString * tmp = [NSString stringWithString:jsonString];
        return tmp;
    }
    else
    {
        NSLog(@"Convert error : %@",error);
    }
    
    return nil;
}


@end
