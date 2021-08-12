local _CAL_ = {}
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local comFunc = require("Matchbox/CommonFunc")

CalibrationTable = {}


-- Unique Function ID : Suncode_000052_1.0
-- writeFile(filepath,str)
-- Function to write file, append new string in the end

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: two string
-- Output Arguments : NA

local function WriteFileByAppend(filepath,str)
    local ret = nil;
    local f = io.open(filepath, "a");
    if f == nil then return nil, "failed to open file"; end
    ret = f:write(tostring(str));
    f:close();
end



-- Unique Function ID : Suncode_000054_1.0
-- RawInstrumentCmd(cmd,device,slot_num)

-- Function to send command to  xavier 

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: three string
-- Output Arguments : a string

local function RawInstrumentCmd(cmd,device,slot_num)

    local fixture = device
    local timeout = 5000
    return fixture.rpc_write_read(cmd,timeout,slot_num)

end


function _CAL_.get_calibration_addr(device)
	local add_str = device.get_calibration_addr()
	local tb = comFunc.splitString(add_str,";")
	local factor_addr_tb = {}
	for _,v in pairs(tb) do
   		if string.find(v,"=") then
	   		local c = comFunc.splitString(v,"=")
	   		local key = comFunc.trim(c[1])
	   		local val = comFunc.trim(c[2])
	   		factor_addr_tb[key]= val
	   	end
	end
	return factor_addr_tb
end

-- Unique Function ID : Suncode_000055_1.0
-- _CAL_.eeprom_string_read(board_name,chip_type,addr_t_key,device,slot_num)

-- Function to send command tp xavier, then get calibration data from eeprom 

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: five string
-- Output Arguments : two number

function _CAL_.eeprom_string_read(board_name,chip_type,addr_t_key,device,slot_num)

    local k = nil
    local r = nil
    local factor_addr_tb = _CAL_.get_calibration_addr(device)
    local cmd = "eeprom.read("..board_name..","..chip_type..","..factor_addr_tb[addr_t_key]..",16)"
    local ret = RawInstrumentCmd(cmd,device,slot_num)
    k,r = string.match(ret,"ACK%(%s*\"([+-]?%d*%.?%d*);([+-]?%d*%.?%d*)\"%s*;DONE")
    if k == nil then k =1 end
    if r == nil then r =0 end
    if tonumber(k) <0.95 or tonumber(k) > 1.05 then k =1 end
    return tonumber(k),tonumber(r)

end

-- Unique Function ID : Suncode_000056_1.0
-- _CAL_.readStrFromTestbase(addr_t_key,device,slot_num)

-- Function to read calibration data from testbase's eeprom 

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: three string
-- Output Arguments : one string

function _CAL_.readStrFromTestbase(addr_t_key,device,slot_num)
    Log.LogInfo("read eeprom addr_t_key--->"..addr_t_key)
    return _CAL_.eeprom_string_read("testbase", "cat32",addr_t_key,device,slot_num)
end


-- Unique Function ID : Suncode_000057_1.0
-- _CAL_.write_factor_file(device,slot_num)

-- Function to get eeprom data , then write to local file

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: two string
-- Output Arguments : NA
function _CAL_.write_factor_file(device,slot_num)

    local path_txt_cal = "/Users/gdlocal/Config/Suncode_Fixture_cal_data_UUT"..tostring(slot_num)..".txt"
 
    Log.LogInfo("***********read cal from eeprom ***********")
    os.execute("rm "..path_txt_cal)
    local factor_addr_tb = _CAL_.get_calibration_addr(device)
    for k,v in pairs(factor_addr_tb) do
        local a,b = _CAL_.readStrFromTestbase(k,device,slot_num)
            if a or b or a ~= 0 then
        else
            a,b = 1.0,0.0
        end
        Log.LogInfo("------>slot"..tostring(slot_num)..":"..k.."-->k="..a..",".."r="..b)
        WriteFileByAppend(path_txt_cal,tostring(k)..": "..tostring(a)..";"..tostring(b)..";\n")
    end

