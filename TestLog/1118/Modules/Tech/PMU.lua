local PMU = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")
local dutCmd = require("Tech/DUTCmd")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000063_1.0
-- PMU.checkButton( param ) 
-- Function to check Power Button, volume up button, volume down button
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function PMU.checkButton(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("BTN_GND", "DISCONNECT", slot_num)
    local dut = Device.getPlugin("dut")
    local timeout = 5
    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    dut.setDelimiter("] :-)")
    if param.AdditionalParameters.mark ~= nil then
        xpcall(dutCmd.dutRead, debug.traceback, { Commands = "\r\n", Timeout = timeout, isNotTop = true })
    end

    local cmd = param.Commands
    dut.write(cmd)
    os.execute("sleep 0.01")
    if cmd == "button -h --time 2000" then
        fixture.relay_switch("BTN_GND", "GPIO_BTN_POWER", slot_num)
        os.execute("sleep 0.3")
        fixture.relay_switch("BTN_GND", "DISCONNECT", slot_num)

    elseif cmd == "button -u --time 2000" then
        fixture.relay_switch("BTN_GND", "GPIO_BTN_VOL_UP", slot_num)
        os.execute("sleep 0.3")
        fixture.relay_switch("BTN_GND", "DISCONNECT", slot_num)

    elseif cmd == "button -d --time 2000" then
        fixture.relay_switch("BTN_GND", "GPIO_BTN_VOL_DOWN", slot_num)
        os.execute("sleep 0.3")
        fixture.relay_switch("BTN_GND", "DISCONNECT", slot_num)

    end
    os.execute("sleep 0.01")
    local ret = dut.read(timeout)
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.pattern ~= nil then
        local pattern = param.AdditionalParameters.pattern
        ret = string.match(ret, pattern)
    end

    local result = false
    if ret ~= nil then
        result = true
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

return PMU


