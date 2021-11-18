local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local relay = require("Tech/Relay")
local powersupply = require("Tech/PowerSupply")
local flow_log = require("Tech/WriteLog")

-- local vpp = -99999
-- local duty_cycle = -9999
-- local freq = -9999
-- local thd = -9999


function func.frequence( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local netname = param.AdditionalParameters.netname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
  
    local value = 0
    local door_v = 300
    if param.AdditionalParameters.door ~= nil then
        door_v = tonumber(param.AdditionalParameters.door)
    end

    if netname == "vpp" then 
        value = tonumber(fixture.read_frequency_vpp(netname,door_v,slot_num))

    elseif netname == "duty_cycle" then 
        value = tonumber(tonumber(fixture.read_frequency_duty(netname,door_v,slot_num)))

    else
        value = tonumber(fixture.read_frequency(netname,door_v,slot_num))
    end

    value=string.format("%.3f",value)

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

    local value = func.dmm("BATT_CURRENT_BIG",param)
    if tonumber(value) < 60 then
        value = func.dmm("BATT_CURRENT_SMALL",param)
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


function func.dmm(netname,param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local value = fixture.read_voltage(netname,slot_num)

    if param.AdditionalParameters.gain ~= nil then
        value = tonumber(value) *tonumber(param.AdditionalParameters.gain)
    end

    flow_log.writeFlowLog(netname.." : "..tostring(value))
    return tonumber(string.format("%.3f",value))
end

function func.read_voltage( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local netname = param.AdditionalParameters.netname

    local value = func.dmm(netname,param)
    
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)

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
    
    local Vbus_meas = func.dmm("PPVBUS_USB_EMI",param)

    local Vbus_fb = param.AdditionalParameters.reference
    local diff = tonumber(Vbus_fb) - tonumber(Vbus_meas)

    if diff<0 then
        diff = tonumber(Vbus_meas) - tonumber(Vbus_fb)
    end

    local result = false

    if diff <=3000 then  --3V
        relay.relay("PPVBUS_FB","CONNECT")
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


    local Vbus_meas = func.dmm("PPVBUS_USB_EMI",param)

    local VBUS_Orignal=tonumber(param.AdditionalParameters.reference)

    local diff= VBUS_Orignal-tonumber(Vbus_meas)
    
    local result = true
    local Vbus_Set=VBUS_Orignal+diff
    if tonumber(VBUS_Orignal)==5000 then

        if Vbus_Set >= 6000 or Vbus_Set<=-6000 then  -- 6000mV
            result = false
        else
            powersupply.set_power({AdditionalParameters={powertype="USB"},Commands=tostring(Vbus_Set)})
            os.execute("sleep 0.03")
            Vbus_meas=func.dmm("PPVBUS_USB_EMI",param)
        end
    else
        if Vbus_Set>=20000 then    --20V
            result = false
        else
            
            powersupply.set_power({AdditionalParameters={powertype="USB"},Commands=tostring(Vbus_Set)})
            os.execute("sleep 0.03")
            Vbus_meas=tonumber(func.dmm("PPVBUS_USB_EMI",param))
        end
    end

    local value = Vbus_meas

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

    local value = func.dmm(netname,param)
    
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


