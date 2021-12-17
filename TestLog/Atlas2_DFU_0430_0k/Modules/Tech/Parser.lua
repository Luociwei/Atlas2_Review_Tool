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
local env = require("env")
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'


Parser.AttributeRecord = 0
Parser.ParametricRecord = 1
Parser.BinaryRecord = 2
TESTNAME_CONNECTOR = "%^"

function Parser.regexParseString( paraTab )
    local Regex = Device.getPlugin("Regex")
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local ret = paraTab.Input

    local result = true
    local pattern = paraTab.AdditionalParameters.pattern
    local matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        if ( paraTab.AdditionalParameters.attribute ) then
            ret = matchs[1][1]
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, matchs[1][1]) )
        end

        local subsubtestname = paraTab.AdditionalParameters.subsubtestname
        local failureMsg = ""
        if paraTab.AdditionalParameters.comparekey ~= nil and result then
            local vc = require("Tech/VersionCompare")
            local key = paraTab.AdditionalParameters.comparekey
            local compareValue = vc()[key]
            local matched_value = matchs[1][1]
            if compareValue and # compareValue > 0 then
                if matched_value ~= compareValue then
                    result = false
                    failureMsg = 'compare failed'
                end
            else
                result = false
                failureMsg = 'get compareValue failed'
            end
        end
        Record.createBinaryRecord(result, paraTab.Technology, subtestname, subsubtestname, failureMsg)
    else
        Record.createBinaryRecord(false, paraTab.Technology, subtestname, paraTab.AdditionalParameters.subsubtestname,"parse failed")
    end

    return ret
end

function Parser.regexParseNumber( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName

    local limitTab = paraTab.limit
    -- Log.LogInfo("$$$$ paraTab limit results:")
    -- Log.LogInfo(comFunc.dump(paraTab.limit))
    local pattern = paraTab.AdditionalParameters.pattern

    local matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        local result = matchs[1][1]
        if ( paraTab.AdditionalParameters.attribute ) then
            ret = result
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, result) )
        end

        if ( paraTab.AdditionalParameters.factor ) then
            result = tonumber(result) * tonumber(paraTab.AdditionalParameters.factor)
        end
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(result),testname, subtestname, paraTab.AdditionalParameters.subsubtestname,limit)
    else
        Record.createBinaryRecord(false, testname, subtestname, paraTab.AdditionalParameters.subsubtestname)
    end
    return ret
end

-- Parse response with MD Parser
-- @param paraTab: parameters from tech csv line(table)
-- @return: result(true/false), pData(string, table)

function Parser.mdParse(paraTab, resp)
    Log.LogInfo("Running MD parser")

    local result = false
    local inputVar = paraTab.AdditionalParameters["Input"]

    if resp == nil then
        if inputVar ~= nil and inputVar ~= "" then
        -- if inputVar ~= nil and inputVar ~= "" and globalVarTab[inputVar] ~= nil then
            resp = globalVarTab[inputVar]
        else
            resp = globalVarTab["defaultOutput"]
        end
    end

    Log.LogInfo("Running MD parser resp" .. tostring(resp))

    result = resp and true or false

    -- Parse DUT response
    local pData = nil
    if result then
        local mdParser = Device.getPlugin("MDParser")
        result, pData = xpcall(mdParser.parse, debug.traceback, paraTab.Commands, resp)
    end

    if not result then
        error("test failure: " .. tostring(pData))
    end
    return pData
end

-- Create record with Parser.createRecordWithTable
-- @param paraTab: parameters from tech csv line(table)
-- @return: result(true/false)

function Parser.createRecord(paraTab)
    local result = false
    local inputVar = paraTab.AdditionalParameters["Input"]
    local input = nil
    if inputVar ~= nil and inputVar ~= "" and globalVarTab[inputVar] ~= nil then
        input = globalVarTab[inputVar]
    else
        input = globalVarTab["defaultOutput"]
    end
    result = input and true or false

    if type(input) ~= "table" then
        local paraName = paraTab.AdditionalParameters["paraName"]
        if paraName == nil then
            error("no paraName in parameter")
        end
        input = { [tostring(paraName)] = input } -- Add suffix to avoid duplication of records from Tech.lua
    end
    result = Parser.createRecordWithTable(paraTab, input)
    if not result then
        error("test failure")
    end
    return result
end

-- Create records based on data table
-- @param dataTable: data table with full definition of test names, limits, type...
-- @return true/false: result of creating records and failures records

