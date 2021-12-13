//
//  Eowyn.h
//  Eowyn
//
//  Created by gdlocal on 2021/6/17.
//  Copyright © 2021 gdlocal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "fixtureControl.h"

NS_ASSUME_NONNULL_BEGIN

@interface Eowyn : NSObject
{
    fixtureControl *fixtureCtl;
    int status_flag;

}

-(id)connectEowyn:(NSString *)ip withLogPath:(NSString *)path error:(NSError **)error;
-(id)writeReadString:(NSString *)cmd error:(NSError **)error;
-(id)fixture_open:(NSError **)error;
-(id)fixture_close:(NSError **)error;

-(id)led_red_on:(NSNumber *)site error:(NSError **)error;
-(id)led_green_on:(NSNumber *)site error:(NSError **)error;
-(id)led_inprogress_on:(NSNumber *)site error:(NSError **)error;
-(id)led_gotoFA_on:(NSNumber *)site error:(NSError **)error;
-(id)led_panic_on:(NSNumber *)site error:(NSError **)error;
-(id)led_off:(NSNumber *)site error:(NSError **)error;
-(id)led_init:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
