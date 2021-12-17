local Common = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")
local mutex = require("mutex")

local runShellCommand = Atlas.loadPlugin('RunShellCommand')

local SKIP_FILE_LIST = {"Common.lua"}
local techPath = string.gsub(Atlas.assetsPath, "Assets", "Modules/Tech")
local techFiles = runShellCommand.run("ls ".. techPath).output
Log.LogInfo("$$$$ file list: ", techFiles)
local techFileList = comFunc.splitBySeveralDelimiter(techFiles,'\n\r')
for i, file in ipairs(techFileList) do
    if not comFunc.hasVal(SKIP_FILE_LIST, file) then
        local requirePath = "Tech/"..file:match("(.*)%.lua")
        local lib = require(requirePath)
        for name, func in pairs(lib) do
            Common[name] = function (paraTab)
                paraTab.Commands = paraTab.varSubCmd()
                paraTab.AdditionalParameters = paraTab.varSubAP()
                return func(paraTab)
            end
        end
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000001_1.0
-- Common.mutexDelay( paraTab )
-- Function to do mutex delay
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Common.mutexDelay( paraTab )
    local delay_time = paraTab.AdditionalParameters.time_s
    if delay_time ~= nil then
        delay_time = tonumber(delay_time)
    else
        delay_time = 10
    end
    function __delay_func( time_s )
        os.execute("sleep " .. time_s)
    end
    local mutexDelay_identifier = paraTab.AdditionalParameters.identifier or "mutex_delay"
    local mutexPlugin = Device.getPlugin("mutex")
    if mutexPlugin.isNewIdentifier(mutexDelay_identifier) == 1 then
        mutex.runWithLock(mutexPlugin, mutexDelay_identifier, __delay_func, 0)
    else
        mutex.runWithLock(mutexPlugin, mutexDelay_identifier, __delay_func, delay_time)
    end
    if paraTab.AdditionalParameters.subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000002_1.0
-- Common.getSiteFromGHJson(paraTab)
-- Function to get the CM site from ghStationInfo.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string
-----------------------------------------------------------------------------------]]

function Common.getSiteFromGHJson(paraTab)
    local StationInfo = Atlas.loadPlugin("StationInfo")
    local site = StationInfo.site()
    return site
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000003_1.0
-- Common.delay(paraTab)
-- Function to do some delay
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : Jayson Ye
-- Modification Date : 28/09/2021
-- Current_Version : 1.1
-- Changes from Previous version : 1.0
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Common.delay(paraTab)
    local time = tonumber(paraTab.AdditionalParameters["delay"])
    runShellCommand.run("sleep " .. tostring(time/1000))
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters["subsubtestname"]..paraTab.testNameSuffix)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000004_1.0
-- Common.sfcQuery( paraTab )
-- Function to query the attribute with key from SFC.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string
-----------------------------------------------------------------------------------]]

function Common.sfcQuery( paraTab )
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local sfc_key = paraTab.AdditionalParameters.sfc_key
    local sn = tostring(paraTab.Input)
    local result = false
    local failureMsg = ""
    local ret = ""
    if sn and #sn > 0 then
        if sfc_key then
            local sfc = Device.getPlugin("SFC")
            local sfc_resp = sfc.getAttributes( sn, {sfc_key} )
            Log.LogInfo("$$$$ sfc query " .. sfc_key)
            Log.LogInfo(comFunc.dump(sfc_resp))
            local sfc_value = sfc_resp[sfc_key]
            if sfc_value and sfc_value ~= "" then
                result = true
                ret = sfc_value
            else
                failureMsg = "sfc_key[" .. sfc_key .. "] query failed"
            end
        else
            failureMsg = "miss sfc_key in AdditionalParameters"
        end
    else
        failureMsg = "no input sn"
    end
    Record.createBinaryRecord(result, paraTab.Technology, subtestname, subsubtestname, failureMsg)
    return ret
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000005_1.0
-- Common.valueCompare( paraTab )
-- Function to compare paraTab.InputValues[1] with paraTab.InputValues[2]
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Common.valueCompare( paraTab )
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local value1 = paraTab.InputValues[1]
    local value2 = paraTab.InputValues[2]
    local result = false
    Log.LogInfo("valueCompare value1 " .. tostring(value1))
    Log.LogInfo("valueCompare value2 " .. tostring(value2))
    if value1 and value2 and value1 == value2 then
        result = true
    end
    Record.createBinaryRecord(result, paraTab.Technology, subtestname, subsubtestname)
end

return Common