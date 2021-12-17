local Process = {}
local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")
local Record = require("Matchbox/record")

myOverrideTable ={}


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000032_1.0
-- myOverrideTable.getSN()
-- Function to get the serialNumber of MLB
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : N/A
-- Output Arguments : string
-----------------------------------------------------------------------------------]]

myOverrideTable.getSN = function()
    local dut = Device.getPlugin("dut")
    local mlbSerialNumber = dut.mlbSerialNumber(3)
    Log.LogInfo("mlbSerialNumber>>>" .. comFunc.dump(mlbSerialNumber))
    return mlbSerialNumber
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000033_1.0
-- Process.startCB(paraTab)
-- Function to start process control ,read SN, write and read the "imcomplete" to cb
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU/SoC
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Process.startCB(paraTab)
    local dutPluginName = paraTab.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(dutPluginName)..' not found.') end
    local category = paraTab.AdditionalParameters.category
    Log.LogInfo('$$$$ Starting process control.')
    if category ~= nil and category ~= '' then
        ProcessControl.start(dut, category)
    else
        ProcessControl.start(dut, myOverrideTable)
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000034_1.0
-- Process.finishCB(paraTab)
-- Function to finish process control, write and check the result cb of current station
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU/SoC
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Process.finishCB(paraTab)
    -- do not finish CB if not started.
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Log.LogInfo('$$$$ Process control finished or not started; skip finishCB.')
        return
    end

    local dutPluginName = paraTab.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(paraTab.Input)..' not found.') end

    -- read Poison flag from Input
    -- local Poison = paraTab.Input
    -- if Poison == 'TRUE' then
    --     Log.LogInfo('$$$$ Poison requested; poisoning CB.')
    --     ProcessControl.poison(dut, myOverrideTable)
    -- end
    Log.LogInfo('$$$$ Finishing process control')
    ProcessControl.finish(dut, myOverrideTable)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000035_1.0
-- Process.dataReportSetup(paraTab)
-- Function to setup the dataReport
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU/SoC
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Process.dataReportSetup(paraTab)
    -- local interactiveView = Device.getPlugin("InteractiveView")
    -- local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    local sn = tostring(paraTab.Input)
    Log.LogInfo("$$$$$ dataReportSetup sn " .. tostring(sn))
    if sn and #sn > 0 then
        Log.LogInfo("Unit serial number: ".. sn)
        DataReporting.primaryIdentity(sn)
        Log.LogInfo("Station reporter is ready.")
        if paraTab.AdditionalParameters.limitsVersion then 
            local limitsVersion = paraTab.AdditionalParameters.limitsVersion
            Log.LogInfo("Unit Limits Version: ".. limitsVersion)
            DataReporting.limitsVersion(limitsVersion)
        end
        if paraTab.AdditionalParameters.subsubtestname then
            Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
        end
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,"Fail to get SN")
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000037_1.0
-- Process.checkExpect( paraTab )
-- Function to check the expect value from the input string or uart log
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : Jayson Ye
-- Modification Date : 22/09/2021
-- Current_Version : 1.1
-- Changes from Previous version : 1.0
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Process.checkExpect( paraTab )
    Log.LogInfo("enter checkExpect>>>")
    local ret = paraTab.Input
    if ret == nil then
        local uart_log_path = Device.userDirectory .. '/uart.log'
        ret = comFunc.fileRead(uart_log_path)
    end
    local subtestname = paraTab.TestName
    local expect = paraTab.AdditionalParameters.expect
    local failWhenNotFound = paraTab.AdditionalParameters.failWhenNotFound
    local result = "TRUE"
    if string.find(ret, expect) == nil then result = "FALSE" end
    if failWhenNotFound and failWhenNotFound == "YES" and result == "FALSE" then
        Record.createBinaryRecord(false, paraTab.Technology, subtestname, paraTab.AdditionalParameters.subsubtestname, expect .. " not find in response")
    else
        Record.createBinaryRecord(true, paraTab.Technology, subtestname, paraTab.AdditionalParameters.subsubtestname)
    end
    return result
end

return Process