end

function _CAL_.getCalibrationTable()
    local slot_num = tonumber(Device.identifier:sub(-1))-1
    local path_txt_cal = "/Users/gdlocal/Config/Suncode_Fixture_cal_data_UUT"..tostring(slot_num)..".txt"

    if #CalibrationTable <=0 then
        CalibrationTable = _CAL_.read_cal_data(path_txt_cal)

    end
    return CalibrationTable
end


function _CAL_.read_cal_data(path_txt_cal)
    
    local cal_ret = comFunc.fileRead(path_txt_cal)
    for v in string.gmatch(cal_ret,"(.-)\n") do
        local k,a,b = string.match(v,"(.-)%s*:%s*([+-]?%d*%.?%d*)%;([+-]?%d*%.?.-)%;")
        if tonumber(a) <0.95 or tonumber(a) >1.05 then a =1 end

        CalibrationTable[k.."_k"] = tonumber(a)
        CalibrationTable[k.."_r"] = tonumber(b)
    end

    return CalibrationTable

end

-- Unique Function ID : Suncode_000058_1.0
-- _CAL_.updated_factor_tb(param )

-- Function to read calibration data from file, and record 

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA


function _CAL_.updated_factor_tb(param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local slot_num = tonumber(Device.identifier:sub(-1))-1
    local path_txt_cal = "/Users/gdlocal/Config/Suncode_Fixture_cal_data_UUT"..tostring(slot_num)..".txt"

    CalibrationTable = _CAL_.read_cal_data(path_txt_cal)
    return CalibrationTable
end

--get calibration factor----

-- Unique Function ID : Suncode_000058_1.0
-- _CAL_.cal_neg_load_set_factor(dac_value,neg_sel)

-- Function to get the neg load factor and record 

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA

function _CAL_.cal_neg_load_set_factor(dac_value,neg_sel)

    local k,r =1,0
    CalibrationTable = _CAL_.getCalibrationTable()
    local section=""

    if string.find(string.lower(neg_sel),"ua") then

        local value = string.match(string.lower(neg_sel),"to%_(%d*)ua")
        if tonumber(value) < 300 then
            section = "10_100_ua"

            k = CalibrationTable["neg_current_setting_10_100_ua_k"]
            r = CalibrationTable["neg_current_setting_10_100_ua_r"]

        elseif tonumber(value) > 300 and tonumber(value) < 600 then
            section = "500_2000_ua"

            k = CalibrationTable["neg_current_setting_500_2000_ua_k"]
            r = CalibrationTable["neg_current_setting_500_2000_ua_r"]

        end

    elseif string.find(string.lower(neg_sel),"ma") then

        local value = string.match(string.lower(neg_sel),"to%_(%d*)ma")
        if tonumber(value) < 3 then
            section = "500_2000_ua"
            --k = vt.getVar("neg_current_setting_500_2000_ua_k")
            --r = vt.getVar("neg_current_setting_500_2000_ua_r")

            k = CalibrationTable["neg_current_setting_500_2000_ua_k"]
            r = CalibrationTable["neg_current_setting_500_2000_ua_r"]

        elseif tonumber(value) >= 3 then
            section = "3000_20000_ua"
            --k = vt.getVar("neg_current_setting_3000_20000_ua_k")
            --r = vt.getVar("neg_current_setting_3000_20000_ua_r")

            k = CalibrationTable["neg_current_setting_3000_20000_ua_k"]
            r = CalibrationTable["neg_current_setting_3000_20000_ua_r"]

        end
    end

    vt.setVar("section",section)

    Log.LogInfo(section.." neg_load_set_factor_k;neg_load_set_factor_r;neg_load_set value without factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(dac_value))
    dac_value = tonumber(dac_value)*tonumber(k)+tonumber(r)
    Log.LogInfo("neg_load_set value with factor--->"..tostring(dac_value))
    return dac_value

end

-- Unique Function ID : Suncode_000059_1.0
--  _CAL_.cal_neg_load_read_factor(value)

-- Function to get the neg load read factor and record

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA

function _CAL_.cal_neg_load_read_factor(value)
    if value == nil then return 0 end

    local k,r =1,0
    local section =""
    CalibrationTable = _CAL_.getCalibrationTable()

    if tonumber(value) < 300 then

        k = CalibrationTable["neg_current_reading_10_100_ua_k"]
        r = CalibrationTable["neg_current_reading_10_100_ua_r"]


        section = "10_100_ua"

    elseif tonumber(value) > 300 and tonumber(value) < 2500 then
        section = "500_2000_ua"

        k = CalibrationTable["neg_current_reading_500_2000_ua_k"]
        r = CalibrationTable["neg_current_reading_500_2000_ua_r"]


    elseif tonumber(value) >= 2500 then
        section = "3000_20000_ua"

        k = CalibrationTable["neg_current_reading_3000_20000_ua_k"]
        r = CalibrationTable["neg_current_reading_3000_20000_ua_r"]

    end

    CalibrationTable["section"] = section
    Log.LogInfo(section.." neg_load_reading_factor_k;neg_load_reading_factor_r;neg_load_read value without factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(value))
    value = tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo("neg_load_read value with factor--->"..tostring(value))
    return value

end


-- Unique Function ID : Suncode_000060_1.0
--  _CAL_.cal_ai1_8_factor(channel,net,value)

-- Function to get ai1 to ai8 factor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: 2 string, a number
-- Output Arguments : a number

function _CAL_.cal_ai1_8_factor(channel,net,value)
    if value == nil then return 0 end

    CalibrationTable = _CAL_.getCalibrationTable()

    local k,r =1,0
  
    if channel =="AI8" then
        if CalibrationTable["ai8_voltage_reading_3000_17000_mV_k"] and CalibrationTable["ai8_voltage_reading_3000_17000_mV_r"] then
            k = CalibrationTable["ai8_voltage_reading_3000_17000_mV_k"]
            r = CalibrationTable["ai8_voltage_reading_3000_17000_mV_r"]
        end

    else
        if tonumber(value) < 200 then
            k = CalibrationTable[string.lower(channel).."_voltage_reading_5_200_mV_k"]
            r = CalibrationTable[string.lower(channel).."_voltage_reading_5_200_mV_r"]
        else
            k = CalibrationTable[string.lower(channel).."_voltage_reading_200_4500_mV_k"]
            r = CalibrationTable[string.lower(channel).."_voltage_reading_200_4500_mV_k"]
        end
    
    end

    local val = tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo(channel..": adc reading value with factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(val))
    return val
end

-- Unique Function ID : Suncode_000060_1.0
--  _CAL_.cal_target_current_factor(value,level)

-- Function to get current facor for AI1 to AI8

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a string, a number
-- Output Arguments : a number

function _CAL_.cal_target_current_factor(value,level)
    if value == nil then return 0 end

    local volt = string.match(level,"(%d+V)")

    if volt == nil then
        return value
    end


    CalibrationTable = _CAL_.getCalibrationTable()

    local k,r =1,0
    local section =""
    if value < 10 then
        section = "1_10_ma"
        k = CalibrationTable["target_"..tostring(volt).."_current_1_10_ma_k"]
        r = CalibrationTable["target_"..tostring(volt).."_current_1_10_ma_r"]

    elseif value >=10 and value <160 then
        section = "10_160_ma"
        k = CalibrationTable["target_"..tostring(volt).."_current_10_160_ma_k"]
        r = CalibrationTable["target_"..tostring(volt).."_current_10_160_ma_r"]

    elseif value >=160 and value <=700 then
        section = "160_700_ma"
        k = CalibrationTable["target_"..tostring(volt).."_current_160_700_ma_k"]
        r = CalibrationTable["target_"..tostring(volt).."_current_160_700_ma_r"]

    elseif value >700 and value <=1600 then
        if volt =="15V" then
            section = "700_1400_ma"
            k = CalibrationTable["target_"..tostring(volt).."_current_700_1400_ma_k"]
            r = CalibrationTable["target_"..tostring(volt).."_current_700_1400_ma_r"]

        else
            section = "700_1800_ma"
            k = CalibrationTable["target_"..tostring(volt).."_current_700_1800_ma_k"]
            r = CalibrationTable["target_"..tostring(volt).."_current_700_1800_ma_r"]

        end

    elseif value >1600 then

        if volt == "15V" then
            section = "1000_1400_ma"
            k = CalibrationTable["target_"..tostring(volt).."_current_1000_1400_ma_k"]
            r = CalibrationTable["target_"..tostring(volt).."_current_1000_1400_ma_r"]

        elseif volt == "12V" then
            section = "1000_2000_ma"
            k = CalibrationTable["target_"..tostring(volt).."_current_1000_2000_ma_k"]
            r = CalibrationTable["target_"..tostring(volt).."_current_1000_2000_ma_r"]

        elseif volt == "9V" then
            section = "1000_2500_ma"
            k = CalibrationTable["target_"..tostring(volt).."_current_1000_2500_ma_k"]
            r = CalibrationTable["target_"..tostring(volt).."_current_1000_2500_ma_r"]

        elseif volt == "5V" then
            section = "1000_2500_ma"
            k = CalibrationTable["target_"..tostring(volt).."_current_1000_2500_ma_k"]
            r = CalibrationTable["target_"..tostring(volt).."_current_1000_2500_ma_r"]

        end
    end

    Log.LogInfo("target current value without factor--->"..tostring(value))
    value = tonumber(value)*tonumber(k)+tonumber(r) 
    Log.LogInfo(section.." target_k;target_r;target current value with factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(value))
    return value

end

-- Unique Function ID : Suncode_000061_1.0
--  _CAL_.cal_ibatt_factor(value)

-- Function to get batt current facor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments:  a number
-- Output Arguments : a number

function _CAL_.cal_ibatt_factor(value)
    if value == nil then return 0 end

    local k,r =1,0
    local section =""

    CalibrationTable = _CAL_.getCalibrationTable()

    if value > 0 and value <= 10 then
        section = "1_10_ma"
        k = CalibrationTable["ibatt_1_10_ma_k"]
        r = CalibrationTable["ibatt_1_10_ma_r"]

    elseif value >10 and value <=500 then
        section = "10_500_ma"
        k = CalibrationTable["ibatt_10_500_ma_k"]
        r = CalibrationTable["ibatt_10_500_ma_r"]

    elseif value >500 and value <= 1000 then
        section = "500_1000_ma"
        k = CalibrationTable["ibatt_500_1000_ma_k"]
        r = CalibrationTable["ibatt_500_1000_ma_r"]

    elseif value >1000 and value <= 1500 then
        section = "1000_1500_ma"
        k = CalibrationTable["ibatt_1000_1500_ma_k"]
        r = CalibrationTable["ibatt_1000_1500_ma_r"]

    elseif value >1500 then
        section = "1500_2500_ma"
        k = CalibrationTable["ibatt_1500_2500_ma_k"]
        r = CalibrationTable["ibatt_1500_2500_ma_r"]
    end

    Log.LogInfo(section.." ibatt_k;ibatt_r;ibatt value without factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(value))
    value = tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo("ibatt value with factor--->"..tostring(value))
    return value

end

-- Unique Function ID : Suncode_000062_1.0
--  _CAL_.cal_ibus_factor(value)

-- Function to get vbus current factor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments:  a number
-- Output Arguments : a number

function _CAL_.cal_ibus_factor(value)
    if value == nil then return 0 end

    local k,r = 1,0
    local section = ""

    CalibrationTable = _CAL_.getCalibrationTable()

    if value > 0 and value <= 10 then
        section = "1_10_ma"
        k = CalibrationTable["ibus_1_10_ma_k"]
        r = CalibrationTable["ibus_1_10_ma_r"]

    elseif value >10 and value <=700 then
        section = "10_700_ma"
        k = CalibrationTable["ibus_10_700_ma_k"]
        r = CalibrationTable["ibus_10_700_ma_r"]

    elseif value >700 and value <= 1300 then
        section = "700_1300_ma"
        k = CalibrationTable["ibus_700_1300_ma_k"]
        r = CalibrationTable["ibus_700_1300_ma_r"]

    elseif value >1300 and value <= 1950 then
        section = "1300_1950_ma"
        k = CalibrationTable["ibus_1300_1950_ma_k"]
        r = CalibrationTable["ibus_1300_1950_ma_r"]

    elseif value >1950 then
        section = "1950_2500_ma"
        k = CalibrationTable["ibus_1950_2500_ma_k"]
        r = CalibrationTable["ibus_1950_2500_ma_r"]
    end

    Log.LogInfo(section.." ibus_k;ibus_r;ibus value without factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(value))
    value = tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo("ibus value with factor--->"..tostring(value))
    return value

end

-- Unique Function ID : Suncode_000063_1.0
--  _CAL_.vbatt_set_with_cal_factor(value)

-- Function to get the batt setting factor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments:  a number
-- Output Arguments : a number

function _CAL_.vbatt_set_with_cal_factor(value)
    if value == nil then return 0 end
    local k,r =1,0

    CalibrationTable = _CAL_.getCalibrationTable()
    if value <200 then
        k = CalibrationTable["batt_voltage_setting_5_200_mV_k"]
        r = CalibrationTable["batt_voltage_setting_5_200_mV_r"]
    else
        k = CalibrationTable["batt_voltage_setting_200_4500_mV_k"]
        r = CalibrationTable["batt_voltage_setting_200_4500_mV_r"]
    end

    Log.LogInfo("VBATT set factor: "..tostring(k)..";"..tostring(r)..";"..tostring(value))
    value =tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo("VBATT set value with cal factor: "..tostring(value))
    return value

end

-- Unique Function ID : Suncode_000064_1.0
--  _CAL_.usb_set_with_cal_factor(value)

-- Function to get the  vbus setting factor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments:  a number
-- Output Arguments : a number

function _CAL_.usb_set_with_cal_factor(value)
    if value == nil then return 0 end

    CalibrationTable = _CAL_.getCalibrationTable()

    local k = CalibrationTable["vbus_voltage_setting_k"]
    local r = CalibrationTable["vbus_voltage_setting_r"]
    --Log.LogInfo("VBUS set value without factor: "..tostring(value))
    Log.LogInfo("VBUS set factor: "..tostring(k)..";"..tostring(r)..";"..tostring(value))

    value =tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo("VBUS set value with cal factor: "..tostring(value))
    return value
end

-- Unique Function ID : Suncode_000065_1.0
-- _CAL_.cal_eload_set_factor(channel,value)

-- Function to get the  eload setting factor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments:  a number,astring
-- Output Arguments : a number

function _CAL_.cal_eload_set_factor(channel,value)
    if value == nil then return 0 end
    local k,r =1,0

    CalibrationTable = _CAL_.getCalibrationTable()

    local section =""
    if value == 0 then
        k = 1
        r = 0
    elseif value <= 10 then
        section ="1_10_ma"
        k = CalibrationTable["eload"..tostring(channel).."_setting_1_10_ma_k"]
        r = CalibrationTable["eload"..tostring(channel).."_setting_1_10_ma_r"]

    elseif value >10 and value <=700 then
        section ="10_700_ma"
        k = CalibrationTable["eload"..tostring(channel).."_setting_10_700_ma_k"]
        r = CalibrationTable["eload"..tostring(channel).."_setting_10_700_ma_r"]

    elseif value >700 and value <= 1300 then
        section ="700_1300_ma"
        k = CalibrationTable["eload"..tostring(channel).."_setting_700_1300_ma_k"]
        r = CalibrationTable["eload"..tostring(channel).."_setting_700_1300_ma_r"]

    elseif value >1300 and value <= 1950 then
        section ="1300_1950_ma"
        k = CalibrationTable["eload"..tostring(channel).."_setting_1300_1950_ma_k"]
        r = CalibrationTable["eload"..tostring(channel).."_setting_1300_1950_ma_r"]

    elseif value > 1950 then
        section ="1950_2500_ma"
        k = CalibrationTable["eload"..tostring(channel).."_setting_1950_2500_ma_k"]
        r = CalibrationTable["eload"..tostring(channel).."_setting_1950_2500_ma_r"]
    end

    Log.LogInfo(section.." iload_k;iload_r;iload setting value without factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(value))
    value = tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo("iload setting value with factor--->"..tostring(value))
    return value

end

-- Unique Function ID : Suncode_000066_1.0
-- _CAL_.cal_eload_read_factor(channel,value)

-- Function to get the  eload read factor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments:  a number,astring
-- Output Arguments : a number

function _CAL_.cal_eload_read_factor(channel,value)

    if value == nil then return 0 end
    local k,r =1,0
    local section = ""
    local chn = channel

    CalibrationTable = _CAL_.getCalibrationTable()

    if value <= 10 then
        section ="1_10_ma"
        k = CalibrationTable["eload"..tostring(chn).."_reading_1_10_ma_k"]
        r = CalibrationTable["eload"..tostring(chn).."_reading_1_10_ma_r"]

    elseif value >10 and value <=700 then
        section ="10_700_ma"
        k = CalibrationTable["eload"..tostring(chn).."_reading_10_700_ma_k"]
        r = CalibrationTable["eload"..tostring(chn).."_reading_10_700_ma_r"]

    elseif value >700 and value <= 1300 then
        section ="700_1300_ma"
        k = CalibrationTable["eload"..tostring(chn).."_reading_700_1300_ma_k"]
        r = CalibrationTable["eload"..tostring(chn).."_reading_700_1300_ma_r"]

    elseif value >1300 and value <= 1950 then
        section ="1300_1950_ma"
        k = CalibrationTable["eload"..tostring(chn).."_reading_1300_1950_ma_k"]
        r = CalibrationTable["eload"..tostring(chn).."_reading_1300_1950_ma_r"] 

    elseif value >1950 then
        section ="1950_2500_ma"
        k = CalibrationTable["eload"..tostring(chn).."_reading_1950_2500_ma_k"]
        r = CalibrationTable["eload"..tostring(chn).."_reading_1950_2500_ma_r"]
    end

    Log.LogInfo("iload_k;iload_r;iload reading value without factor--->"..tostring(k)..";"..tostring(r)..";"..tostring(value))
    value = tonumber(value)*tonumber(k)+tonumber(r)
    Log.LogInfo("iload reading value with factor--->"..tostring(value))
    return value

end


-- Unique Function ID : Suncode_000067_1.0
-- _CAL_.cal_ADC_zero_read_factor(channel,value)

-- Function to get ADC zero voltage read factor

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version . directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments:  a number,astring
-- Output Arguments : a number

function _CAL_.cal_ADC_zero_read_factor(channel,value)
    if value == nil then return 0 end
    local k,r =1,0
   
    CalibrationTable = _CAL_.getCalibrationTable()

    r = CalibrationTable["ADC_"..channel.."_Zero_reading_r"]
    Log.LogInfo("ai "..channel.." adc zero reading value without factor--->"..tostring(value).." "..tostring(r))
    value = tonumber(value) - tonumber(r)
    Log.LogInfo("ai "..channel.." adc zero reading value with factor--->"..tostring(value))
    return value

end



return _CAL_


