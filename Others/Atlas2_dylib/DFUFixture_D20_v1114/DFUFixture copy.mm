//
//  DFUFixture.m
//  DFUFixture
//
///

/*
 //NSLog(@"%@",[NSString stringWithUTF8String:get_usb_location(0,1)]);
 NSString *str=@"delay:3";
 NSArray *arry=[str componentsSeparatedByString:@":"];
 if ([[arry[0] uppercaseString] isEqual:@"DELAY"]) {
 NSLog(@"--delay   %f",[arry[1] doubleValue]);
 }
 NSLog(@"====1======");
 [NSThread sleepForTimeInterval:[arry[1] doubleValue]];
 NSLog(@"====2======\r\n%@",arry);
 
 
 */

#import "DFUFixture.h"
#import <Foundation/Foundation.h>
#import "plistParse.h"
#import "CRS232.h"
#import "ErrorCode.h"
#import "USBDevice.h"



int g_SLOTS = 0;
extern ErrorCode * g_errcode;

NSMutableDictionary * cmd = [[NSMutableDictionary alloc]init];


CRS232 * rs232_1 = new CRS232();
CRS232 * rs232_2 = new CRS232();
CRS232 * rs232_3 = new CRS232();
CRS232 * rs232_4 = new CRS232();
CRS232 * rs232_5 = new CRS232();
CRS232 * rs232_6 = new CRS232();
CRS232 * rs232_7 = new CRS232();
CRS232 * rs232_8 = new CRS232();

CRS232 * rs232Arr[] = {rs232_1,rs232_2,rs232_3,rs232_4,rs232_5,rs232_6,rs232_7,rs232_8};





void* create_fixture_controller(int index)
{
    
    if(cmd)
        [cmd removeAllObjects];
//    cmd setObject:(nonnull id) forKey:(nonnull id<NSCopying>)
   // [cmd setDictionary:[plistParse parsePlist:@"/usr/local/lib/DFUFixtureCmd.plist"]];
    //[cmd setDictionary:dic];
    [cmd setDictionary:[plistParse readAllCMD]];
    if([cmd count]>0)
        g_SLOTS = [[cmd objectForKey:kFIXTURESLOTS]intValue];
    for (int i=0; i<g_SLOTS; i++) {
        rs232Arr[i]->Close();
    }

    NSDictionary * dic = [cmd objectForKey:kFIXTUREPORT];
    for(int i=0; i<g_SLOTS; i++)
    {
        if(dic)
        {
            rs232Arr[i]->Open([[dic objectForKey:[NSString stringWithFormat:@"UUT%d",i]]UTF8String], [[cmd objectForKey:kFIXTURESETTING]UTF8String]);
            rs232Arr[i]->SetDetectString("\r\n");
        }
    }
    return (__bridge void*)rs232Arr;
}

void release_fixture_controller(void* controller)
{
    if(cmd)
        [cmd removeAllObjects];
    for (int i=0; i<g_SLOTS; i++) {
        rs232Arr[i]->Close();
    }
}


/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
int executeAction(NSString * key, int site)
{
    if(site<1)
        return -1;

    id list = [cmd objectForKey:key];
    CRS232 * r = rs232Arr[site-1];
    NSArray * arr = (__bridge NSArray*)list;
    for (int j=0; j<[arr count]; j++) {
        r->WriteReadString([[arr objectAtIndex:j]UTF8String], 1000);
    }
    return 0;
}

/////////////////////////////////////////////////////
int executeAllAction(NSString * key)
{
    for(int i=0; i<g_SLOTS; i++)
    {
        executeAction(key, i+1);
    }
    return 0;
}
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////


const char * const get_vendor()
{
    id obj = [cmd objectForKey:kVENDER];
    if(obj)
        return [obj UTF8String];
    else
        return "IA";
}


const char * const get_serial_number(void* controller)
{
    id obj = [cmd objectForKey:kSERIAL];
    if(obj)
        return [obj UTF8String];
    else
        return "TBD";
}

const char* const get_error_message(int status)
{
    if(g_errcode)
        return [g_errcode getErrorMsg:status];
    else
        return "Invalide ErroCode center";
}

const char* const get_version(void* controller)
{
    id obj = [cmd objectForKey:kVERSION];
    if(obj)
        return [obj UTF8String];
    else
        return "0.1";
}

int init(void* controller)
{
    return executeAllAction(kINIT);
}

int reset(void* controller)
{
    return executeAllAction(kRESET);
}

int get_site_count(void* controller)
{
    return g_SLOTS;
}

int get_actuator_count(void* controller)
{
    return g_SLOTS;
}

