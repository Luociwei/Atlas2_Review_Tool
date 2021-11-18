local Power = {}
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")
local comFunc = require("Matchbox/CommonFunc")


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000064_1.0
-- Power.calculateCurrentDifference( param )
-- Function to Current differential = Batt_current_On-Baseline_current
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
function Power.calculateCurrentDifference(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict
    local value = -9999
    local param1 = param.AdditionalParameters.param1
    flow_log.writeFlowLog(comFunc.dump(inputDict))
    if param1 == "Batt_current_Delta" then

        local Batt_current_On = -995
        if inputDict.Batt_current_On ~= nil then
            Batt_current_On = inputDict.Batt_current_On
        end

        local Baseline_current = -995
        if inputDict.Baseline_current ~= nil then
            Baseline_current = inputDict.Baseline_current
        end
        value = tonumber(Batt_current_On) - tonumber(Baseline_current)

    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000065_1.0
-- Power.shutdownDUT(param )
-- Function to send diags command to power off MLB
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
function Power.shutdownDUT(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    local startTime = os.time()

    local cmd = param.Commands

    dut.setDelimiter("")
    dut.write(cmd)

    local timeout = 2
    local content = ""
    local lastRetTime = os.time()
    local result = false
    repeat

        local status, ret = xpcall(dut.read, debug.traceback, 0.1, '')

        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret
        end

    until (os.difftime(os.time(), lastRetTime) >= timeout)
    flow_log.writeFlowLog(content)

    dut.setDelimiter(default_delimiter)
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end

function Power.readMaxVoltage(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local mode = tostring(5000) .. ";" .. tostring(param.AdditionalParameters.gain)
    local value = 0
    local volt_tab = {}
    flow_log.writeFlowLog("[dmm_measure] : " .. netname .. "   [mode] : " .. tostring(mode))
    for i = 1, 5 do
        value = fixture.read_voltage(netname, mode , slot_num)
        flow_log.writeFlowLog("[dmm_measure] : " .. netname .. "   [value] : " .. tostring(value))
        table.insert(volt_tab, value)
    end
    table.sort(volt_tab)
    value = volt_tab[5]
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end

    local result = Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('Dmm.readVoltage is Out of limit error')
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value
end

return Power


