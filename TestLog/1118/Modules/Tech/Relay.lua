local Relay = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000078_1.0
-- Relay.relaySwitch( param )
-- Function to control hardware relay on/off
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : bool
-----------------------------------------------------------------------------------]]
function Relay.relaySwitch(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local state = param.AdditionalParameters.state or ""
    local ret = fixture.relay_switch(netname, state, slot_num)
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.netname2 ~= nil and param.AdditionalParameters.netname2 ~= "" and param.AdditionalParameters.state2 ~= nil and param.AdditionalParameters.state2 ~= "" then
        os.execute('sleep 0.01')
        local netname2 = param.AdditionalParameters.netname2
        local state2 = param.AdditionalParameters.state2
        local ret2 = fixture.relay_switch(netname2, state2, slot_num)
        flow_log.writeFlowLog(ret2)
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "ture")
    return true
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000079_1.0
-- Relay.setAmplification( param )
-- Function to set current/voltage magnification value
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
function Relay.setAmplification(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local state = param.AdditionalParameters.state

    local ret = fixture.relay_switch(netname, state, slot_num)
    flow_log.writeFlowLog(ret)

    local factor = 1
    if state == "X1" then
        result = 1
    elseif state == "X10" then
        result = 0.1
    elseif state == "X100" then
        result = 0.01
    elseif state == "X1000" then
        result = 0.001
    end

    if param.AdditionalParameters.netname2 ~= nil and param.AdditionalParameters.netname2 ~= "" and param.AdditionalParameters.state2 ~= nil and param.AdditionalParameters.state2 ~= "" then
        os.execute('sleep 0.01')
        local netname2 = param.AdditionalParameters.netname2
        local state2 = param.AdditionalParameters.state2
        local ret2 = fixture.relay_switch(netname2, state2, slot_num)
        flow_log.writeFlowLog(ret2)
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(param, 'true')
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    return result
end

return Relay


