local Process = {}
local Log = require("Matchbox/logging")
local dutCmd = require("Tech/DUTCmd")
local Record = require 'Matchbox/record'
local powersupply = require("Tech/PowerSupply")
local comFunc = require("Matchbox/CommonFunc")
local flow_log = require("Tech/WriteLog")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000067_1.0
-- getSN()
-- Function to get the serialNumber of MLB
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : N/A 
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
myOverrideTable = {}
myOverrideTable.getSN = function()
    local dut = Device.getPlugin("dut")
    local mlbSerialNumber = dut.mlbSerialNumber(3)
    Log.LogInfo("mlbSerialNumber>>>" .. comFunc.dump(mlbSerialNumber))
    return mlbSerialNumber
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000068_1.0
-- Process.startCB(param)
-- Function to start process control ,read SN, write and read the "imcomplete" to cb
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
function Process.startCB(param)
    flow_log.writeFlowLogStart(param)
    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then
        dutPluginName = "dut"
    end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then
        error('DUT plugin ' .. tostring(dutPluginName) .. ' not found.')
    end
    local category = param.AdditionalParameters.category
    Log.LogInfo('Starting process control')
    if category ~= nil and category ~= '' then
        ProcessControl.start(dut, category)
    else
        ProcessControl.start(dut, myOverrideTable)
    end
    flow_log.writeFlowLimitAndResult(param, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000069_1.0
-- Process.finishCB(param)
-- Function to finish process control, write and check the result cb of current station
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
function Process.finishCB(param)
    flow_log.writeFlowLogStart(param)
    -- do not finish CB if not started.
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Log.LogInfo('Process control finished or not started; skip finishCB.')
        return
    end

    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then
        dutPluginName = "dut"
    end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then
        error('DUT plugin ' .. tostring(param.Input) .. ' not found.')
    end

    -- read Poison flag from Input
    local Poison = param.Input
    if Poison == 'TRUE' then
        Log.LogInfo('Poison requested; poisoning CB.')
        ProcessControl.poison(dut, myOverrideTable)
    end
    Log.LogInfo('Finishing process control')
    ProcessControl.finish(dut, myOverrideTable)
    flow_log.writeFlowLimitAndResult(param, "ture")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000070_1.0
-- Process.dataReportSetup(param)
-- Function to dataReportSetup, will upload sn, limitsVersion
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
function Process.dataReportSetup(param)
    flow_log.writeFlowLogStart(param)
    local interactiveView = Device.getPlugin("InteractiveView")
    local status, data = xpcall(interactiveView.getData, debug.traceback, Device.systemIndex)
    local sn = data --tostring(param.Input)
    Log.LogInfo("$$$$$ dataReportSetup sn " .. tostring(sn))
    if sn and #sn > 0 then
        Log.LogInfo("Unit serial number: " .. sn)
        DataReporting.primaryIdentity(sn)
        local limitsVersion = param.AdditionalParameters.limitsVersion
        if limitsVersion then
            DataReporting.limitsVersion("v0.0.0.1")
        end
        Log.LogInfo("Station reporter is ready.")
    end
    flow_log.writeFlowLimitAndResult(param, "ture")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000071_1.0
-- Process.addLogToInsight(param)
-- Function to  add user/ folder to systemArchive.zip,station can choose what file/folder to add by calling Archive.addPathName here.
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
function Process.addLogToInsight(param)
    Log.LogInfo('adding user/ log folder to insight')
    local slot_num = tonumber(Device.identifier:sub(-1))
    Archive.addPathName(Device.userDirectory, Archive.when.endOfTest)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000072_1.0
-- Process.setRTC(paraTab)
-- Function to set MLB time stamp
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
function Process.setRTC(paraTab)
    flow_log.writeFlowLogStart(paraTab)
    local dut = Device.getPlugin("dut")
    if dut.isOpened() ~= 1 then
        --Log.LogInfo("$$$$ dut.open")
        dut.open(2)
    end
    dut.setDelimiter("] :-)")
    local timeout_sub = 5
    if paraTab.AdditionalParameters.timeout ~= nil then
        timeout_sub = tonumber(paraTab.AdditionalParameters.timeout)
    end
    if paraTab.AdditionalParameters.mark ~= nil then
        xpcall(dutCmd.dutRead, debug.traceback, { Commands = "\r\n", Timeout = timeout_sub })
    end
    local result, rtc = xpcall(dut.setRTC, debug.traceback)
    Log.LogInfo("RTC>>>>", rtc)
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(paraTab, result)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000073_1.0
-- Process.forceDFUDischarge( paraTab )
-- Function to discharge when enter DFU mode
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
function Process.forceDFUDischarge(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    Log.LogInfo("***forceDfuDischarge******")
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 5000
    fixture.reset(slot_num)
    fixture.relay_switch("PPBATT_VCC_DISCHARGE", "CONNECT", slot_num)
    fixture.relay_switch("PPVCC_MAIN_DISCHARGE", "CONNECT", slot_num)
    fixture.relay_switch("PPV_BST_AUDIO_DISCHARGE", "CONNECT", slot_num)
    flow_log.writeFlowLog("PPBATT_VCC_DISCHARGE CONNECT")
    flow_log.writeFlowLog("PPVCC_MAIN_DISCHARGE CONNECT")
    flow_log.writeFlowLog("PPV_BST_AUDIO_DISCHARGE CONNECT")

    os.execute("sleep 2")

    fixture.relay_switch("PPBATT_VCC_DISCHARGE", "DISCONNECT", slot_num)
    fixture.relay_switch("PPVCC_MAIN_DISCHARGE", "DISCONNECT", slot_num)
    fixture.relay_switch("PPV_BST_AUDIO_DISCHARGE", "DISCONNECT", slot_num)
    flow_log.writeFlowLog("PPBATT_VCC_DISCHARGE DISCONNECT")
    flow_log.writeFlowLog("PPVCC_MAIN_DISCHARGE DISCONNECT")
    flow_log.writeFlowLog("PPV_BST_AUDIO_DISCHARGE DISCONNECT")
    os.execute("sleep 1")

    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000074_1.0
-- Process.setDFUCondition( paraTab )
-- Function to set condition for enter DFU mode
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
function Process.setDFUCondition(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(paraTab)
    Log.LogInfo("***dfu_set***")
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLog("***dfu_set***")
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local func_str = fixture.set_dfu_mode(slot_num)
    flow_log.writeFlowLog(func_str)
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, "ture")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000075_1.0
-- Process.detectDCConnected( paraTab )
-- Function to use dock channel check mlb into "Dock Channel Connected" mode
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
function Process.detectDCConnected(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    dock_port.setDetectString("Dock Channel Connected", slot_num, port)
    local st = dock_port.waitForString(5000, slot_num, port)
    flow_log.writeFlowLog("==============>>>>>>>>>>  " .. tostring(st))
    local result = false
    if tonumber(st) ~= 0 then
        for i = 1, 5 do
            fixture.relay_switch("VDM_CC1", "DISCONNECT", slot_num)
            flow_log.writeFlowLog("VDM_CC1 DISCONNECT")
            os.execute("sleep 0.5")
            fixture.relay_switch("VDM_CC1", "TO_ACE_CC1", slot_num)
            flow_log.writeFlowLog("VDM_CC1 TO_ACE_CC1")
            os.execute("sleep 1")
            dock_port.writeString("\r\n", slot_num, port)
            dock_port.writeString("\r\n", slot_num, port)
            dock_port.setDetectString("Dock Channel Connected", slot_num, port)
            st = dock_port.waitForString(5000, slot_num, port)
            if tonumber(st) == 0 then
                result = true
                break
            end
        end
    else
        result = true
    end
    flow_log.writeFlowLog("[31337-recv] : " .. dock_port.readString(slot_num, port))
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, result)
    if result == false then
        error(testname .. "-" .. subtestname .. "-" .. subsubtestname .. "-fail")
    end
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000076_1.0
-- Process.detectENV( paraTab )
-- Function to use dock channel check mlb into "Entering recovery" mode
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
function Process.detectENV(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    local cmd = paraTab.Commands

    dock_port.setDetectString("Entering recovery mode", slot_num, port)
    local st = dock_port.waitForString(50000, slot_num, port)
    flow_log.writeFlowLog("Entering recovery mode==============>>>>>>>>>>  " .. tostring(st))
    local result = false
    if tonumber(st) ~= 0 then
        dock_port.writeString("\r", slot_num, port)
        dock_port.writeString("\r", slot_num, port)
        dock_port.setDetectString("]", slot_num, port)
        st = dock_port.waitForString(3000, slot_num, port)
        flow_log.writeFlowLog("==========Entering recovery mode========>2  " .. tostring(st))
        if tonumber(st) == 0 then
            dock_port.setDetectString("] :-)", slot_num, port)
            dock_port.writeString(cmd .. "\r", slot_num, port)
            local st = dock_port.waitForString(15000, slot_num, port)
            flow_log.writeFlowLog("==========Entering recovery mode========>3  " .. tostring(st))
            if tonumber(st) == 0 then
                result = true
            else
                result = false
            end
        end


    else

        dock_port.setDetectString("] :-)", slot_num, port)
        dock_port.writeString(cmd .. "\r", slot_num, port)
        local st = dock_port.waitForString(15000, slot_num, port)
        if tonumber(st) == 0 then
            result = true

        else
            dock_port.writeString("\r", slot_num, port)
            dock_port.writeString("\r", slot_num, port)
            dock_port.waitForString(5000, slot_num, port)
            local ret = dock_port.readString(slot_num, port)
            flow_log.writeFlowLog(ret)
            if string.find(ret, "%] %:%-%)") then
                result = true
            end

        end

    end
    flow_log.writeFlowLog(dock_port.readString(slot_num, port))
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, result)

    if result == false then
        error(testname .. "-" .. subtestname .. "-" .. subsubtestname .. "-fail")
    end

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000077_1.0
-- Process.delay(param)
--Function to do some delay with AdditionalParameters from Tech csv
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
function Process.delay(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    os.execute('sleep ' .. (tonumber(param.AdditionalParameters.delay) / 1000))
    flow_log.writeFlowLog('sleep ' .. (tonumber(param.AdditionalParameters.delay) / 1000))
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(param, "true")
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
end

return Process
