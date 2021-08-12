-------------------------------------------------------------------
----***************************************************************
----DUT Action Functions
----Created at: 07/21/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------

local ActionFunc = {}

local parser = require("Tech/Parser")
-- local dutCommChannelMux = require("Tech/dutCommMux")
-- local csvCommon = require("Tech/csvCommon")
local utils = require("utils")
local Log = require("Matchbox/logging")
local csvCommon = require("Matchbox/Matchbox")
local Record = require 'Matchbox/record'

-- Run DUT Command
-- @param paraTab: parameters from tech csv line(table)
-- @return: command response(string)

function ActionFunc.sendCmd(paraTab, sendAsData)
    local sendCommand__inner = function ()
        local dutPluginName = paraTab.AdditionalParameters.dutPluginName
        local dut = nil
        if dutPluginName then
            -- dut = Device.getPlugin("dut")
            dut = Device.getPlugin(dutPluginName)
        else
            dut = Device.getPlugin("dut")
        end
        local channelPlugin = Device.getPlugin("channelPlugin")
        if dut.isOpened() ~= 1 then
            Log.LogInfo("$$$$ dut.open")
            dut.open(2)
        end

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        else
            timeout = 5
        end

        local cmd = paraTab.Commands
        local cmdReturn = ""

        Log.LogInfo("Running sendCommand:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
        if cmd ~= nil then
            local hangTimeout = paraTab.AdditionalParameters["hangTimeout"]
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
            
            -- if sendAsData == nil or tonumber(sendAsData) == 0 then
                -- Send cmd and retrieve response as String
            dut.write(cmd)
            cmdReturn = dut.read(timeout)

            if hangTimeout ~= nil then
                if dut ~= nil then                   
                    channelPlugin.setHangTimeout(-1)
                end
            end

            -- Log.LogInfo("cmdReturn>>" .. tostring(cmdReturn))
            -- else
            --     -- Send cmd and retrieve response as Data, be sure to register Utilities plugin for device first.
            --     local Utilities = Device.getPlugin("Utilities")
            --     local cmdData = Utilities.dataFromHexString(utils.str2hex(cmd))
            --     local returnData = dut.sendData(cmdData, timeout)
            --     cmdReturn = utils.hex2str(Utilities.dataToHexString(returnData))

            -- end
        end

        return cmdReturn
    end

    -- sendCommand__inner()
    local status, ret = pcall(sendCommand__inner)
    -- Log.LogInfo("sendCmd status .." .. tostring(status) ..'\n ret' .. ret)

    if not status then 
        if string.match(ret or "", "HangDetected") ~= nil then
            error("Hang Detected")
        end 
    end

    -- Check if matches expect string
    local expect = paraTab.AdditionalParameters["expect"]
    if expect ~= nil and string.find(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
        status = false
        error("expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
    end

    if not status then
        error("test failure, please check log details")
    end
    return ret
end

-- function ActionFunc.read(paraTab)
--     local sendCommand__inner = function ()
--         local dut = Device.getPlugin("dut")
--         if dut.isOpened() ~= 1 then
--             dut.open(2)
--         end
--         local channelPlugin = Device.getPlugin("channelPlugin")

--         local timeout = paraTab.Timeout
--         if timeout ~= nil then
--             timeout = tonumber(timeout)
--         end

--         local cmd = paraTab.Commands
--         local cmdReturn = ""

--         Log.LogInfo("Running read:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. "', timeout: '" .. tostring(timeout) .. "'")
--         Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))

--         local hangTimeout = paraTab.AdditionalParameters["hangTimeout"]
--         if hangTimeout ~= nil then
--             if dut ~= nil then
--                 Log.LogInfo("Setting HangTimeout:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", HangTimeout: '" .. tostring(hangTimeout) .. "'")
--                 channelPlugin.setHangTimeout(tonumber(hangTimeout))
--             end
--         end

--         local delimiter = paraTab.AdditionalParameters["delimiter"]
--         if delimiter ~= nil then
--             dut.setDelimiter(delimiter)
--         end
--         cmdReturn = dut.read()
--         Log.LogInfo("Return>>" .. tostring(cmdReturn))
--     -- else
--         -- Send cmd and retrieve response as Data, be sure to register Utilities plugin for device first.
--         -- local Utilities = Device.getPlugin("Utilities")
--         -- local cmdData = Utilities.dataFromHexString(utils.str2hex(cmd))
--         -- local returnData = dut.sendData(cmdData, timeout)
--         -- cmdReturn = utils.hex2str(Utilities.dataToHexString(returnData))

--     -- end

--         return cmdReturn
--     end

--     -- sendCommand__inner()

--     local status, ret = xpcall(sendCommand__inner, debug.traceback)
--     local vt = Device.getPlugin("VariableTable")
--     vt.setVar("last", ret)

--     if not status then
--         if paraTab.AdditionalParameters["hangTimeout"] ~= nil then
--             vt.setVar("Hang_detect", "True")
--         end

--         error("sendCmd failed: " .. tostring(ret))
--     end



--     -- Check if matches expect string
--     local expect = paraTab.AdditionalParameters["expect"]
--     -- if expect ~= nil and string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
--     if expect ~= nil then
--         if string.match(ret, expect) ~= nil then
--             DataReporting.submit( DataReporting.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname) )
--         else
--             DataReporting.submit( DataReporting.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname) )
--             error("expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
--         end
--     end


--     if not status then
--         error("test failure, please check log details")
--     end
--     return ret
-- end


-- Run DUT Command and receive response as Data
-- @param paraTab: parameters from tech csv line(table)
-- @return: command response(string)
function ActionFunc.sendData(paraTab)
    return ActionFunc.sendCmd(paraTab, 1)
end

-- Send command, parse response with MD Parser and create records
-- @param paraTab: parameters from tech csv line(table)
-- @return: result(true/false)

function ActionFunc.sendAndParseCommand(paraTab)
    -- Get DUT response
    local result = false
    local resp = nil
    local cmd = paraTab.Commands
    local sendCommand = cmd and cmd ~= "" and true or false

    if not sendCommand then
        error("no Commands defined")
    end

    result, resp = xpcall(ActionFunc.sendCmd, debug.traceback, paraTab,1)

    -- Parse DUT response
    local pData = nil
    if not result or resp == nil then
        error("sendCmd failed: " .. tostring(resp))
    end

    result, pData = xpcall(parser.mdParse, debug.traceback, paraTab, resp)
    if not result then
        error("sendAndParseCommand failed: " .. tostring(pData))
    end
    
    comFunc = require("Matchbox/CommonFunc")
    print("MD parse cmd:>>".. cmd .. comFunc.dump(pData))

    -- if paraTab.AdditionalParameters.need_save_variables ~= false then
    --     local vt = Device.getPlugin("VariableTable")
    --     for k, v in pairs(pData) do
    --         vt.setVar(k, v)
    --     end
    -- end
    result = parser.createRecordWithTable(paraTab, pData)
    if not result then
        error("test failure")
    end

    -- local report = DataReporting.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters["subsubtestname"])
    -- DataReporting.submit(report)

    return result
end

-- Send command, parse response with LuaParser Module and create records
-- @param paraTab: parameters from tech csv line(table)
-- @return: result(true/false)

function ActionFunc.sendAndParseCommandWithRegex(paraTab)
    -- Get DUT response
    local result = false
    local resp = nil
    local cmd = paraTab.Commands
    local sendCommand = cmd and cmd ~= "" and true or false
 
    if not sendCommand then
        error("no Commands defined")
    end
 
    result, resp = xpcall(ActionFunc.sendCmd, debug.traceback, paraTab)
 
    -- Parse DUT response
    local pData = nil
    if not result or resp == nil then
        error("sendAndParseCommandWithRegex failed " .. tostring(resp))
    end
    
    if paraTab.AdditionalParameters["pattern"] == nil  then
        error("pattern not set")
    end
    
    -- Construct paraTab for csvCommon.parse
    local inputVar = "sendAndParseCommandWithRegex"
    local outputVar = paraTab.AdditionalParameters["Output"]
    local newParaTab = utils.clone(paraTab)
    newParaTab.paralist["Input"] = inputVar

    -- Workaround for csvCommon.parse before <rdar://problem/67799480> is fixed, since it's calling localVarTab declared in other files. 
    local globals = Device.getPlugin("VariableTable")
    globals.setVar(inputVar, resp)
    localVarTab = localVarTab and localVarTab or globals.list()
    result, pData = xpcall(csvCommon.parse, debug.traceback, newParaTab)
  
    if not result then
        error("sendAndParseCommandWithRegex failed: " .. tostring(pData))
    end

    if outputVar ~= nil then
        local output = localVarTab[tostring(outputVar)]
        pData = output and output or localVarTab["defaultOutput"]
    end
    
    if paraTab.AdditionalParameters.need_save_variables ~= false then
        local vt = Device.getPlugin("VariableTable")
        for k, v in pairs(pData) do
            vt.setVar(k, v)
        end
    end

    -- local report = DataReporting.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters["subsubtestname"])
    -- DataReporting.submit(report)

    return pData
