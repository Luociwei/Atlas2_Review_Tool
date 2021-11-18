-------------------------------------------------------------------
----***************************************************************
----Parser Functions
----Created at: 07/21/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------
-- require("plist")

local Parser = {}
local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")
local Record = require("Matchbox/record")

-- A new function Starts after this
-- Unique Function ID :  Microtest_000030_1.0
-- regexParseString
-- Function to Use the Regex to match value with the Input string, can support compare with VersionCompare with the comparekey
-- Create Binary Record with the result

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the match value
function Parser.regexParseString( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input
    if ret == nil then
        local log_device = paraTab.AdditionalParameters.log_device
        local log_path = Device.userDirectory .. '/../system/device.log'
        local Restore = require("Tech/Restore")
        if log_device == 'restore_device' then
            log_path = Restore.getRestoreDeviceLogPath()
        elseif log_device == 'restore_host' then
            log_path = Restore.getRestoreHostLogPath()
        elseif log_device == 'uart' then
            log_path = Device.userDirectory .. '/uart.log'
        end
        ret = comFunc.fileRead(log_path)
        Log.LogInfo("$$$$ parseFromLog log_path " .. tostring(log_path))
    end

    local result = true
    local failureMsg = ""
    local pattern = paraTab.AdditionalParameters.pattern
    if ret and #ret > 0 then
        local matchs = Regex.groups(ret, pattern, 1)
        if #matchs > 0 then
            ret = comFunc.trim(matchs[1][1])
            local removeAllSpaces = paraTab.AdditionalParameters.removeAllSpaces or "NO"
            if removeAllSpaces == "YES" then
                ret = string.gsub( ret, '\r', '' )
                ret = string.gsub( ret, '\n', '' )
                ret = string.gsub( ret, ' ', '' )
            end
            if ( paraTab.AdditionalParameters.attribute ) then
                DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
            end
            local subsubtestname = paraTab.AdditionalParameters.subsubtestname
            if paraTab.AdditionalParameters.comparekey ~= nil and result then
                local vc = require("Tech/VersionCompare")
                local key = paraTab.AdditionalParameters.comparekey
                local compareValue = vc.getVersions()[key]
                if compareValue and #compareValue > 0 then
                    if ret ~= compareValue then
                        result = false
                        failureMsg = 'compare failed'
                    end
                else
                    result = false
                    failureMsg = 'get compareValue failed'
                end
            end

            local target = paraTab.AdditionalParameters.target
            if target ~= nil and result then
                result = ret == target
                if not result then
                    failureMsg = "target value '" .. tostring(target) .. "' matched value: " .. tostring(ret)
                end
            end
        else
            result = false
            failureMsg = "parse failed"
        end
    else
        result = false
        failureMsg = "parse failed"
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,failureMsg)
    return ret
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000031_1.0
-- regexParseNumber
-- Function to Use the Regex to match value with the Input string, will get limits with subsubtestname and create the Parametric Record

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the match value
function Parser.regexParseNumber( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input
    local testname =  paraTab.Technology
    local subtestname = paraTab.TestName

    local limitTab = paraTab.limit
    local pattern = paraTab.AdditionalParameters.pattern

    local matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        ret = matchs[1][1]
        if ( paraTab.AdditionalParameters.factor ) then
            ret = tonumber(ret) * tonumber(paraTab.AdditionalParameters.factor)
        end
        if ( paraTab.AdditionalParameters.attribute ) then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, tostring(ret)) )
        end
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, paraTab.AdditionalParameters.subsubtestname,limit)
    else
        Record.createBinaryRecord(false, testname, subtestname, paraTab.AdditionalParameters.subsubtestname)
    end

    return tostring(ret)
end

return Parser