const char* get_usb_location(void* controller, int site)
{
    if(site<1)
        return "site should be from 1";
    NSMutableArray *uartSerialLocation=[NSMutableArray array];
    NSArray *array=[USBDevice getAllAttachedDevices];
    for (id myindex in [array valueForKey:@"DeviceFriendlyName"]) {
        if ([myindex[0] isEqualToString:@"Bluetooth USB Host Controller"]||[myindex[0] isEqualToString:@"USB Serial Converter"]) {
            int j=[myindex[1] intValue];
           // if ([[array[j] valueForKey:@"ProductID"] isEqualToString:@"0x6001"]) {
                NSString *str1=[[array[j] valueForKey:@"LocationID"][0] substringWithRange:NSMakeRange(0,6)];
                NSString *str2=[array[j] valueForKey:@"DeviceVersion"];
                [uartSerialLocation addObject:[NSString stringWithFormat:@"%@,%@",str2,str1]];
            //}
        }
    }
    
    NSSet *set = [NSSet setWithArray:uartSerialLocation];
    [uartSerialLocation addObject:[set allObjects]];
    NSArray *USBLocationArray =[set allObjects];
   
    NSString *usbLocation_fixture1=@"";
    NSString *usbLocation_fixture2=@"";
    for (int i=0; i<[USBLocationArray count]; i++) {
        if (USBLocationArray[i]) {
            if ([USBLocationArray[i] containsString:@"119"]) {
                NSArray *arr =[USBLocationArray[i] componentsSeparatedByString:@","];
                if (arr[1]) {
                    //return [[NSString stringWithFormat:@"%@%d000",arr[1],site] UTF8String];
                    usbLocation_fixture1=[NSString stringWithFormat:@"%@",arr[1]];
                }
            }
            if ([USBLocationArray[i] containsString:@"600"]) {
                NSArray *arr =[USBLocationArray[i] componentsSeparatedByString:@","];
                if (arr[1]) {
                    //return [[NSString stringWithFormat:@"%@%d000",arr[1],site] UTF8String];
                    usbLocation_fixture2=[NSString stringWithFormat:@"%@",arr[1]];
                }
            }
        }
        else{
            NSLog(@"-not get usb location-");
        }
    }
    
     NSLog(@"=usbLocation_fixture1:%@=",usbLocation_fixture1);
     NSLog(@"=usbLocation_fixture2:%@=",usbLocation_fixture2);
     return [@"" UTF8String];
    /*id usb = [cmd objectForKey:kUSBLOCATION];
    if(usb)
    {
        id str = [(NSDictionary*)usb objectForKey:[NSString stringWithFormat:@"UUT%d",site-1] ];
        if(str)
            return [str UTF8String];
        return nil;
    }
    return nil;*/
}

const char* get_uart_path(void* controller, int site)
{
    if(site<1)
        return "site should be from 1";
    NSMutableArray* uartSerialArray =[NSMutableArray array];
    NSMutableArray* uartSerialArray_sub1 = [NSMutableArray array];;
    NSMutableArray* uartSerialArray_sub2 = [NSMutableArray array];;
    NSMutableArray* uartSerialLocation = [NSMutableArray array];
    NSArray *array=[USBDevice getAllAttachedDevices];
    for (id myindex in [array valueForKey:@"DeviceFriendlyName"]) {
        if ([myindex[0] containsString:@"Serial Converter"]) {
            
            int j=[myindex[1] intValue];
            [uartSerialArray addObject:array[j]];
            NSString *str=[[array[j] valueForKey:@"LocationID"][0] substringWithRange:NSMakeRange(0,6)];
            [uartSerialLocation addObject:str];
        }
    }
    //remove duplicate
    NSSet *set = [NSSet setWithArray:uartSerialLocation];
    [uartSerialLocation addObject:[set allObjects]];
    NSArray *uartSerialLocationArray =[set allObjects];
    
    for (id usbSerialArray_sub in uartSerialArray) {
        NSString *str=[usbSerialArray_sub valueForKey:@"LocationID"][0];
        if ([str containsString:uartSerialLocationArray[0]]) {
            [uartSerialArray_sub1 addObject:[usbSerialArray_sub valueForKey:@"SerialNumber"]];
        }
    }
    for (id usbSerialArray_sub in uartSerialArray) {
        NSString *str=[usbSerialArray_sub valueForKey:@"LocationID"][0];
        if ([str containsString:uartSerialLocationArray[1]]) {
            [uartSerialArray_sub2 addObject:[usbSerialArray_sub valueForKey:@"SerialNumber"]];
        }
    }
    //sort K->A
    [uartSerialArray_sub1 sortUsingComparator:^NSComparisonResult(__strong id obj1,__strong id obj2){
        NSString *str1=(NSString *)obj1;
        NSString *str2=(NSString *)obj2;
        return [str2 compare:str1];
    }];
    
    [uartSerialArray_sub2 sortUsingComparator:^NSComparisonResult(__strong id obj1,__strong id obj2){
        NSString *str1=(NSString *)obj1;
        NSString *str2=(NSString *)obj2;
        return [str2 compare:str1];
    }];
    
    NSString *uartPath=@"";
    NSString *pp=@"";
      switch (site)
            {
                case 1:
                    pp =@"A";break;
                case 2:
                    pp =@"B";break;
                case 3:
                    pp =@"C";break;
                case 4:
                    pp =@"D";break;
                case 5:
                    pp =@"A";break;
                case 6:
                    pp =@"B";break;
                case 7:
                    pp =@"C";break;
                case 8:
                    pp =@"D";break;
                default:
                    break;
                    
            }
    
    if ([uartSerialArray_sub1[0] containsString:@"MCUA"]) {
        if ([@"1234" containsString:[NSString stringWithFormat:@"%d", site]])
        {
        uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub1[1],pp];
        NSLog(@"---slot:1,2,3,4-:%@",uartPath);
        }
        
    }
    
    if ([uartSerialArray_sub1[0] containsString:@"MCUB"]) {
        if ([@"5678" containsString:[NSString stringWithFormat:@"%d", site]])
        {
        uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub1[1],pp];
        NSLog(@"---slot:5,6,7,8-:%@",uartPath);
        }
    }
    
    if ([uartSerialArray_sub2[0] containsString:@"MCUA"]) {
        if ([@"1234" containsString:[NSString stringWithFormat:@"%d", site]])
        {
        uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub2[1],pp];
        NSLog(@"-slot:1,2,3,4-:%@",uartPath);
        }
    }
    if ([uartSerialArray_sub2[0] containsString:@"MCUB"]) {
        if ([@"5678" containsString:[NSString stringWithFormat:@"%d", site]])
        {
        uartPath=[NSString stringWithFormat:@"/dev/cu.usbserial-%@%@",uartSerialArray_sub2[1],pp];
        NSLog(@"-slot:5,6,7,8-:%@",uartPath);
        }
    }
    
   return [uartPath UTF8String];
    
