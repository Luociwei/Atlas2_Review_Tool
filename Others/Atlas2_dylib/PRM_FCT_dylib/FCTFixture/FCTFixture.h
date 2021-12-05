/*!
 *    Copyright 2016 Apple Inc. All rights reserved.
 *
 *    APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  FCTFixture.h
 *
 */

#ifndef FCTFixture_FCTFixture_h
#define FCTFixture_FCTFixture_h
#define FCT_API_VERSION 2
#define FCT_API_MINOR_VERSION 9

#ifdef __cplusplus
extern "C" {
#endif
    
    void* create_fixture_controller(int index);
    void release_fixture_controller(void* controller);
    
    int init(void* controller);
    int reset(void* controller, int site);

    const char * const get_vendor(void* controller);
    const char * const get_version(void* controller);
    const char * const get_serial_number(void* controller,int site);
    const char * const get_error_message(int status,int site);
    
    const char * relay_switch(void* controller, const char* net_name, const char * state, int site);
    float read_voltage(void* controller, const char* net_name,const char* mode,int site);  // eg: mode when measure current,need to know is 5V/9V/12/15 factor .
    
    float read_frequency(void* controller, const char* net_name,int ref_volt,int measure_time, const char*geer, int site);
    float read_frequency_duty(void* controller, const char* net_name,int ref_volt, int site);
    float read_frequency_vpp(void* controller, const char* net_name,int ref_volt, int site);
    
    const char *set_battery_voltage(void* controller,float volt_mv, const char * mode,int site); //eg: mode 1000-4000-200, start 1000mV, stop 4000mv, step 200mV
    const char *set_usb_voltage(void* controller,float volt_mv, const char * mode,int site);
    const char *set_eload_output(void* controller,float value_ma, const char * mode, int site);
    const char *set_pp5v0_output(void* controller,float volt_mv, const char * mode, int site);
    const char *eload_set(void* controller,int channel,const char * mode,float value, int site);
    int get_vendor_id(void* controller);
    int dut_detect(void* controller,int site);
    const char * const get_fw_version(void* controller,int site);
    float read_gpio_voltage(void* controller,const char* net_name,int site);
    float read_eload_current(void* controller,const char* net_name,int site);
    const char * vdm_set_source_capabilities(void* controller,int PDO_number, const char *source_switch, int voltage, int max_current, const char *peak_current, int site, int timeout);
    float read_eload_cv_current(void* controller,const char* net_name,float value,int site);  //orion set eload OC
    const char *set_dfu_mode(void* controller,int site);
    const char *get_fixture_log(void* controller,int site);

    const char *fixture_command(void* controller, const char* cmd, int timeout, int site);
    const char *rpc_write_read(void* controller, const char* rpccmd, int timeout, int site);  //
    const char *getAndWriteFile(void* controller,const char* target,const char* dest,int site,int timeout);


#ifdef __cplusplus
}
#endif
#endif

