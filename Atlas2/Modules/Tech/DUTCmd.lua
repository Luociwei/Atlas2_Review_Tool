local DUTCmd = {}

local parser = require("Tech/Parser")
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")
local runShellCommand = Atlas.loadPlugin("RunShellCommand")


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000007_1.0
-- DUTCmd.sendCmd(paraTab, sendAsData, command)
-- Function to send dut command and return the response
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU/SoC
-- Input Arguments : param table, number, string
-- Output Arguments : string(command response)
-----------------------------------------------------------------------------------]]
function DUTCmd.sendCmd(paraTab, sendAsData, command)
    local sendCommand__inner = function ()
        local dut = Device.getPlugin("dut")
        if dut.isOpened() ~= 1 then
            dut.open(2)
        end

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        else
            timeout = 5
        end

        local cmd = command or paraTab.Commands
        local cmdReturn = ""

        Log.LogInfo("$$$$ Running sendCommand:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")

        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))

        if cmd ~= nil then
            if cmd == "shutdown" then
                if paraTab.AdditionalParameters.shutdownDelimiter then
                    dut.setDelimiter(paraTab.AdditionalParameters.shutdownDelimiter)
                else
                    dut.setDelimiter("Waiting for VBUS removal before shutting down.")
                end
            end

            local hangTimeout = paraTab.AdditionalParameters["hangTimeout"]
            local delimiter = paraTab.AdditionalParameters["delimiter"] or "] :-) "
            if hangTimeout ~= nil then
                log.LogInfo("Setting HangTimeout:" .. paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", HangTimeout: '" .. tostring(hangTimeout) .. "'")
                hangTimeout = tonumber(hangTimeout)
                dut.write(cmd)
                cmd = string.gsub(cmd, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
                delimiter = string.gsub(delimiter, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
                local startTime = os.time()
                repeat
                    local status, ret = xpcall(dut.read, debug.traceback, hangTimeout, '')
                    if status and ret and #ret > 0 then
                        cmdReturn = cmdReturn .. ret
                        local delimiterStartIndex = string.find(cmdReturn, delimiter)
                        if delimiterStartIndex ~= nil then
                            local cmdStartIndex = string.find(cmdReturn, cmd)
                            if cmdStartIndex and delimiterStartIndex > cmdStartIndex then
                                break
                            end
                        end
                    elseif string.find(ret, "Timed out trying to read") ~= nil then
                        error("HangDetected")
                    else
                        error(ret)
                    end
                until(os.difftime(os.time(), startTime) >= timeout)
            else
                dut.write(cmd)
                cmdReturn = dut.read(timeout)
            end
        end

        return cmdReturn
    end

    local status, ret = xpcall(sendCommand__inner, debug.traceback)

    if not status then 
        if string.match(ret or "", "HangDetected") ~= nil then
            error("Hang Detected")
        end 
    end

    -- Check if matches expect string
    local expect = paraTab.AdditionalParameters["expect"]
    
    if command == nil and expect ~= nil and string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
        status = false
        error("expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
    end

    if not status then
        error("test failure, please check log details")
    end
    return ret
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000008_1.0
-- DUTCmd.sendCmdAndCreateRecord( paraTab )
-- Function to Send command and create the binary record according to the response
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string, string
-----------------------------------------------------------------------------------]]

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

    local raiseErrorWhenFailed = paraTab.AdditionalParameters.raiseErrorWhenFailed
    if not result and raiseErrorWhenFailed and raiseErrorWhenFailed == "YES" then
        error(failureMsg)
    end

    return tostring(ret),targetResp
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000009_1.0
-- DUTCmd.sendCmdAndCheckError( paraTab )
-- Function to Send command and report the error and power off the UUT if find the 'error' string from the response
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
        if string.find(ret,'Hang Detected') ~= nil then
            has_error = true
            failureMsg = "Hang Detected"
        end
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,failureMsg)
    if has_error then
        error(failureMsg)
    end 
end


