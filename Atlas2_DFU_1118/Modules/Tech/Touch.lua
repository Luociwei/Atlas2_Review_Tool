local Touch = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000097_1.0
-- Touch.calculateTouchCurrentDifference( paraTab )
-- Function to current difference = PFM_current_No_load-Baseline_current
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
function Touch.calculateTouchCurrentDifference(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName .. paraTab.testNameSuffix
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local inputDict = paraTab.InputDict

    local value = -999
    if paraTab.AdditionalParameters.delta ~= nil then
        local delta_name = paraTab.AdditionalParameters.delta
        if delta_name == "PFM_current_Delta" then
            value = tonumber(inputDict.PFM_current_No_load) - tonumber(inputDict.Baseline_current)

        elseif delta_name == "PWM_current_Delta" then
            value = tonumber(inputDict.PWM_current_No_load) - tonumber(inputDict.Baseline_current)

        elseif delta_name == "Dombra_Delta" then
            value = tonumber(inputDict.PWM_current_No_load) - tonumber(inputDict.PFM_current_No_load)
        end

    end

    local limitTab = paraTab.limit
    local limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, value)
    return value

end

function Touch.readVoltagePFM(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName .. paraTab.testNameSuffix
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local inputDict = paraTab.InputDict
    local Baseline_current = inputDict.Baseline_current
    local value = -9999

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = paraTab.AdditionalParameters.netname
    local mode = paraTab.AdditionalParameters.mode or ""
    value = fixture.read_voltage(netname, mode, slot_num)
    flow_log.writeFlowLog("[dmm_measure] : " .. netname .. " : " .. tostring(value))
    for i = 1, 3 do
        if math.abs(tonumber(value) - tonumber(Baseline_current)) >= 10 then
            os.execute("sleep 0.2")
            value = fixture.read_voltage(netname, mode, slot_num)
            flow_log.writeFlowLog("[dmm_measure] : " .. netname .. " : " .. tostring(value))
        else
            break
        end
    end
    local limitTab = paraTab.limit
    local limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, value)
    return value

end
return Touch


