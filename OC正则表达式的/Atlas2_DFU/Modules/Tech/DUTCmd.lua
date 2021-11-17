-------------------------------------------------------------------
----***************************************************************
----DUT Action Functions
----Created at: 07/21/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------

local DUTCmd = {}

local parser = require("Tech/Parser")
local Log = require("Matchbox/logging")
local csvCommon = require("Matchbox/Matchbox")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")

-- A new function Starts after this
-- Unique Function ID :  Microtest_000007_1.0
-- sendCmd
-- Function to run dut command.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Reutrn :dut respose
function DUTCmd.sendCmd(paraTab, sendAsData, command)
    local hangTimeout = paraTab.AdditionalParameters["hangTimeout"]
    local channelPlugin = Device.getPlugin("channelPlugin")

    local sendCommand__inner = function ()
        local dutPluginName = paraTab.AdditionalParameters.dutPluginName
        local dut = nil
        if dutPluginName then
            dut = Device.getPlugin(dutPluginName)
        else
            dut = Device.getPlugin("dut")
        end
        if dut.isOpened() ~= 1 then
            Log.LogInfo("$$$$ dut.open")
            dut.open(2)
        end

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        else
            error("miss timeout")
        end

        local cmd = command or paraTab.Commands
        local cmdReturn = ""

        Log.LogInfo("Running sendCommand:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
        if cmd ~= nil then
            if hangTimeout ~= nil then
                if dut ~= nil then                   
                    log.LogInfo("Setting HangTimeout:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", HangTimeout: '" .. tostring(hangTimeout) .. "'")
                    channelPlugin.setHangTimeout(tonumber(hangTimeout))
                end
            end

            if cmd == "shutdown" then
                if paraTab.AdditionalParameters.shutdownDelimiter then
                    dut.setDelimiter(paraTab.AdditionalParameters.shutdownDelimiter)
                else
                    dut.setDelimiter("Waiting for VBUS removal before shutting down.")
                end
            end
            dut.write(cmd)
            cmdReturn = dut.read(timeout)
        end

        return cmdReturn
    end

    -- sendCommand__inner()
    local status, ret = pcall(sendCommand__inner)
    if hangTimeout ~= nil then
        channelPlugin.setHangTimeout(-1)
    end
    -- Log.LogInfo("sendCmd status .." .. tostring(status) ..'\n ret' .. ret)

    if not status then 
        if string.match(ret or "", "HangDetected") ~= nil then
            error("Hang Detected")
        end 
    end

    if not status then
        error("test failure, please check log details")
    end
    return ret
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000008_1.0
-- sendCmdAndCreateRecord
-- Function to Send command and create the binary record according to the response

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Reutrn :The match result of Regex or the whole response
function DUTCmd.sendCmdAndCreateRecord( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local targetindex = paraTab.AdditionalParameters.targetindex
    local failureMsg = ""
    local result = true
    local ret = nil
    local cmds = comFunc.splitString(paraTab.Commands, ';')

    if targetindex then
        targetindex = tonumber(targetindex)
    else
        targetindex = #cmds
    end
    local targetResp = ""

    for i=1,#cmds do
        result, ret = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab, 0, cmds[i])
        if not result and string.find(ret,'Hang Detected') ~= nil then 
            error(paraTab.Technology ..'-'.. paraTab.TestName ..'-'.. paraTab.AdditionalParameters.subsubtestname ..'-'.. "Hang Detected")
            return
        end
        if result and i == targetindex then
            targetResp = ret
        end
    end

    Log.LogInfo("$$$$ targetindex " .. tostring(targetindex))
    Log.LogInfo("$$$$ targetResp " .. tostring(targetResp))

    if #targetResp == 0 then result = false end
    ret = targetResp

    if paraTab.AdditionalParameters.pattern ~= nil then
        local Regex = Device.getPlugin("Regex")
        local pattern = paraTab.AdditionalParameters.pattern
        local matchs = Regex.groups(targetResp, pattern, 1)
        if matchs and #matchs > 0 and #matchs[1] > 0 then
            ret = matchs[1][1]
        else
            result = false
            failureMsg = 'match failed'
        end
    end

    if paraTab.AdditionalParameters.attribute ~= nil and result then
        DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
    end

    if paraTab.AdditionalParameters.comparekey ~= nil and result then
        local vc = require("Tech/VersionCompare")
        local key = paraTab.AdditionalParameters.comparekey
        local compareValue = vc.getVersions()[key]
        if compareValue and #compareValue > 0 then
            if ret ~= compareValue then
                result = false
                failureMsg = 'compare failed; expect [' .. compareValue .."]" .. "got [" .. ret .. "]"
            end
        else
            result = false
            failureMsg = 'get compareValue failed'
        end
    end

    local expect = paraTab.AdditionalParameters.expect
    if expect ~= nil and result then
        if string.find(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
            result = false
            failureMsg = "expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret)
        end
    end

    local target = paraTab.AdditionalParameters.target
    if target ~= nil and result then
        result = comFunc.trim(ret) == target
        if not result then
            failureMsg = "expected value '" .. tostring(target) .. "' response: " .. tostring(ret)
        end
    end

    local testname = paraTab.Technology
    local subtestname = paraTab.TestName

    local isparametric = paraTab.AdditionalParameters.isparametric or "NO"
    if isparametric == "YES" then
        if ( paraTab.AdditionalParameters.factor ) then
            ret = tonumber(ret) * tonumber(paraTab.AdditionalParameters.factor)
        end

        local limit = nil
        local limitTab = paraTab.limit
        if limitTab then
            limit = limitTab[subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
    else
        if subsubtestname then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname,failureMsg)
        end
    end

    return tostring(ret),targetResp
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000009_1.0
-- sendCmdAndCheckError
-- Function to Send command and report the error and power off the UUT if find the 'error' string from the response

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Reutrn :if no error return "PASS" ,else report error ,do stop on fail
function DUTCmd.sendCmdAndCheckError( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local has_error = false

    local result, ret = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab)

    if result then
        if string.find(string.lower(ret), "error") ~= nil then
            failureMsg = "dut report error"
            result = false
            has_error = true
        end
    else
        Log.LogError(tostring(ret))
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,failureMsg)
    if has_error then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "CMD Error Check")
        error(paraTab.Technology ..'-'.. paraTab.TestName ..'-'.. paraTab.AdditionalParameters.subsubtestname ..'-'.. "audio cmd error")
    end 
end

return DUTCmd