function Parser.createRecordWithData(dataTable)
    if type(dataTable) ~= "table" then
        error("table expected for createRecordWithData: " .. tostring(dataTable))
    end

    local result = true

    -- Load attribute list
    -- local attributes = Parser.loadAttributes(env.ATTRIBUTE_FILE)

    for _, pData in ipairs(dataTable) do
        local testName = pData["testname"]
        local subTestName = pData["subtestname"]
        local subSubTestName = pData["subsubtestname"]
        local pResult = pData["result"]
        local value = pData["value"]
        local lowerlimit = pData["lowerlimit"]
        local relaxedlowerlimit = pData["relaxedlowerlimit"]
        local upperlimit = pData["upperlimit"]
        local relaxedupperlimit = pData["relaxedupperlimit"]
        local units = pData["units"]
        local priority = pData["priority"]
        local type = pData["type"]
        local failureMsg = pData["failuremessage"]
        local report = nil
        local nameTable = {}
        -- for k, v in pairs(pData) do
        --     print(k,v)
        -- end
        
        -- Create attribute record
        -- for i, v in ipairs(attributes) do
        --     if tostring(v) == tostring(subSubTestName) then
        --         DataReporting.getPrimaryReporter().submit(DataReporting.createAttribute(subSubTestName, value))
        --         break
        --     end
        -- end

        if pResult == true or string.lower(tostring(pResult)) == "pass" then
            pResult = true
        else
            pResult = false
        end

        if testName == nil or testName == "" then
            error("invalid data table, no testname defined: " .. tostring(testName))
        elseif subTestName == nil or subTestName == "" then
            nameTable = { testName }
        elseif subSubTestName == nil or subSubTestName == "" then
            nameTable = { testName, subTestName }
        else
            nameTable = { testName, subTestName, subSubTestName }
        end

        if type == Parser.AttributeRecord then
            report = DataReporting.createAttribute(subSubTestName, value)
        elseif type == Parser.BinaryRecord then
            report = DataReporting.createBinaryRecord(pResult, table.unpack(nameTable))
        elseif type == Parser.ParametricRecord then
            report = DataReporting.createParametricRecord(tonumber(value), table.unpack(nameTable))
            if report and lowerlimit ~= nil or upperlimit ~= nil or units ~= nil then
                report.applyLimit(tonumber(relaxedlowerlimit), tonumber(lowerlimit), tonumber(upperlimit), tonumber(relaxedupperlimit), units)
            end
        else
            error("invalid record type, should be 0, 1 or 2" .. tostring(type))
        end

        pResult = pResult and report.getResult() ~= 0

        if pResult == true then
            report.addFailureReason("")
        elseif failureMsg then
            report.addFailureReason(failureMsg)
        end

        pResult = xpcall(DataReporting.submit, debug.traceback, report) and pResult
        result = pResult and result
    end

    return result
end 



-- Create records based on paraTab, data table, attribute list and limit file
-- @param paraTab: tech csv parameters
-- @return true/false: result of creating records and failures records

