local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local cal_factor = require("Tech/Calibration")
local relay = require("Tech/Relay")
local powersupply = require("Tech/PowerSupply")

local vpp = -99999
local duty_cycle = -9999
local freq = -9999
local thd = -9999


local function channel_number(ch)
    local temp = ""
    if ch == "AI1" then
        temp = "A"
    elseif ch == "AI2" then
        temp = "B"
    elseif ch == "AI3" then
        temp = "C"
    elseif ch == "AI4" then
        temp = "D"
    elseif ch == "AI5" then
        temp = "E"
    elseif ch == "AI6" then
        temp = "F" 
    elseif ch == "AI7" then
        temp = "G"
    else
        temp = "H"
    end
    return temp
end


local function readsmallvolt(fixture,netname,slot_num,timeout)

    local f = {GAIN=1,OFFSET=0}

    local ai_channel = fixture.get_measure_table(netname,"CH",slot_num)
    local ai_gnd = fixture.get_measure_table(netname,"GND",slot_num)
    local ai_gain =  fixture.get_measure_table(netname,"GAIN",slot_num)

    if ai_gain then f.GAIN = ai_gain end

    local option = "nor"
    local channel= channel_number(ai_channel)
    local adc_range = "5V"
    local sample_rate = 10000
    local count = 1
    local measure_time = 400

    local io_cmd = fixture.get_measure_table(netname,"IO",slot_num)
    fixture.rpc_write_read(io_cmd,timeout,slot_num)

    local adc_cmd = string.format("blade.adc_read(-c,%s,%s,%s,%s,%s,%s)",option,channel,adc_range,sample_rate,count,measure_time)
    local response = fixture.rpc_write_read(adc_cmd,timeout,slot_num)

    local voltage = string.match(response,"([+-]?%d*%.?%d*)%s*mV")
    --Log.LogInfo('$*** readsmallvolt : '..tostring(voltage))

    if(voltage == nil) then
        return -999999
    end
    --voltage = tonumber(string.format("%f",voltage))
    
    voltage = tonumber(f.GAIN )* tonumber(voltage)  + tonumber(f.OFFSET)
    voltage = tonumber(string.format("%f",voltage))
    --relay_disconnect(HWIO.MeasureTable[netname])
    --Log.LogInfo('$*** readsmallvolt 2: '..tostring(voltage))
    return tonumber(voltage)
end