-- Send command, parse response with MD Parser and create records
-- @param paraTab: parameters from tech csv line(table)
-- @return: result(true/false)
function DUTCmd.sendAndParseCommand(paraTab)
    Timer.tick(paraTab.AdditionalParameters.subsubtestname)
    local stateForSendCmd,stateForParserCmd,stateForCreateRecord = true,true,true
    local resp = nil
    local cmd = paraTab.Commands
    local cmdExistFlag = cmd and cmd ~= "" and true or false
    local retData = nil

    -- Get DUT response
    stateForSendCmd, resp = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab)
    stateForParserCmd, retData = xpcall(parser.mdParse, debug.traceback, paraTab, resp)
       
    Log.LogInfo("$$$$ MD parse cmd:>>".. cmd .. comFunc.dump(retData))
    if cmd ~= "syscfg print MLB#" and string.sub(paraTab.TestName,1,2) ~= "B-" then
        -- pTab = {[1] = retData}
        stateForCreateRecord = parser.createRecordWithDataTable(paraTab, retData)
    end
    
    CMDTime = Timer.tock(paraTab.AdditionalParameters.subsubtestname)
    if paraTab.AdditionalParameters.parseKey then
        local parseKey = paraTab.AdditionalParameters.parseKey
        runShellCommand.run("mv " .. Device.userDirectory .. "/base_uart.log ".. Device.userDirectory .. "/" .. retData[parseKey] .. "_base_uart.log")
        return retData[parseKey]
    end
    result = stateForSendCmd and stateForParserCmd and stateForCreateRecord
    failMsg = raiseFailMsg(result, cmdExistFlag, stateForSendCmd, resp, stateForParserCmd, stateForCreateRecord)
    Record.createParametricRecord(tonumber(CMDTime), paraTab.Technology,  paraTab.AdditionalParameters["subsubtestname"], "TIME")
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.AdditionalParameters["subsubtestname"],"Result",failMsg)

    raiseError(result, cmdExistFlag, stateForSendCmd, resp, stateForParserCmd, stateForCreateRecord)

    return result
end


function DUTCmd.sendAndParseCommandWithPlugin(paraTab)
    Timer.tick(paraTab.AdditionalParameters.subsubtestname)
    local pluginVar = paraTab.AdditionalParameters.plugin or "SOCParser"
    local pluginFunc = paraTab.AdditionalParameters.pluginFunc or "parseSOC"
    local stateForSendCmd,stateForParserCmd,stateForCreateRecord = false,false,false
    local resp = nil
    local cmd = paraTab.Commands
    local cmdExistFlag = cmd and cmd ~= "" and true or false
    
    stateForSendCmd, resp= xpcall(DUTCmd.sendCmd, debug.traceback, paraTab)

    if pluginVar ~= nil and pluginFunc ~= nil then
        local pluginParser = Device.getPlugin(pluginVar)
        if string.sub(cmd, 0 , 5) ~= "exec " then
            stateForParserCmd, retData = xpcall(pluginParser[pluginFunc], debug.traceback, cmd, resp)
        else
            -- TODO
            local sequecePath = Atlas.assetsPath .. "/Tech/RTOS_exec.csv"
            Log.LogInfo("$$$$ sequecePath: ".. sequecePath)
            stateForParserCmd, retData = xpcall(pluginParser[pluginFunc], debug.traceback, cmd, resp, sequecePath)
        end
    end
    
    stateForCreateRecord = parser.createRecordWithDataTable(paraTab, retData)
    Timer.tock(paraTab.AdditionalParameters.subsubtestname)
    result = stateForSendCmd and stateForParserCmd and stateForCreateRecord
    failMsg = raiseFailMsg(result, cmdExistFlag, stateForSendCmd, resp, stateForParserCmd, stateForCreateRecord)
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.AdditionalParameters["subsubtestname"],"Result",failMsg)

    if paraTab.AdditionalParameters.parseKey then
        local parseKey = paraTab.AdditionalParameters.parseKey
        -- for _,v in ipairs(retData) do
        for k,v in pairs(retData) do
            if k == parseKey then
                return tostring(v)
            end
        end
        -- end
    end
    
    raiseError(result, cmdExistFlag, stateForSendCmd, resp, stateForParserCmd, stateForCreateRecord)
    return result
end

function raiseFailMsg( result, cmdExistFlag, stateForSendCmd, resp, stateForParserCmd, stateForCreateRecord )
    if not result then
        if not cmdExistFlag then
            failMsg = "NO COMMANDS DEFINED!!!"
        elseif not stateForSendCmd or resp == nil then
            failMsg = "SEND CMD FAILED OR EXPECTED STRING NOT FOUND!!!"
        elseif not stateForParserCmd then
            failMsg = "PARSE COMMAND FAILED!!!"
        elseif not stateForCreateRecord then
            failMsg = "CREATE RECORD FAIL!!!"
        end
    else
        failMsg = nil
    end
    return failMsg
end

function raiseError( result, cmdExistFlag, stateForSendCmd, resp, stateForParserCmd, stateForCreateRecord )
    if not result then
        if not cmdExistFlag then
            error("NO COMMANDS DEFINED")
        elseif not stateForSendCmd or resp == nil then
            error("SEND CMD FAILED OR EXPECTED STRING NOT FOUND: " .. tostring(resp))
        elseif not stateForParserCmd then
            error("PARSE COMMAND FAILED: " .. tostring(retData))
        elseif not stateForCreateRecord then
            error("CREATE RECORD FAIL")
        end
    end
end

return DUTCmd
