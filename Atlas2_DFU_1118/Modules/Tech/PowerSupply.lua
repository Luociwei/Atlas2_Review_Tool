local PowerSupply = {}
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000066_1.0
-- PowerSupply.powerSupply(param ) 
-- Function to set USB/Battery/PP5V0/Eload output
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function PowerSupply.powerSupply(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local result = false
    local powertype = param.AdditionalParameters.powertype
    if powertype:upper() == "BATT" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_battery_voltage(tonumber(stop), tostring(start) .. "-" .. tostring(stop) .. "-" .. tostring(step), slot_num)
            Log.LogInfo(">1>>set " .. tostring(step) .. " " .. ret)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_battery_voltage(tonumber(value), "", slot_num)
            Log.LogInfo(">1>>set: " .. tostring(value) .. " " .. ret)
            flow_log.writeFlowLog("BATT_OUTPUT : " .. tostring(value))
        end

        if not string.find(ret, "ERR") then
            result = true
        end
        flow_log.writeFlowLog(ret)

    elseif powertype:upper() == "USB" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_usb_voltage(tonumber(stop), tostring(start) .. "-" .. tostring(stop) .. "-" .. tostring(step), slot_num)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_usb_voltage(tonumber(value), "", slot_num)
            flow_log.writeFlowLog("USB_OUTPUT : " .. tostring(value))
        end

        if not string.find(ret, "ERR") then
            result = true
        end
        flow_log.writeFlowLog(ret)
    elseif powertype:upper() == "PP5V0" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_pp5v0_output(tonumber(stop), tostring(start) .. "-" .. tostring(stop) .. "-" .. tostring(step), slot_num)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_pp5v0_output(tonumber(value), "", slot_num)
            flow_log.writeFlowLog("PP5V0_OUTPUT : " .. tostring(value))
        end

        if not string.find(ret, "ERR") then
            result = true
        end
        flow_log.writeFlowLog(ret)

    elseif powertype:upper() == "ELOAD" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_eload_output(tonumber(stop), tostring(start) .. "-" .. tostring(stop) .. "-" .. tostring(step), slot_num)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_eload_output(tonumber(value), "", slot_num)
            flow_log.writeFlowLog("SET_ELOAD_OUTPUT : " .. tostring(value))
        end

        if string.find(ret, "ERR") then
            error("power supply set error!")
        else
            result = true
        end
        flow_log.writeFlowLog(ret)
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

return PowerSupply