end

function ActionFunc.sendAndParseCommandWithPlugin(paraTab)

    -- Get DUT response
    local pluginVar = "SOCParser"
    local pluginFunc = "parseSOC"
    local result = false
    local resp = nil
    local cmd = paraTab.Commands
    local sendCommand = cmd and cmd ~= "" and true or false

    if paraTab.AdditionalParameters["plugin"] then
        pluginVar = paraTab.AdditionalParameters["plugin"]
    end

    if paraTab.AdditionalParameters["pluginFunc"] then
        pluginFunc = paraTab.AdditionalParameters["pluginFunc"]
    end
    
    if not sendCommand then
        error("no Commands defined")
    end
    result, resp = xpcall(ActionFunc.sendCmd, debug.traceback, paraTab,1)

    if not result or resp == nil then
        error("Parse Cmd failed: " .. tostring(resp))
    end

    if string.sub(cmd, 0 , 5) == "exec " then
        print(resp)
    end
 
    if pluginVar ~= nil and pluginFunc ~= nil then
        local pluginParser = Device.getPlugin(pluginVar)
        if string.sub(cmd, 0 , 5) ~= "exec " then
            result, pData = xpcall(pluginParser[pluginFunc], debug.traceback, cmd, resp)
        else
            local sequecePath = Atlas.assetsPath .. "/Tech/RTOS_exec.csv"
            print("sequecePath: ".. sequecePath)

            result, pData = xpcall(pluginParser[pluginFunc], debug.traceback, cmd, resp, sequecePath)
        end
    else
        error("No plugin found!")
    end
    if not result then
        error("sendAndParseCommandWithPlugin failed: " .. tostring(pData))
    end
   

    result = parser.createRecordWithTable(paraTab, pData)
    if not result then
        error("test failure")
    end

    if paraTab.AdditionalParameters["attributeKey"] then csvCommon.createAttribute(paraTab) end

    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)    
    return result