//    id usb = [cmd objectForKey:kUARTPATH];
//    if(usb)
//    {
//        id str = [(NSDictionary*)usb objectForKey:[NSString stringWithFormat:@"UUT%d",site-1] ];
//        if(str)
//            return [str UTF8String];
//        return nil;
//    }
//    return nil;
}

int actuator_for_site(void* controller, int site)
{
    if(site<1)
        return -1;
    return site-1;
}

int fixture_engage(void* controller, int actuator_index)
{
    if(actuator_index<0)
        return -1;
    return 0;
}

int fixture_disengage(void* controller, int actuator_index)
{
    if(actuator_index<0)
        return -1;
    return 0;
}

int fixture_open(void* controller, int actuator_index)
{
    if(actuator_index<0)
        return -1;
    return 0;
}

int fixture_close(void* controller, int actuator_index)
{
    if(actuator_index<0)
        return -1;
    return 0;
}


int set_usb_power(void* controller, POWER_STATE action, int site)
{
    return executeAction((action==0 ? kUSBPOWERON : kUSBPOWEROFF),site);
}

int set_battery_power(void* controller, POWER_STATE action, int site)
{
    return executeAction((action==0 ? kBATTERYPOWERON : kBATTERYPOWEROFF),site);
}

int set_usb_signal(void* controller, RELAY_STATE action, int site)
{
    return executeAction((action==0 ? kUSBSIGNALON : kUSBSIGNALOFF),site);
}

int set_uart_signal(void* controller, RELAY_STATE action, int site)
{
    return executeAction((action==0 ? kUARTSIGNALON : kUARTSIGNALOFF),site);
}

int set_apple_id(void* controller, RELAY_STATE action, int site)
{
    return executeAction((action==0 ? kAPPLEIDON : kAPPLEIDOFF),site);
}

int set_conn_det_grounded(void* controller, RELAY_STATE action, int site)
{
    return executeAction((action==0 ? kCONNDETGNDON : kCONNDETGNDOFF),site);
}

int set_hi5_bs_grounded(void* controller, RELAY_STATE action, int site)
{
    return executeAction((action==0 ? kHI5ON : kHI5OFF),site);
}

int set_dut_power(void* controller, POWER_STATE action, int site)
{
    return executeAction((action==0 ? kDUTPOWERON : kDUTPOWEROFF),site);
}

int set_dut_power_all(void* controller, POWER_STATE action)
{
    return executeAllAction(action==0 ? kDUTPOWERON : kDUTPOWEROFF);
}

int set_force_dfu(void* controller, POWER_STATE action, int site)
{
    return executeAction((action==0 ? kFORCEDFUON : kFORCEDFUOFF), site);
}

int set_force_diags(void* controller, POWER_STATE action, int site)
{
    return executeAction((action==0 ? kFORCEDIAGSON : kFORCEDIAGSOFF), site);
}

