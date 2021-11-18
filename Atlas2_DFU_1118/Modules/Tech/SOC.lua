local SOC = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local flow_log = require("Tech/WriteLog")

local V_CPU = -9999
local V_SOC = -9999
local V_GPU = -9999
local V_DCS = -9999
local V_DISP = -9999

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000080_1.0
-- SOC.parseTDEV( param )
-- Function to calculate soc temperature
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
function SOC.parseTDEV(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1
    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(inputDict))
    local min = 0
    local avg = 0
    local max = 0
    if param1 == "THERMAL0" then
        min = inputDict.THERMAL0_Min
        avg = inputDict.THERMAL0_Average
        max = inputDict.THERMAL0_Max

    elseif param1 == "THERMAL1" then
        min = inputDict.THERMAL1_Min
        avg = inputDict.THERMAL1_Average
        max = inputDict.THERMAL1_Max
    end

    local value = -1
    if (tonumber(min) > (tonumber(avg) - 5)) and (tonumber(max) < (tonumber(avg) + 5)) then
        value = 1
    else
        value = 0
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
-- Unique Function ID            :  Suncode_F000081_1.0
-- SOC.sendSOCCmdAndParse( param )
-- Function to send soc command to get Soc/CPU/GPU/PMU/Disp Voltage
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
function SOC.sendSOCCmdAndParse(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local command = param.Commands .. ";"

    local buffer = ""
    for cmd in string.gmatch(command, "(.-);") do
        local temp_buffer = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no", isNotTop = true } })
        buffer = buffer .. temp_buffer

    end
    flow_log.writeFlowLog(buffer)
    local Soc_Voltage_match = "SoC%s*Voltage%s*:%s*(%d+)%s*mV"
    local Gpu_Voltage_match = "Gpu%s*Voltage%s*:%s*(%d+)%s*mV"
    local DCS_Voltage_match = "Dcs%s*Voltage%s*:%s*(%d+)%s*mV"
    local DISP_Voltage_match = "Disp%s*Voltage%s*:%s*(%d+)%s*mV"
    local Cpu_Voltage_match = "PMU%s*ADC%s*test.-ADC%s*Channel%s*.-:%s*(%d+.%d+)%s*mV"

    V_CPU = string.match(buffer, Cpu_Voltage_match)
    V_SOC = string.match(buffer, Soc_Voltage_match)
    V_GPU = string.match(buffer, Gpu_Voltage_match)
    V_DCS = string.match(buffer, DCS_Voltage_match)
    V_DISP = string.match(buffer, DISP_Voltage_match)

    if V_CPU == nil then
        V_CPU = -9999
    end
    if V_SOC == nil then
        V_SOC = -9999
    end
    if V_GPU == nil then
        V_GPU = -9999
    end
    if V_DCS == nil then
        V_DCS = -9999
    end
    if V_DISP == nil then
        V_DISP = -9999
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000082_1.0
-- SOC.getSOCValue( param )
-- Function to get Soc/CPU/GPU/PMU/Disp Voltage
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
function SOC.getSOCValue(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local keyName = param.AdditionalParameters.param1
    local value = -999
    if keyName == "Cpu_Voltage" then
        value = V_CPU
    elseif keyName == "Soc_Voltage" then
        value = V_SOC
    elseif keyName == "Gpu_Voltage" then
        value = V_GPU
    elseif keyName == "DCS_Voltage" then
        value = V_DCS
    elseif keyName == "DISP_Voltage" then
        value = V_DISP
    else
        value = -9999
    end
    flow_log.writeFlowLog(keyName)
    flow_log.writeFlowLog(value)
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
-- Unique Function ID            :  Suncode_F000083_1.0
-- SOC.calculateStatePercentage( param )
-- Function to calculate percentage, 100*(PPVDD_ECPU - V_CPU)/(PPVDD_ECPU) or state difference
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
function SOC.calculateStatePercentage(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1
    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(inputDict))
    local value = -9999

    if (string.find(param1, "ECPU")) then
        local PPVDD_ECPU = inputDict.PPVDD_ECPU
        local ret = 100 * (tonumber(PPVDD_ECPU) - V_CPU) / tonumber(PPVDD_ECPU);
        value = string.format("%.6f", ret)

    elseif (string.find(param1, "CPU")) then

        local PPVDD_CPU = inputDict.PPVDD_CPU
        local ret = 100 * (tonumber(PPVDD_CPU) - V_CPU) / tonumber(PPVDD_CPU);
        value = string.format("%.6f", ret)

    elseif (string.find(param1, "SOC")) then

        local PPVDD_S1_SOC = inputDict.PPVDD_S1_SOC
        local ret = 100 * (tonumber(PPVDD_S1_SOC) - V_SOC) / tonumber(PPVDD_S1_SOC);
        value = string.format("%.6f", ret)

    elseif param1 == "state0" then

        local state0 = inputDict.state0
        local state4 = inputDict.state4
        local res = tonumber(state0) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state1" then

        local state1 = inputDict.state1
        local state4 = inputDict.state4
        local res = tonumber(state1) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state2" then

        local state2 = inputDict.state2
        local state4 = inputDict.state4
        local res = tonumber(state2) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state3" then

        local state3 = inputDict.state3
        local state4 = inputDict.state4
        local res = tonumber(state3) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state5" then

        local state5 = inputDict.state5
        local state4 = inputDict.state4
        local res = tonumber(state5) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state6" then

        local state6 = inputDict.state6
        local state4 = inputDict.state4
        local res = tonumber(state6) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state7" then

        local state7 = inputDict.state7
        local state4 = inputDict.state4
        local res = tonumber(state7) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state8" then

        local state8 = inputDict.state8
        local state4 = inputDict.state4
        local res = tonumber(state8) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state9" then

        local state9 = inputDict.state9
        local state4 = inputDict.state4
        local res = tonumber(state9) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state10" then

        local state10 = inputDict.state10
        local state4 = inputDict.state4
        local res = tonumber(state10) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state11" then

        local state11 = inputDict.state11
        local state4 = inputDict.state4
        local res = tonumber(state11) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state12" then

        local state12 = inputDict.state12
        local state4 = inputDict.state4
        local res = tonumber(state12) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state13" then

        local state13 = inputDict.state13
        local state4 = inputDict.state4
        local res = tonumber(state13) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state14" then

        local state14 = inputDict.state14
        local state4 = inputDict.state4
        local res = tonumber(state14) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state15" then

        local state15 = inputDict.state15
        local state4 = inputDict.state4
        local res = tonumber(state15) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state16" then

        local state16 = inputDict.state16
        local state4 = inputDict.state4
        local res = tonumber(state16) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state17" then

        local state17 = inputDict.state17
        local state4 = inputDict.state4
        local res = tonumber(state17) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state18" then

        local state18 = inputDict.state18
        local state4 = inputDict.state4
        local res = tonumber(state18) - tonumber(state4)
        value = math.abs(res)

    elseif param1 == "state19" then

        local state19 = inputDict.state19
        local state4 = inputDict.state4
        local res = tonumber(state19) - tonumber(state4)
        value = math.abs(res)

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
-- Unique Function ID            :  Suncode_F000084_1.0
-- SOC.checkECID( paraTab )
-- Function to get MLB ecid from sfc, and compare ecid with MLB
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
function SOC.checkECID(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local dut_id = paraTab.Input

    local interactiveView = Device.getPlugin("InteractiveView")
    local status, data = xpcall(interactiveView.getData, debug.traceback, Device.systemIndex)
    local sn = data

    Log.LogInfo("$$$$$ getSNFromInteractiveView " .. data)
    local sfc_key = paraTab.AdditionalParameters.sfc_key

    local result = false
    local failureMsg = ""

    if sn and #sn > 0 then
        if sfc_key then
            local sfc = Device.getPlugin("SFC")
            local sfc_resp = sfc.getAttributes(sn, { sfc_key })
            flow_log.writeFlowLog(comFunc.dump(sfc_resp))
            Log.LogInfo("$$$$ sfc query: " .. sfc_key)
            Log.LogInfo("$$$$ sfc result: " .. comFunc.dump(sfc_resp))
            flow_log.writeFlowLog(comFunc.dump(sfc_resp))
            local sfc_value = sfc_resp[sfc_key]
            Log.LogInfo("dut_id :" .. tostring(dut_id))
            if sfc_value and sfc_value ~= "" then
                if sfc_value == dut_id then
                    result = true
                end
            else
                failureMsg = "sfc_key[" .. sfc_key .. "] query failed"
            end
        else
            failureMsg = "miss sfc_key in AdditionalParameters"
        end
    else
        failureMsg = "no input sn"
    end
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname, failureMsg)
    end
    if result == false and paraTab.AdditionalParameters.fa_sof == "YES" then
        error('SOC.checkECID is error')
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000085_1.0
-- SOC.getSOCStage(paraTab )
-- Function to get Soc secure mode and production mode
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
function SOC.getSOCStage(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local input = paraTab.Input

    --Log.LogInfo("$$$$ soc_pro_stage: "..input)
    local semode = string.match(input, "secure%-mode:%s*(%w+)%s*")
    --Log.LogInfo("$$$$ soc_pro_stage semode: "..semode)
    local promode = string.match(input, "production%-mode:%s*(%w+)%s*[\r\n]%s*board%-id:")
    --Log.LogInfo("$$$$ soc_pro_stage promode: "..promode)

    semode = tostring(semode)
    promode = tostring(promode)

    local ret = ""
    local result = true
    if semode == "0" and promode == "0" then
        ret = "B06"
    elseif semode == "1" and promode == "0" then
        ret = "B09"
    elseif semode == "1" and promode == "1" then
        ret = "B12"
    else
        result = false
        ret = "Unknown"
    end

    if paraTab.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
    end

    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, result)
end

return SOC