end

function ActionFunc.sendCmdAndCreateRecord( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local passnoshow = paraTab.AdditionalParameters.passnoshow
    local failureMsg = ""
    local result = true
    local ret = nil

    result, ret = xpcall(ActionFunc.sendCmd, debug.traceback, paraTab)

    if not result and string.find(ret,'Hang Detected') ~= nil then 
        local fixture = require("Tech/Fixture")
        fixture.dut_power_off()
        error(paraTab.Technology ..'-'.. paraTab.TestName ..'-'.. paraTab.AdditionalParameters.subsubtestname ..'-'.. "Hang Detected")
        return
    end

    if #ret == 0 then result = false end

    if paraTab.AdditionalParameters.pattern ~= nil then
        local Regex = Device.getPlugin("Regex")
        local pattern = paraTab.AdditionalParameters.pattern
        local matchs = Regex.groups(ret, pattern, 1)
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
        local compareValue = vc()[key]
        if compareValue and # compareValue > 0 then
            if ret ~= compareValue then
                result = false
                failureMsg = 'compare failed'
            end
        else
            result = false
            failureMsg = 'get compareValue failed'
        end
    end

    -- had been judge during dut.sendCmd
    -- if paraTab.AdditionalParameters.expect ~= nil and result then
    --     if string.find(ret, paraTab.AdditionalParameters.expect) == nil then
    --         result = false
    --         subsubtestname = subsubtestname .. ' expect failed'
    --     end
    -- end
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    if subsubtestname and (not result or not passnoshow or passnoshow ~= "YES") then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname,failureMsg)
    end
    return ret
end



function ActionFunc.sendCmdAndCheckError( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local result = true
    local ret = nil
    local has_error = false

    result, ret = xpcall(ActionFunc.sendCmd, debug.traceback, paraTab)

    -- failSpec = {"ERROR", "Error", "error"}

    -- for _, spec in ipairs(failSpec) do
    --     if string.find(ret, spec) ~= nil then
    --         result = false
    --         has_error = true
    --         break
    --     end
    -- end

    if #ret == 0 then 
        failureMsg = "dut no response"
        has_error = true 
        result = false
    else
        if string.find(string.lower(ret), "error") ~= nil then
            failureMsg = "dut report error"
            result = false
            has_error = true
        end
    end

    if result and paraTab.AdditionalParameters.expect ~= nil then
        if string.find(ret, paraTab.AdditionalParameters.expect) == nil then
            failureMsg = "expect failed"
            result = false
        end
    end

    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,failureMsg)
    
    if has_error then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "CMD Error Check")
        local fixture = require("Tech/Fixture")
        fixture.dut_power_off()
        error(paraTab.Technology ..'-'.. paraTab.TestName ..'-'.. paraTab.AdditionalParameters.subsubtestname ..'-'.. "audio cmd error")
        return "DFU_SOF"
    else
        return "PASS"
    end 
