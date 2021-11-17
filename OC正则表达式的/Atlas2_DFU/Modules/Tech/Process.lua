local Process = {}
local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")
local Record = require("Matchbox/record")

myOverrideTable ={}
-- A new function Starts after this
-- Unique Function ID :  Microtest_000032_1.0
-- getSN
-- Function to get the serialNumber of MLB

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  void
-- Return Arguments : MLB serialNumber
myOverrideTable.getSN = function()
    local dut = Device.getPlugin("dut")
    local mlbSerialNumber = dut.mlbSerialNumber(3)
    Log.LogInfo("mlbSerialNumber>>>" .. comFunc.dump(mlbSerialNumber))
    return mlbSerialNumber
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000033_1.0
-- startCB
-- Function to start process control ,read SN, write and read the "imcomplete" to cb

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv
function Process.startCB(paraTab)
    local dutPluginName = paraTab.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(dutPluginName)..' not found.') end
    local category = paraTab.AdditionalParameters.category
    Log.LogInfo('Starting process control')
    if category ~= nil and category ~= '' then
        ProcessControl.start(dut, category)
    else
        ProcessControl.start(dut, myOverrideTable)
    end
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000034_1.0
-- finishCB
-- Function to finish process control, write and check the result cb of current station

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv
function Process.finishCB(paraTab)
    -- do not finish CB if not started.
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Log.LogInfo('Process control finished or not started; skip finishCB.')
        return
    end

    local dutPluginName = paraTab.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(paraTab.Input)..' not found.') end

    -- read Poison flag from Input
    local Poison = paraTab.Input
    if Poison == 'TRUE' then
        Log.LogInfo('Poison requested; poisoning CB.')
        ProcessControl.poison(dut, myOverrideTable)
    end
    Log.LogInfo('Finishing process control')
    ProcessControl.finish(dut, myOverrideTable)
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000035_1.0
-- dataReportSetup
-- Function to dataReportSetup, will upload sn, limitsVersion

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
function Process.dataReportSetup(paraTab)
    -- local interactiveView = Device.getPlugin("InteractiveView")
    -- local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    local sn = tostring(paraTab.Input)
    local limitsVersion = paraTab.AdditionalParameters.limitsVersion
    Log.LogInfo("$$$$$ dataReportSetup sn " .. tostring(sn))
    if sn and #sn > 0 then
        Log.LogInfo("Unit serial number: ".. sn)
        Log.LogInfo("Unit Limits Version: ".. limitsVersion)
        DataReporting.primaryIdentity(sn)
        DataReporting.limitsVersion(limitsVersion)
        Log.LogInfo("Station reporter is ready.")
        if paraTab.AdditionalParameters.subsubtestname then
            Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
        end
    end
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000036_1.0
-- UOPCheck
-- Function to do UOPCheck, will report error when failed.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv
function Process.UOPCheck(paraTab)
    -- waiting for amIOK is ready.
    os.execute("sleep 5")
    local InteractiveView = Device.getPlugin("InteractiveView")
    local failMsg = nil
    local result = true
    local status, res = xpcall(ProcessControl.amIOK, debug.traceback)
    Log.LogInfo("$$$$$$", res, "$$$$$$")

    if res then
        failMsg = string.match(res,"unit_process_check=(.*)\";")
        if failMsg then
            result = false
            paraTab.AdditionalParameters["message"] = failMsg
            local viewConfig = {
                         ["title"] = paraTab.AdditionalParameters["subsubtestname"],
                         ["message"] = paraTab.AdditionalParameters["message"],
                         ["button"] = { "OK" } 
                       }
            Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname, failMsg)
            InteractiveView.showView(Device.systemIndex, viewConfig)
            error(failMsg)
        end
    end  
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname, failMsg)
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000037_1.0
-- checkExpect
-- Function to check the expect value in the input string from tech csv

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
-- Return: "TRUE" if found else "FALSE".
function Process.checkExpect( paraTab )
    Log.LogInfo("enter checkExpect>>>")
    local ret = paraTab.Input
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
