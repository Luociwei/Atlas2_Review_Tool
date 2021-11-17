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
local utils = require("utils")

Parser.AttributeRecord = 0
Parser.ParametricRecord = 1
Parser.BinaryRecord = 2


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000030_1.0
-- Parser.regexParseString( paraTab )
-- Function to Use the Regex to match value with the Input string, can support compare with VersionCompare with the comparekey
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


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000031_1.0
-- Parser.regexParseNumber( paraTab )
-- Function to Use the Regex to match value with the Input string, will get limits with subsubtestname and create the Parametric Record
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
end


-- Parse response with MD Parser
-- @param paraTab: parameters from tech csv line(table)
-- @return: result(true/false), retData(string, table)
function Parser.mdParse(paraTab, resp)
    Log.LogInfo("--------- Running MD parser --------")
    Log.LogInfo("$$$$ Running MD parser resp" .. tostring(resp))

    local result = false
    result = resp and true or false

    -- Parse DUT response
    local retData = nil
    if result then
        local mdParser = Device.getPlugin("MDParser")
        result, retData = xpcall(mdParser.parse, debug.traceback, paraTab.Commands, resp)
    end

    if not result then
        error("PARSE COMMAND FAIL: " .. tostring(retData))
    end
    return retData
end

-- Create records based on paraTab, data table, attribute list and limit file
-- @param paraTab: tech csv parameters
-- @return true/false: result of creating records and failures records
function Parser.createRecordWithDataTable(paraTab, dataTable)
    Log.LogInfo("$$$$ subSubTestName>> dataTable>>",comFunc.dump(dataTable))
    local result = true

    if dataTable == nil then
        Log.LogError("$$$$ empty data table: " .. tostring(paraTab.Technology) .. ", " .. tostring(paraTab.TestName) .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
        return false
    end
    
    for pKey, pValue in pairs(dataTable) do
        local testName = tostring(paraTab.Technology)
        local subTestName = tostring(paraTab.TestName)
        local subSubTestName = paraTab.AdditionalParameters["subsubtestname"]
        local testNameSuffix = paraTab.testNameSuffix and tostring(paraTab.testNameSuffix) or ""
        local pResult = true
        local failMsg = nil
        local recordType = Parser.ParametricRecord
        -- Fetch limit
        local limit = Parser.fetchLimit(paraTab, pKey)
        subTestName = subSubTestName and tostring(subSubTestName) .. testNameSuffix or subTestName
        subSubTestName = tostring(pKey)

        if limit ~= nil and limit.upperLimit ~= nil and limit.lowerLimit ~= nil and type(limit.upperLimit) ~= type(limit.lowerLimit) then
            error("INVALID LIMIT DEFINITION")
        end

        if paraTab.AdditionalParameters.hasAttribute then
            local attributePath= "/Users/gdlocal/Library/Atlas2/supportFiles/Attributes.plist"
            local attributeTable = utils.loadPlist(attributePath)
            if comFunc.hasKey(attributeTable["Attributes"]["SOC"], pKey) then
                if paraTab.AdditionalParameters.needCombine then
                    subSubTestName = paraTab.AdditionalParameters.attributeName
                    pValue = paraTab.Input .. "_" .. pValue
                end
                recordType = Parser.AttributeRecord
            end
        end

        if recordType == Parser.AttributeRecord then
            DataReporting.submit(DataReporting.createAttribute(subSubTestName, tostring(pValue)))
        elseif recordType == Parser.ParametricRecord then
            Record.createParametricRecord(tonumber(pValue), testName, subTestName, subSubTestName, limit)
        else
            error("invalid record type, should be a number:" .. tostring(recordType))
        end
    end
    return result
end

-- fetch limits for specific test names
-- @param subTestName: Test name
-- @param subSubTestName: subsubtestname in tech csv
-- @param parseKey: parseKey for command
-- @return table: limit table for specified test names
function Parser.fetchLimit(paraTab, parseKey)
    local rtosTempArray = {"_tMAX", "_tMIN", "Dtemp", "Stemp"}
    if string.sub(paraTab.Commands, 0 , 6) == "sc run" then
        if comFunc.hasVal(rtosTempArray, string.sub(parseKey, -5 , -1)) then
            return paraTab.limit["rtosTempLimit"]
        end
    end

    if parseKey == "SOC_MAX_TEMPERATURE" then
        return paraTab.limit["rbmTempLimit"]
    end
end

return Parser