end

function ActionFunc.writeAndRead( paraTab )
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"
    local store_buffer = paraTab.AdditionalParameters.storeBuffer

    if dut.isOpened() == 0 then
        dut.setDelimiter("")
        dut.open(2)
    end

    local startTime = os.time()
    local timeout = paraTab.Timeout

    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 5
    end

    local cmd = paraTab.Commands
    local content = ""
    if cmd ~= nil then
        dut.write(cmd)
    end

    local hangTimeout = paraTab.AdditionalParameters["hangTimeout"]
    if hangTimeout == nil then
        hangTimeout = 5    
    end

    local delimiter = paraTab.AdditionalParameters["delimiter"]
    if delimiter == nil then
        delimiter = "%] %:%-%)"
    end

    local lastRetTime = os.time()
    repeat
        local status, ret = xpcall(dut.read, debug.traceback, 0.1, '')
        local cmd_index = -1
        local delimiter_index = -1
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret

            if #content >0 then
                delimiter_index = string.find(content, delimiter)
                if cmd ~= nil and #cmd > 0 then
                    cmd_index = string.find(content, cmd)
                    if cmd_index and cmd_index>0 and delimiter_index and delimiter_index > cmd_index then
                        break
                    end
                else
                    if delimiter_index and delimiter_index > 0 then
                        break
                    end
                end
            end
        end
        if os.difftime(os.time(),lastRetTime) >= hangTimeout then
            -- DataReporting.submit(DataReporting.createBinaryRecord(result, parmTab.Technology, "hangTimeout", "detected"))
            -- vt.setVar("Hang_detect","TRUE")
            error("Hang Detected")
            break
            -- local fixture = Device.getPlugin("FixturePlugin")
            -- local slot_num = tonumber(Device.identifier:sub(-1)) + 1
            -- fixture.dut_power_off(slot_num)
            -- DataReporting.submit(DataReporting.createBinaryRecord(true, parmTab.Technology, "hangTimeout", "dut_power_off"))
            -- local viewConfig = {
            --     ["message"] = "uart hang detected"
            -- }
            -- vt.setVar("Restore_SOF","TRUE")
            -- InteractiveView.showView(Device.systemIndex, viewConfig)
            -- return "TRUE"
        end
    until(os.difftime(os.time(), startTime) >= timeout)
    -- if store_buffer then
    --     vt.setVar(store_buffer, content)
    -- end
    dut.setDelimiter(default_delimiter)
    return content
end

function ActionFunc.enterEnvMode( paraTab )
    local ENV_PROMPT_TABLE = { ["diags"] = "] :-) ", ["rtos"] = "SEGPE>", ["rbm"] = " <-", ["phleet"] = "CPU0: ( Empty ) ok", ["iboot"] = "[m]"}
    local env = paraTab.AdditionalParameters.env
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local passnoshow = paraTab.AdditionalParameters.passnoshow
    local ret = nil
    local result = true

    if env and ENV_PROMPT_TABLE[env] then
        local expect = ENV_PROMPT_TABLE[paraTab.AdditionalParameters.env]
        expect = string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
        result, ret = xpcall(ActionFunc.writeAndRead, debug.traceback, paraTab)
        
        if not result and string.find(ret,'Hang Detected') ~= nil then 
            local fixture = require("Tech/Fixture")
            Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"Hang Detected")
            fixture.dut_power_off()
            error(paraTab.Technology ..'-'.. paraTab.TestName ..'-'.. paraTab.AdditionalParameters.subsubtestname ..'-'.. "Hang Detected")
            return ret
        end

        if #ret >0 then
            local index = string.find(ret, expect)
            if index and index > 0 then
                local dut = Device.getPlugin("dut")
                dut.setDelimiter(ENV_PROMPT_TABLE[env])
                if not passnoshow or passnoshow ~= "YES" then
                    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName,subsubtestname,"")
                end
            else
                Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"cannot find expect")
            end
        else
            Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"dut no response")
        end

    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"miss env")
    end
    return ret
end

return ActionFunc
