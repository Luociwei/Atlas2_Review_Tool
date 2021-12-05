//
//  main.m
//  test
//
//  Created by IvanGan on 16/10/18.
//  Copyright © 2016年 IvanGan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFUFixture.h"
#import "USBDevice.h"


void on_fixture_event(const char* sn, void *controller, void* event_ctx, int site, int event_type)
{
    NSLog(@"---fixture event call back : %s, %d, %d",sn, site,event_type);
    for (int i=1; i<3; i++) {
        sleep(1);
        NSLog(@"---my fixture event call back: %d",i);
    }
    
}

void on_stop_event_notification(void* ctx)
{
    NSLog(@"stop notification : here");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
       // void * cf = create_fixture_controller(1);
        NSLog(@"----------");
      /* NSLog(@"[set_dut_power] : %d",set_dut_power(cf,TURN_ON,1));
         setup_event_notification(cf,0,on_fixture_event,on_stop_event_notification);
        NSLog(@"----------");
         NSLog(@"[set_dut_power] : %d",set_dut_power(cf,TURN_ON,1));
       NSLog(@"[Vender ]: %s",get_vendor());
        NSLog(@"[Serial Number ]: %s",get_serial_number(cf));
        NSLog(@"[version] : %s",get_version(cf));
        NSLog(@"[get_error_message] : %s",get_error_message(0));
        NSLog(@"[init] : %d",init(cf));
        NSLog(@"[reset] : %d",reset(cf));
        NSLog(@"[get_site_count] : %d",get_site_count(cf));
        NSLog(@"[get_actuator_count] : %d",get_actuator_count(cf));
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,1));
        NSLog(@"[get_uart_path] : %s",get_uart_path(cf,1));
        NSLog(@"[actuator_for_site] : %d",actuator_for_site(cf,1));

        NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        
        NSLog(@"[fixture_engage] : %d",fixture_engage(cf,1));
        NSLog(@"[fixture_disengage] : %d",fixture_disengage(cf,1));
        NSLog(@"[fixture_open] : %d",fixture_open(cf,1));
        NSLog(@"[fixture_close] : %d",fixture_close(cf,1));

        NSLog(@"[set_usb_power] : %d",set_usb_power(cf,TURN_ON,1));
        NSLog(@"[set_battery_power] : %d",set_battery_power(cf,TURN_ON,1));
        NSLog(@"[set_usb_signal] : %d",set_usb_signal(cf,CLOSE_RELAY,1));
        NSLog(@"[set_uart_signal] : %d",set_uart_signal(cf,CLOSE_RELAY,1));
        NSLog(@"[set_apple_id] : %d",set_apple_id(cf,CLOSE_RELAY,1));
        NSLog(@"[set_conn_det_grounded] : %d",set_conn_det_grounded(cf,CLOSE_RELAY,1));
        NSLog(@"[set_hi5_bs_grounded] : %d",set_hi5_bs_grounded(cf,CLOSE_RELAY,1));

        NSLog(@"[set_dut_power] : %d",set_dut_power(cf,TURN_ON,1));
        NSLog(@"[set_dut_power_all] : %d",set_dut_power_all(cf,TURN_ON));

        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_ON,1));
        NSLog(@"[set_force_diags] : %d",set_force_diags(cf,TURN_ON,1));
        NSLog(@"[set_force_iboot] : %d",set_force_iboot(cf,TURN_ON,1));

        NSLog(@"[set_led_state] : %d",set_led_state(cf,PASS,1));
        NSLog(@"[set_led_state_all] : %d",set_led_state_all(cf,PASS));

       // NSLog(@"fixture_write_string : %d",fixture_write_string(cf,"kao"));

    
        NSLog(@"[release_fixture_controller]");
        */
      
    
       
       // void * cf = create_fixture_controller(0);
       // void * cf1 = create_fixture_controller(1);
        
       /* NSLog(@"[set_led_state] : %d",set_led_state(cf,PASS,1));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,PASS,2));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,PASS,3));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,PASS,4));
       
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,FAIL,1));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,FAIL,2));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,FAIL,3));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,FAIL,4));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,INPROGRESS,1));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,INPROGRESS,2));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,INPROGRESS,3));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf,INPROGRESS,4));

        
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,PASS,1));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,PASS,2));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,PASS,3));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,PASS,4));
        
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,FAIL,1));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,FAIL,2));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,FAIL,3));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,FAIL,4));
        
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,INPROGRESS,1));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,INPROGRESS,2));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,INPROGRESS,3));
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[set_led_state] : %d",set_led_state(cf1,INPROGRESS,4));
        NSLog(@"*************************************");
        NSLog(@"*************************************");
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,1));
        NSLog(@"=====slot 1===::::[get_uart_path] : %s",get_uart_path(cf,1));
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,2));
        NSLog(@"======slot 2==::::[get_uart_path] : %s",get_uart_path(cf,2));
        
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,3));
        NSLog(@"=====slot 3===::::[get_uart_path] : %s",get_uart_path(cf,3));
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,4));
        NSLog(@"======slot 4==::::[get_uart_path] : %s",get_uart_path(cf,4));
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,1));
        NSLog(@"======slot 5==::::[get_uart_path] : %s",get_uart_path(cf1,1));
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,2));
        NSLog(@"======slot 6==::::[get_uart_path] : %s",get_uart_path(cf1,2));
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,3));
        NSLog(@"======slot 7==::::[get_uart_path] : %s",get_uart_path(cf1,4));
        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,4));
        NSLog(@"======slot 8==::::[get_uart_path] : %s",get_uart_path(cf1,4));
        */
        
       /* NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_ON,1));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_ON,2));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_ON,3));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_ON,4));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_ON,1));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_ON,2));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_ON,3));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_ON,4));
        [NSThread sleepForTimeInterval:2];
       */
        
       /*
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_OFF,1));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_OFF,2));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_OFF,3));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf,TURN_OFF,4));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_OFF,1));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_OFF,2));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_OFF,3));
        [NSThread sleepForTimeInterval:2];
        NSLog(@"[set_force_dfu] : %d",set_force_dfu(cf1,TURN_OFF,4));
        [NSThread sleepForTimeInterval:2];*/
        
        
        //
        
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,1));
//        NSLog(@"=====slot 1===::::[get_uart_path] : %s",get_uart_path(cf,1));
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,2));
//        NSLog(@"======slot 2==::::[get_uart_path] : %s",get_uart_path(cf,2));
//        
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,3));
//        NSLog(@"=====slot 3===::::[get_uart_path] : %s",get_uart_path(cf,3));
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf,4));
//        NSLog(@"======slot 4==::::[get_uart_path] : %s",get_uart_path(cf,4));
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,5));
//        NSLog(@"======slot 5==::::[get_uart_path] : %s",get_uart_path(cf1,5));
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,6));
//        NSLog(@"======slot 6==::::[get_uart_path] : %s",get_uart_path(cf1,6));
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,7));
//        NSLog(@"======slot 7==::::[get_uart_path] : %s",get_uart_path(cf1,7));
//        NSLog(@"[get_usb_location] : %s",get_usb_location(cf1,8));
//        NSLog(@"======slot 8==::::[get_uart_path] : %s",get_uart_path(cf1,8));
        
       
        
        
        
       // release_fixture_controller(cf1);
        //release_fixture_controller(cf);
        
      //  NSLog(@"-:%@",[USBDevice getAllAttachedDevices]);
        
        
        
        
        
    }
    return 0;
}

