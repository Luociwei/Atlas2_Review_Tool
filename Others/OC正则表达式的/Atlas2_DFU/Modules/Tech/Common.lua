Common = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")
local mutex = require("mutex")

local SKIP_FILE_LIST = {"Common.lua"}
local techPath = string.gsub(Atlas.assetsPath, "Assets", "Modules/Tech")
local runShellCommand = Atlas.loadPlugin('RunShellCommand')
local comFunc = require("Matchbox/CommonFunc")
local techFiles = runShellCommand.run("ls ".. techPath).output
Log.LogDebug("file list: ", techFiles)
local techFileList = comFunc.splitBySeveralDelimiter(techFiles,'\n\r')
for i, file in ipairs(techFileList) do
    if not comFunc.hasVal(SKIP_FILE_LIST, file) then
        Log.LogInfo("file: ", file)
        local requirePath = "Tech/"..file:match("(.*)%.lua")
        local lib = require(requirePath)
        for name, func in pairs(lib) do
            Common[name] = function (params)
                params.Commands = params.varSubCmd()
                params.AdditionalParameters = params.varSubAP()
                return func(params)
            end
        end
    end
end

-- Unique Function ID :  Microtest_000001_1.0
-- mutexDelay
-- Function to do mutex delay

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv
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

-- A new function Starts after this
-- Unique Function ID :  Microtest_000002_1.0
-- getSiteFromGHJson
-- Function to get the cm site from ghStationInfo.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
-- Return : value of CM site from gh_station_info.json 
function Common.getSiteFromGHJson(paraTab)
    local StationInfo = Atlas.loadPlugin("StationInfo")
    local site = StationInfo.site()
    return site
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000003_1.0
-- delay
-- Function to do some delay with AdditionalParameters delay

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
function Common.delay(paraTab)
    local testname = paraTab.Technology
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    os.execute('sleep ' .. ( tonumber(paraTab.AdditionalParameters.delay)/1000) )
    if subsubtestname then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000004_1.0
-- sfcQuery
-- Function to query the attribute with key from SFC.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
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

-- A new function Starts after this
-- Unique Function ID :  Microtest_000005_1.0
-- valueCompare
-- Function to compare two value from paraTab.InputValues[1] and paraTab.InputValues[2]

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
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