function func.frequence( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local netname = param.AdditionalParameters.netname
    --Log.LogInfo("$$~~~ netname :"..tostring(netname))
    local value = 0

    if netname == "vpp" then 
        value = tonumber(vpp)

    elseif netname == "duty_cycle" then 
        --Log.LogInfo("$$~~~ duty_cycle :"..tostring(duty_cycle))
        value = tonumber(duty_cycle)

    else

        local fixture = Device.getPlugin("FixturePlugin")
        local slot_num = tonumber(Device.identifier:sub(-1))
        local timeout = 6000

        local f = {GAIN=1,OFFSET=0}  
        local io_cmd = fixture.get_measure_table(netname,"IO",slot_num)
        fixture.rpc_write_read(io_cmd,timeout,slot_num)

        local ai_gain = fixture.get_measure_table(netname,"GAIN",slot_num)
        os.execute("sleep 0.01")

        local door_v = 300
        if param.AdditionalParameters.door ~= nil then
            door_v = param.AdditionalParameters.door
        end


        local cmd = "blade.frequency_measure(-fdv,"..tostring(door_v)..",200)"
        local response =""
        local sumVpp = 0
        local retryCount = 1

        --Log.LogInfo("$$~~~ ai_gain :"..tostring(ai_gain))

        for i=1,retryCount,1 do

            response = fixture.rpc_write_read(cmd,timeout,slot_num)
            vpp = string.match(response,"([+-]?%d+%.*%d*)%s*mV")
            if vpp == nil then
                vpp = 0
            end
            vpp = vpp * tonumber(ai_gain)
            vpp = tonumber(vpp)*f.GAIN + f.OFFSET
            sumVpp = sumVpp + vpp
        end

        vpp = sumVpp / retryCount
        duty_cycle = string.match(response,"%,%s*([+-]?%d+.*%d*)%s+%%")
        freq=string.match(response,"%(([+-]?%d+%.*%d*)%s+Hz")
        if freq == nil then
            freq = 0
        end
        freq = tonumber(freq)
        value=string.format("%.3f",freq)
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    end

    return tonumber(value)
end



function func.readbattcurr( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname


    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 6000


    local value = readsmallvolt(fixture,"BATT_CURRENT_BIG",slot_num,timeout)
    if tonumber(value) < 60 then

        os.execute("sleep 0.5")
        value = readsmallvolt(fixture,"BATT_CURRENT_SMALL",slot_num,timeout)
        local io_cmd = fixture.get_measure_table("BATT_CURRENT_BIG","IO",slot_num)
        fixture.rpc_write_read(io_cmd,timeout,slot_num)

    end

    

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    end
    return value

end


function func.readvolt(netname,param,units)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 6000

    local option = "nor"
    local adc_range = "5V"
    local sample_rate = 10000
    local count = 1
    local measure_time = 80

    local ai_channel =  fixture.get_measure_table(netname,"CH",slot_num)
    local channel= channel_number(ai_channel)

    local value = fixture.read_voltage(netname,tostring(option),tostring(count),tostring(sample_rate),tostring(measure_time),slot_num)

    local voltage = cal_factor.cal_ADC_zero_read_factor(channel,tonumber(value))
    voltage = tonumber(string.format("%f",voltage))
    return voltage

end

function func.dmm(netname,param,units)

    local option = "nor"
    local count = 1
    local sample_rate = 10000
    local measure_time = 70

    if tostring(netname) == "PPLED_OUT" or tostring(netname) == "PPLED_BACK_REG" then
        measure_time = 500

    elseif tostring(netname) == "DENSE_CURRENT" or tostring(netname) == "SPARSE_CURRENT" or tostring(netname) == "ROSALINE_CURRENT" or tostring(netname) == "TITUS_A_CURRENT" or tostring(netname) == "TITUS_B_CURRENT" then
        measure_time = 500

    elseif tostring(netname) =="BATT_CURRENT_BIG" or tostring(netname) =="USB_TARGET_CURRENT" or tostring(netname) =="USB_CURRENT_BIG" then
        measure_time = 100

    end

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local value = fixture.read_voltage(netname,tostring(option),tostring(count),tostring(sample_rate),tostring(measure_time),slot_num)

    if param.AdditionalParameters.gain ~= nil then
        value = tonumber(value) *tonumber(param.AdditionalParameters.gain)
    end
    
    if param == nil then
        error("param is nil")
    end

    local unit = nil

    if units ~=nil then
        unit = units
    
    elseif param.AdditionalParameters.unit ~= nil and param.AdditionalParameters.unit ~="" then
        unit = param.AdditionalParameters.unit

    else
        local limitTab = param.limit
        if limitTab then
            limit = limitTab[param.AdditionalParameters.subsubtestname]
            if limit ~= nil then
                unit = limit.units
            end
        end
    end

    if unit == nil then
        error("unit is nil")
    end

    unit  = string.upper(unit)

    if unit == "MV" or unit == "V" or unit== "UV" then
        local channel =  fixture.get_measure_table(netname,"CH",slot_num)
        value = cal_factor.cal_ai1_8_factor(channel,netname,value)

    elseif unit == "MA" or unit == "A" or unit == "UA" then
        if string.find(netname,"LED") and netname ~= "STROBE_LED_CURRENT" then
            --do nothing
        elseif string.find(netname,"USB_TARGET_CURRENT") then
            local param2 = "5V"
            if param.AdditionalParameters.param2 ~=nil then
                param2 = param.AdditionalParameters.param2
            end
            value = cal_factor.cal_target_current_factor(tonumber(value),param2)

        elseif string.find(netname,"BATT_CURRENT") then
            value = cal_factor.cal_ibatt_factor(tonumber(value))

        elseif string.find(netname,"USB_CURRENT") then
            value = cal_factor.cal_ibus_factor(tonumber(value))

        end 
    end
  
    return tonumber(string.format("%.3f",value))
end

function func.read_voltage( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local netname = param.AdditionalParameters.netname

    local value = func.dmm(netname,param,nil)
    
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)

    return value
    
end



function func.frequence_high( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local netname = param.AdditionalParameters.netname
    local timeout = 5000

    local io1_cmd = fixture.get_measure_table("CLK_Measure_Disable","IO",slot_num)
    fixture.rpc_write_read(io1_cmd,timeout,slot_num)
    local io2_cmd = fixture.get_measure_table(netname,"IO",slot_num)
    fixture.rpc_write_read(io2_cmd,timeout,slot_num)

    local f = {GAIN=1,OFFSET=0}
    local ai_gain =  fixture.get_measure_table(netname,"GAIN",slot_num)
    if ai_gain then f.GAIN = ai_gain end
    os.execute("sleep 0.01")

    local door_v = param.AdditionalParameters.door
    local cmd = "blade.frequency_measure(-fd,"..tostring(door_v)..")"

    local response = fixture.rpc_write_read(cmd,timeout,slot_num)


    local value_freq = string.match(response,"%(([+-]?%d+.%d*)%s+Hz")
    local value_dc = string.match(response,"%,%s*([+-]?%d+.%d*)%s+%%")
    if value_freq == nil  then value_freq = 0 end
    if value_dc == nil then value_dc = 0 end

    local value = string.format("%.3f",value_freq)
    local io_cmd = fixture.get_measure_table("CLK_Measure_Disable","IO",slot_num)
    fixture.rpc_write_read(io_cmd,timeout,slot_num)
    
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    return value
    
end


-- Unique Function ID : Suncode_000017_1.0
-- func.vbus_fb_connect( param )

-- Function to measure Vbus_fb and  PPVBUS_USB_EMI voltage, if Vbus_fb - PPVBUS_USB_EMI< 3mV, then switch realy PPVBUS_FB to CONNECT, otherwise fail

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.vbus_fb_connect( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local Vbus_meas = func.dmm("PPVBUS_USB_EMI",param,"mV")

    Vbus_meas = tonumber(Vbus_meas)/1000
    local Vbus_fb = param.AdditionalParameters.reference
    local diff = tonumber(Vbus_fb) - tonumber(Vbus_meas)

    if diff<0 then
        diff = tonumber(Vbus_meas) - tonumber(Vbus_fb)
    end

    local result = false

    if diff <=3 then
        relay.relay("PPVBUS_FB","CONNECT")
        os.execute("sleep 0.02")
        result = true
    end

    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)

end

-- Unique Function ID : Suncode_000018_1.0
-- func.vbus_check( param )

-- Function to measure VBUS_Orignal and  PPVBUS_USB_EMI voltage,
-- calculate diff= VBUS_Orignal-tonumber(Vbus_meas)/1000 and Vbus_Set=VBUS_Orignal+diff
-- if Vbus_Set>=20 mV, it will be fail, otherwise set vbus power to Vbus_Set, then measure PPVBUS_USB_EMI value, get PPVBUS_USB_EMI voltage

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA

function func.vbus_check( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname


    local Vbus_meas = func.dmm("PPVBUS_USB_EMI",param,"mV")

    local VBUS_Orignal=tonumber(param.AdditionalParameters.reference)

    local diff= VBUS_Orignal-tonumber(Vbus_meas)/1000
    
    local result = true
    local Vbus_Set=VBUS_Orignal+diff
    if tonumber(VBUS_Orignal)==5 then

        if Vbus_Set >= 6 or Vbus_Set<=-6 then
            result = false
        else
            powersupply.set_power({AdditionalParameters={powertype="USB"},Commands=tostring(Vbus_Set)})
            os.execute("sleep 0.05")
            Vbus_meas=func.dmm("PPVBUS_USB_EMI",param,"mV")
        end
    else
        if Vbus_Set>=20 then
            result = false
        else
            
            powersupply.set_power({AdditionalParameters={powertype="USB"},Commands=tostring(Vbus_Set)})
            os.execute("sleep 0.05")
            Vbus_meas=tonumber(func.dmm("PPVBUS_USB_EMI",param,"mV"))
        end
    end

    local value = Vbus_meas
    Log.LogInfo('$$$$ vbus_check: '..tostring(value))
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)

end

function func.gpio_state( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname

    local value = func.dmm(netname,param,"mV")
    
    local voltage = tonumber(value)
    local high_level = tonumber(param.AdditionalParameters.reference)

    if voltage < high_level*0.3 then
        value =  0
    elseif voltage >=high_level*0.7 and voltage <=high_level*1.2 then
        value = 1
    else
        value = -1
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    
    local result = Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    
end


return func