int set_force_iboot(void* controller, POWER_STATE action, int site)
{
    return executeAction((action==0 ? kFORCEIBOOTON : kFORCEIBOOTOFF), site);
}

int set_led_state(void* controller, LED_STATE action, int site)
{
    if (site<1)
        return -1;

    NSString * key = kOFF;
    switch (action) {
        case PASS:
            key = kPASS;
            break;
        case FAIL:
            key = kFAIL;
            break;
        case INPROGRESS:
            key = kINPROCESS;
            break;
        case FAIL_GOTO_FA:
            key = kFAILGOTOFA;
            break;
        case PANIC:
            key = kPANIC;
            break;
        default:
            break;
    }
    id list = [cmd objectForKey:kLEDSTATE];
    if(list)
    {
        id cmdArr = [(NSDictionary*)list objectForKey:key];
        if(cmdArr)
        {
            NSArray * arr = (NSArray*)cmdArr;
            CRS232 * r = rs232Arr[site-1];
            for (int j=0; j<[arr count]; j++)
                r->WriteReadString([[arr objectAtIndex:j]UTF8String], 1000);
        }
    }
    return 0;
}
int set_led_state_all(void* controller, LED_STATE action)
{
    for (int i=0; i<g_SLOTS; i++) {
        set_led_state(controller, action, i+1);
    }
    return 0;
}

//************* section:status functions *******************
//when the actuator is in motion and not yet settled, neither is_engage nor is_disengage should return true
bool is_fixture_engaged(void* controller, int actuator_index)
{
    return YES;
}

bool is_fixture_disengaged(void* controller, int actuator_index)
{
    return YES;
}

bool is_fixture_closed(void* controller, int actuator_index)
{
    return YES;
}

bool is_fixture_open(void* controller, int actuator_index)
{
    return YES;
}

POWER_STATE usb_power(void* controller, int site)
{
    return TURN_ON;
}
POWER_STATE battery_power(void* controller, int site)
{
    return TURN_ON;
}

POWER_STATE force_dfu(void* controller, int site)
{
    return TURN_ON;
}

RELAY_STATE usb_signal(void* controller, int site)
{
    return CLOSE_RELAY;
}

RELAY_STATE uart_signal(void* controller, int site)
{
    return CLOSE_RELAY;
}

RELAY_STATE apple_id(void* controller, int site)
{
    return CLOSE_RELAY;
}

RELAY_STATE conn_det_grounded(void* controller, int site)
{
    return CLOSE_RELAY;
}

RELAY_STATE hi5_bs_grounded(void* controller, int site)
{
    return CLOSE_RELAY;
}

POWER_STATE dut_power(void* controller, int site)
{
    return TURN_ON;
}

bool is_board_detected(void* controller, int site)
{
    CRS232 * r = rs232Arr[site-1];
    const char *u=r->WriteReadString("READ INPUT:A", 1000);
    NSString *str=[NSString stringWithCString:u encoding:NSUTF8StringEncoding];
    if ([str containsString:@"Read Input A:0"]) {
        return YES;
    }
    
    return NO;
    
}


void setup_event_notification(void* controller, void* event_ctx, fixture_event_callback_t on_fixture_event, stop_event_notfication_callback_t on_stop_event_notification)
{
    
    
    if (controller == NULL || event_ctx == NULL ||
        on_fixture_event == NULL || on_stop_event_notification == NULL)
    {
        NSLog(@"setup_event_notification error: parameter error!");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        do{
            for (int i=0; i<g_SLOTS; i++) {
                
               NSDictionary *chInfo = @{@"FixtureID":[NSString stringWithFormat:@"%d", 1],
                                         @"chNum":[NSString stringWithFormat:@"%d", i+1],
                                         @"EventMsg":[NSString stringWithFormat:@"%s",event_ctx]};
                NSString *eventMsg = (NSString *)[chInfo objectForKey:@"EventMsg"];
                //int fid = [(NSString *)[chInfo objectForKey:@"FixtureID"] intValue];

                rs232Arr[i]->Set_Event_Callback(on_fixture_event,event_ctx,i+1);
                rs232Arr[i]->Set_Stop_Callback(on_stop_event_notification, event_ctx);
                [NSThread sleepForTimeInterval:0.5];

                if([rs232Arr[i]->start_flag containsString:@"1"])
                {
                    rs232Arr[i]->start_flag=@"0";
                    [[NSNotificationCenter defaultCenter] postNotificationName:eventMsg object:chInfo];
                    rs232Arr[i]->m_event_CallBack("TBD",0,rs232Arr[i]->m_event_context,i+1,0);
                    NSLog(@"----do callback--");
                    break;
                }
                
                
            }
        }while(1);
    });
   

}

