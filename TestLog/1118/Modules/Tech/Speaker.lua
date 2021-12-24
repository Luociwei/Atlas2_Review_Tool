local Speaker = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local flow_log = require("Tech/WriteLog")

local batt_mon = nil
local thld = nil

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000086_1.0
-- Speaker.bitAnd(num1,num2)
-- Function to bit and function
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : number,number
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function Speaker.bitAnd(num1, num2)
    local tmp1 = num1
    local tmp2 = num2
    local str = ""
    repeat
        local s1 = tmp1 % 2
        local s2 = tmp2 % 2
        if s1 == s2 then
            if s1 == 1 then
                str = "1" .. str
            else
                str = "0" .. str
            end
        else
            str = "0" .. str
        end
        tmp1 = math.modf(tmp1 / 2)
        tmp2 = math.modf(tmp2 / 2)
    until (tmp1 == 0 and tmp2 == 0)
    return tonumber(str, 2)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000087_1.0
-- Speaker.listCmdsAndsend(cmd)
-- Function to list all the command to send, if response error, status will show error
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : string
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function Speaker.listCmdsAndsend(cmd)

    local status = ""
    local commands = cmd .. ";"
    local response = ""
    for command in string.gmatch(commands, "(.-);") do

        local temp_buffer = dutCmd.sendCmdAndParse({ Commands = command, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        response = response .. temp_buffer
        if string.find(cmd, "wait") then
            -- do nothing
        else

            if string.find(string.upper(temp_buffer), "OK") == nil then
                if string.find(string.upper(temp_buffer), "PASSED") == nil then
                    if string.find(string.upper(temp_buffer), "PASS") == nil then
                        status = "ERROR"
                    end
                end
            end

        end

    end
    flow_log.writeFlowLog(response)
    return status
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000088_1.0
-- Speaker.sendBoostMaintenanceCmd( param )
-- Function to send boost maintenance command to diags
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
function Speaker.sendBoostMaintenanceCmd(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local index = tostring(param.AdditionalParameters.param1)
    local offset = tonumber(param.AdditionalParameters.param2)

    local cmd = param.Commands
    local ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
    flow_log.writeFlowLog(ret)
    local pattern = param.AdditionalParameters.pattern

    ret = string.match(ret, pattern)

    local value = Speaker.bitAnd(tonumber(ret), tonumber(0x200))
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000089_1.0
-- Speaker.parseMaintenance( param )
-- Function to parse maintenance response
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
function Speaker.parseMaintenance(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local _last_diags_response = param.Input

    local pattern = param.AdditionalParameters.pattern
    local ret = string.match(_last_diags_response, pattern)

    local value = Speaker.bitAnd(tonumber(ret), tonumber(0x200))

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000090_1.0
-- Speaker.runCmds( param )
-- Function to run multi diags commands and check response has "OK"/"PASSED"/"PASS" keyword
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
function Speaker.runCmds(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands

    local last_result = ""
    local ret_all = ""

    local commands = cmd .. ";"
    for command in string.gmatch(commands, "(.-);") do

        local temp_buffer = dutCmd.sendCmdAndParse({ Commands = command, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        if string.find(cmd, "wait") then
            -- do nothing
        else

            if string.find(string.upper(temp_buffer), "OK") == nil then

                if string.find(string.upper(temp_buffer), "PASSED") == nil then

                    if string.find(string.upper(temp_buffer), "PASS") == nil then

                        last_result = "--FAIL--"

                    end

                end
            end
        end
        ret_all = ret_all .. temp_buffer

    end
    flow_log.writeFlowLog(ret_all)
    local result = false
    if last_result == "" then
        result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
    return ret_all

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000091_1.0
-- Speaker.ampMeasBBTL( param )
-- Function to calculate RMS value
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
function Speaker.ampMeasBBTL(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local _last_diags_response = param.Input
    flow_log.writeFlowLog(_last_diags_response)
    local keyName = param.AdditionalParameters.param1
    local pattern = param.AdditionalParameters.pattern
    local v = string.match(_last_diags_response, pattern)
    flow_log.writeFlowLog(v)
    local value = v
    if string.find(keyName, "v_rms_l") then
        value = 15.4 * tonumber(v) / (2 ^ 15 - 1)

    elseif string.find(keyName, "v_rms") then
        value = 15.4 * tonumber(v) / (2 ^ 15 - 1)

    elseif string.find(keyName, "i_rms_l") then
        value = 3 * tonumber(v) / (2 ^ 15 - 1) * 1000

    elseif string.find(keyName, "i_rms") then
        value = 3 * tonumber(v) / (2 ^ 15 - 1) * 1000
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000092_1.0
-- Speaker.ampMeasPP( param )
-- Function to calculate vmon/imon value
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
function Speaker.ampMeasPP(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local keyName = param.AdditionalParameters.param1
    local _last_diags_response = param.Input

    local pattern_dp = param.AdditionalParameters.pattern_dp
    local pattern_dn = param.AdditionalParameters.pattern_dn

    local value = 0
    if string.find(keyName, "vmon_pp") then
        local vmon_dp = string.match(_last_diags_response, pattern_dp)
        local vmon_dn = string.match(_last_diags_response, pattern_dn)
        local DP_value = -1
        local DN_value = -1

        if tonumber(vmon_dp) then
            DP_value = tonumber(vmon_dp)
        end

        if tonumber(vmon_dn) then
            DN_value = tonumber(vmon_dn)
        end
        value = 15.4 * (10 ^ (DP_value / 20) + 10 ^ (DN_value / 20))

    elseif string.find(keyName, "imon_pp") then
        local imon_dp = string.match(_last_diags_response, pattern_dp)
        local imon_dn = string.match(_last_diags_response, pattern_dn)
        local DP_value = -1
        local DN_value = -1

        if tonumber(imon_dp) then
            DP_value = tonumber(imon_dp)
        end

        if tonumber(imon_dn) then
            DN_value = tonumber(imon_dn)
        end

        value = 3 * (10 ^ (DP_value / 20) + 10 ^ (DN_value / 20)) * 1000

    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000093_1.0
-- Speaker.calLeftRDC( param )
-- Function to calculate RMS/DCR value ,value = (v_rms_l_cal)/(i_rms_l_cal) *100  
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
function Speaker.calLeftRDC(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(param.InputDict))
    local keyName = param.AdditionalParameters.param1
    local value = 0

    if keyName == "v_rms_l_cal" then
        value = inputDict.v_rms_l

    elseif keyName == "i_rms_l_cal" then
        value = inputDict.i_rms_l

    elseif keyName == "dcr_cal" then
        local v_rms_l_cal = inputDict.v_rms_l
        local i_rms_l_cal = inputDict.i_rms_l

        value = tonumber(v_rms_l_cal) / tonumber(i_rms_l_cal)
        value = value * 1000  -- need check
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000094_1.0
-- Speaker.initVPBR( param )
-- Function to get vpbr value
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
function Speaker.initVPBR(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local cmd_return_result = ""
    local init = param.AdditionalParameters.param1
    if init == "vpbr_init" then
        local cmd = param.Commands
        cmd_return_result = Speaker.listCmdsAndsend(cmd)
        fixture.set_battery_voltage(3380, "3500-3380-200", slot_num)
        os.execute("sleep 0.005")

    elseif init == "vpbr_init_1" then
        local cmd = param.Commands
        cmd_return_result = Speaker.listCmdsAndsend(cmd)
    elseif init == "vpbr_init_2" then
        local cmd = param.Commands
        cmd_return_result = Speaker.listCmdsAndsend(cmd)
    elseif init == "stop" then
        local cmd = param.Commands
        cmd_return_result = Speaker.listCmdsAndsend(cmd)
        fixture.set_battery_voltage(3380, "3500-4300-200", slot_num)

    elseif init == "reset" then
        local cmd = param.Commands
        cmd_return_result = list_cmd_send(cmd)
    elseif init == "unmask" then
        local cmd = param.Commands
        cmd_return_result = list_cmd_send(cmd)

    elseif init == "GPIO_SPKAMP_TO_SOC_IRQ_L" then
        local cmd = param.Commands
        local pattern = param.AdditionalParameters.pattern
        cmd_return_result = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { pattern = pattern, record = "NO", tick = "no" }, isNotTop = true })

    end
    flow_log.writeFlowLog(cmd_return_result)
    local result = true
    if (cmd_return_result == "ERROR") then
        result = false
    end

    if param.AdditionalParameters.parametric ~= nil then
        local limitTab = param.limit
        local limit = nil
        if limitTab then
            limit = limitTab[param.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)

    else
        if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000095_1.0
-- Speaker.loopTestVPBR( param )
-- Function to loop test  vpbr ,and get the value
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
function Speaker.loopTestVPBR(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1

    local ret = nil
    local response = nil
    local irq_status = nil
    local irq_state = nil
    local reg_flag = nil

    local pin = "200"
    local result = false

    if param1 == "loop" then
        irq_state = 1
        for i = 72, 80, 1 do

            irq_status = dutCmd.sendCmdAndParse({ Commands = "socgpio --port 0 --pin " .. pin .. " --get", AdditionalParameters = { pattern = "SoC%s*GPIO%[0,%d*%]%s*=%s*(%d*)", record = "NO", tick = "no" }, isNotTop = true })
            Log.LogInfo('$*** >vpbr_test_loop 1: ' .. tostring(irq_status))
            irq_status = tonumber(irq_status)

            reg_flag = dutCmd.sendCmdAndParse({ Commands = "audioreg -b boost-master -r -a 0x2818", AdditionalParameters = { pattern = "0x2818%s*=%s*(0x%x*)", escape = "yes", record = "NO", tick = "no" }, isNotTop = true })
            reg_flag = dutCmd.hexToBinary(reg_flag, 12, nil, "1")
            Log.LogInfo('$*** >vpbr_test_loop 2: ' .. tostring(reg_flag))
            if reg_flag == nil then
                reg_flag = -1
            end

            response = dutCmd.sendCmdAndParse({ Commands = "audioparam -b boost-master -g", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
            --Log.LogInfo('$*** >vpbr_test_loop 3: '..tostring(response))
            batt_mon = string.match(response, "vbatt%-mon%s*=%s*(%d+.%d+)")

            if not (batt_mon) then
                batt_mon = -1
            end

            thld = string.match(response, "br%-l3%-thld%s*=%s*(%d+.%d+)")
            if not (thld) then
                thld = -1
            end

            if irq_status == 0 and reg_flag == 1 then
                irq_state = 0
                result = true
                break
            else
                if i == 81 then
                    ret = "ALC_VTH out of range"
                    result = false
                else
                    ret = "0x" .. string.lower(string.format("%02X", tonumber(i))) .. "50604"
                    local command = "audioreg -b boost-master -w -a 0x4804 -d " .. ret
                    dutCmd.sendCmdAndParse({ Commands = command, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
                    result = true

                end
            end

        end

    elseif param1 == "batt_mon" then
        ret = batt_mon
        batt_mon = nil

    elseif param1 == "thld" then
        ret = thld
        thld = nil
    elseif param1 == "IRQ" then
        ret = irq_state
    end

    Log.LogInfo("-->>>vpbr_test_loop: " .. tostring(ret))
    if param.AdditionalParameters.attribute ~= nil and result then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ret))
    end

    if param.AdditionalParameters.parametric ~= nil then

        local limitTab = param.limit
        local limit = nil
        if limitTab then
            limit = limitTab[param.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
    else
        if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, ret)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000096_1.0
-- Speaker.clear( param )
-- Function to send diags command
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
function Speaker.clear(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local bit = param.AdditionalParameters.bit
    local pattern1 = param.AdditionalParameters.pattern

    local ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { return_val = "raw", escape = "yes", record = "NO", tick = "no" }, isNotTop = true })
    flow_log.writeFlowLog(ret)
    ret = string.match(ret, pattern1)
    ret = dutCmd.hexToBinary(ret, tonumber(bit), nil, "1")

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, ret)
end

return Speaker


