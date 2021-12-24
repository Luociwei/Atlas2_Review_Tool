local Eload = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000035_1.0
-- Eload.setEload( param )
-- Function to set eload output current
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
function Eload.setEload(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    flow_log.writeFlowLog(cmd)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local channel, mode, value = string.match(cmd, "eload%.set%((%d)%*(%w*)%*(%d*%.?%d*)%)")
    local ret = fixture.eload_set(tonumber(channel), tostring(mode), tonumber(value), slot_num)
    flow_log.writeFlowLog(ret)
    os.execute("sleep 0.01")
    local result = true
    if string.find(ret, "ERR") then
        result = false
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(param, result)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000036_1.0
-- Eload.readEloadCurrent( param )
-- Function to read eload current
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function Eload.readEloadCurrent(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local value = fixture.read_eload_current(netname, slot_num)

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    end
    flow_log.writeFlowLimitAndResult(param, value)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    return tonumber(value)
end

return Eload