function Parser.createRecordWithTable(paraTab, dataTable)
    print("subSubTestName>> paraTab>>",comFunc.dump(paraTab))
    local result = true

    if dataTable == nil then
        LogError("empty data table: " .. tostring(paraTab.Technology) .. ", " .. tostring(paraTab.TestName) .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
        return false
    end

    local pDataTab = {}

    for pKey, pValue in pairs(dataTable) do
        local pData = {}
        local testName = tostring(paraTab.Technology)
        local subTestName = tostring(paraTab.TestName)
        local subSubTestName = paraTab.AdditionalParameters["subsubtestname"]
        local testNameSuffix = paraTab.testNameSuffix and tostring(paraTab.testNameSuffix) or ""
        local pResult = true
        local report = nil

        -- Fetch limit
        local limit = Parser.fetchLimit(paraTab.limit, testName, subTestName, subSubTestName and tostring(subSubTestName) .. testNameSuffix .. " - " .. tostring(pKey) or tostring(pKey))
        if limit == nil then
            limit = {}
        end
        -- Reconstructing subTestName, subSubTestName
        -- Leave pKey as subSubTestName so no need to check which substring is attribute name from concatenated string with subTestName and subSubTestName when needs to create attribute
        subTestName = subSubTestName and subTestName .. " - " .. tostring(subSubTestName) .. testNameSuffix or subTestName
        
        -- subSubTestName = subSubTestName .. "_" .. tostring(pKey)
        subSubTestName = tostring(pKey)

        
        if limit.units == "string" then
            if pValue ~= limit.upperLimit then
                pResult = false
            end
            pData["type"] = Parser.BinaryRecord
        elseif limit.upperLimit == nil and limit.lowerLimit == nil then
            pData["type"] = Parser.ParametricRecord
        -- Limit is string
        elseif type(limit.upperLimit) == type("a") or type(limit.lowerLimit) == type("a") then
            -- Convert string to number here since it seems limits we get are always string when reading.
            if tonumber(limit.upperLimit) ~= nil or tonumber(limit.lowerLimit) ~= nil then
                pData["type"] = Parser.ParametricRecord
            elseif limit.upperLimit ~= nil and pValue == limit.upperLimit or limit.lowerLimit ~= nil and pValue == limit.lowerLimit then
                pResult = true
                pData["type"] = Parser.BinaryRecord
            else
                pData["type"] = Parser.BinaryRecord
                pResult = false
                result = false
            end
         -- Limit is number
        elseif type(limit.upperLimit) == type(1) or type(limit.lowerLimit) == type(1)  then
            pData["type"] = Parser.ParametricRecord
        else
            result = false
            error("Invalid limit definition")
        end

        local cmd = paraTab.Commands

        local rtosTempArray = {"_tMAX", "_tMIN", "Dtemp", "Stemp"}
        if string.sub(cmd, 0 , 6) == "sc run" then
            if comFunc.hasVal(rtosTempArray, string.sub(subSubTestName, -5 , -1)) then
                limit.upperLimit = 50.0
            end
        end

        if subSubTestName == "TEMPERATURE" then
            limit.upperlimit = 50.0
        end

        if string.sub(cmd, 0 , 10) == "sc run 129" then 
            if string.find(subSubTestName, "Eye_Height_mV") ~= nil or string.find(subSubTestName, "Eye Height (mV)") then
                --eyeHeightLowerLimit
                limit.upperlimit = 100.0
            elseif string.find(subSubTestName, "Eye_Width_Ratio") then 
                --eyeWidthRatioLowerLimit
                limit.upperlimit = 40.0
            elseif string.find(subSubTestName, "Eye Width UI ratio") then
                --eyeWidthUIRatioLowerLimit
                limit.upperlimit = 0.40
            end
        end

        pData["testname"] = testName
        pData["subtestname"] = subTestName
        pData["subsubtestname"] = subSubTestName
        pData["result"] = pResult
        pData["lowerlimit"] = limit.lowerLimit
        pData["upperlimit"] = limit.upperLimit
        pData["relaxedlowerlimit"] = limit.relaxedLowerLimit
        pData["relaxedupperlimit"] = limit.relaxedUpperLimit
        pData["units"] = limit.units
        pData["value"] = pValue

        table.insert(pDataTab, pData)

    end


    result = Parser.createRecordWithData(pDataTab) and result
    return result
end

-- fetch limits for specific test names
-- @param testName: Tech name
-- @param subTestName: Test name
-- @param subSubTestName: subsubtestname in tech csv
-- @return table: limit table for specified test names

function Parser.fetchLimit(limit, testName, subTestName, subSubTestName)
    if limit == nil then
        return nil
    end
    return limit[subSubTestName]
end

-- @param attributeFile: attribute file path
-- @return table: array of attributes

-- function Parser.loadAttributes(attributeFile)
--     local globals = Device.getPlugin('VariableTable')
--     local attributes = globals.getVar("attributes")

--     if attributes ~= nil then
--         return attributes
--     end

--     attributes = plistParse(attributeFile)

--     globals.setVar("attributes", attributes.attributes)
--     return attributes.attributes
-- end

-- Run shell command with RunShellCommand plugin's run() api
-- @param paraTab: parameters from tech csv line(table)
-- @return: result(true/false)

function Parser.runShellCommand(paraTab)
    Log.LogInfo("Running sendShellCommand:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
    Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))

    local cmd = paraTab.Commands
    if cmd == nil then
       error("Invalid parameter! Commands not defined")
    end

    local timeout = paraTab.Timeout
    if timeout ~= nil then
       timeout = tonumber(timeout)
    end

    local run = require('RunShellCommand')
    local status, resp = xpcall(run.run, debug.traceback, cmd)
    Log.LogInfo("RunShellCommand Resp: " .. tostring(resp.output .. "; stderr: " .. tostring(resp.error)))
    --local report = DataReporting.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters["subsubtestname"])
    --DataReporting.getPrimaryReporter().submit(report)

    return status
end



return Parser
