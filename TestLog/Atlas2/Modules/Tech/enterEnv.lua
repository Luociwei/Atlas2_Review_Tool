-------------------------------------------------------------------
----***************************************************************
----enterEnv functions
----Created at: 07/01/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------
-- local dutCommChannelMux = require("Tech/dutCommMux")
local enterEnv = {}
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'
-------------------------------------------------------------------
----***************************************************************
---- Constants
----***************************************************************
-------------------------------------------------------------------
local ENV_UNKNOWN = "unknown"
local DIAGS_SHUTDOWN_MSG = "Waiting for VBUS removal before shutting down."
local IBOOT_PROMPT = "Entering recovery mode, starting command prompt"
local AUTO_BOOT_PROMPT = "Hit enter to break into the command prompt"
local ENV_TABLE = { "diags", "rtos", "rbm", "phleet", "fsboot", "iboot", "ibootPrompt", "fixture", ENV_UNKNOWN }
local ENV_PROMPT_TABLE = { ["diags"] = "] :-) ", ["rtos"] = "SEGPE>", ["rbm"] = " <-", ["phleet"] = "CPU0: ( Empty ) ok", ["fsboot"] = "# ", ["iboot"] = "[m]", ["ibootPrompt"] = "] ", ["fixture"] = "_done", [ENV_UNKNOWN] = ""}
local ENV_PROMPT_REGEX_TABLE = { ["diags"] = "%] :%-%)", ["rtos"] = "SEGPE>", ["rbm"] = "%->[%w%s]<%-", ["phleet"] = "CPU[%d]+: %( Empty %) ok", ["fsboot"] = "# ", ["iboot"] = "%[m%]", ["ibootPrompt"] = "%^%] $", ["fixture"] = "_done", [ENV_UNKNOWN ] = "" }
local ENV_ENTER_COMMAND_TABLE = { ["diags"] = "diags", ["rtos"] = "rtos", ["rbm"] = "rbm", ["phleet"] = "phleet", ["fsboot"] = "fsboot" }
local ENV_RESET_COMMAND_TABLE = { ["diags"] = "reset", ["rtos"] = "pmgr reset", ["rbm"] = "reset", ["phleet"] = "reset", ["iboot"] = "reset", ["fsboot"] = "reboot", [ENV_UNKNOWN] = "reset" }

-- @param: dut(ATKLuaPlugin) - plugin for communication
-- @param: targetEnv(string) - expected environment, breaks out when it's detected
-- @param: timeout(number) - time to stop detection when env is unknown
-- @return: env(string) - detected env, could be "unknown"

function enterEnv.detectEnv(dut, targetEnv, timeout)
    local envDetected = ENV_UNKNOWN
    local _detectEnv = function(cmd)
        local env = ENV_UNKNOWN
       
        local resp = nil
        
        if cmd then
            -- Write and Read
            -- dut.write(cmd)
            -- resp = dut.read(0.5, "\n")
            resp = dut.send(cmd,0.5)
        else
            -- Read only
            resp = dut.read(0.5)
        end
        Log.LogInfo("detectEnv cmd: '" .. tostring(cmd) .. "', resp: '"..resp.."'")
        
        for _, e in ipairs(ENV_TABLE)
        do
            local promptRegex = ENV_PROMPT_REGEX_TABLE[e]
            if promptRegex ~= nil and string.find(resp, promptRegex) ~= nil then
                env = e
                break
            end
        end

        Log.LogInfo("_detectEnv: detected "..env)
        return env
    end

    local startTime = os.time()
    local command = nil
    repeat
        local status, ret = xpcall(_detectEnv, debug.traceback, command)
        if status then
            -- Keep reading and no writing if data read successfully
            command = nil
            envDetected = ret
        else
            -- No response indicates DUT is in booted environment, sending "\n"
            command = "\n"
        end
        if targetEnv ~= nil and targetEnv == envDetected then
            break
        end
    until (envDetected ~= ENV_UNKNOWN or os.difftime(os.time(), startTime) >= timeout)

    return envDetected
end

-- @param: paraTab - table containing all values defined one tech csv line.
-- @return: bool(true) - return true if all actions performed successfully, otherwise errors out.

function enterEnv.enterEnv(paraTab)
    Log.LogInfo("Running enterEnv:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ". cmd: " ..tostring(paraTab.Commands))
    Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
    local fixturePower = paraTab.AdditionalParameters["FixturePower"]
    if fixturePower == nil then
        fixturePower = false
    else
        fixturePower = tonumber(fixturePower)
        if fixturePower == 1 then
            fixturePower = true
        else
            fixturePower = false
        end
    end

    local cmd = paraTab.Commands -- #Todo: env validation against supported envs
    if cmd == nil then
       error("Invalid parameter! Commands not defined")
    end
 
    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 60
    end

    local prompt = ENV_PROMPT_TABLE[cmd]
    if prompt == nil then
       error("Invalid parameter! Prompt not available for " .. cmd)
    end

    local envDetected = ENV_UNKNOWN
    -- local dut = nil
    -- local dutVar = dutCommChannelMux.getCurrentDataChannel(paraTab.thread)

    local dut = Device.getPlugin("dut")
    if dut.isOpened() ~= 1 then
       dut.setDelimiter("")
       dut.open(2)
       -- dut.syncCmdResp()
    end
    
    -- Do not append any suffix to command
    dut.setLineTerminator("")
    dut.setDelimiter("")
    local status, envDetected = xpcall(enterEnv.detectEnv, debug.traceback, dut, cmd, timeout)
    -- Restore default suffix to command
    dut.setLineTerminator("\n")

    Log.LogInfo("envDetected = " .. envDetected)

    if fixturePower and envDetected == "diags" and cmd ~= "diags" then
        dut.setDelimiter(DIAGS_SHUTDOWN_MSG)
        dut.send("shutdown", 1)
        os.execute("sleep 3")
    end

    if cmd ~= "diags" or cmd == "diags" and envDetected ~= cmd then
        if fixturePower then
            -- Todo: reboot DUT via fixture power control
        end

        -- reset DUT if detected env is not iboot
        if string.find(envDetected, "^iboot") == nil then
            local resetCMD = ENV_RESET_COMMAND_TABLE[envDetected]
            if resetCMD == nil then
                resetCMD = ENV_RESET_COMMAND_TABLE[ENV_UNKNOWN]
            end

            -- LogDebug("Setting delimiter before reset")
            dut.setDelimiter(ENV_RESET_COMMAND_TABLE[ENV_UNKNOWN])
            -- LogDebug("Sending reset command: " .. tostring(resetCMD))
            dut.write(resetCMD)
            dut.setDelimiter(ENV_PROMPT_TABLE["iboot"])
            xpcall(dut.read, debug.traceback, timeout)
        end
        
        -- Send cmd to enter target env which is not iboot
        if string.find(cmd, "^iboot") == nil then
            Log.LogInfo("Start to send command: " .. cmd)
            dut.setDelimiter(ENV_PROMPT_TABLE[ENV_UNKNOWN])
            -- Add sleep to fix command no response
            os.execute("sleep 0.5")

            local Utilities = Atlas.loadPlugin("Utilities") 
            local utils = require("utils")
            local cmdData = Utilities.dataFromHexString(utils.str2hex(cmd)) 
            local returnData = dut.sendData(cmdData, timeout) 
            -- resp = utils.hex2str(Utilities.dataToHexString(returnData))
            
            -- dut.write(cmd)

            if string.find(cmd, "fsboot") == nil then
                dut.setDelimiter(prompt)
                Log.LogInfo("Set prompt to " .. prompt)
                dut.readData(timeout)
            end
        end
    else
        Log.LogInfo("FINDME: DUT is already in " .. cmd .. "! Auto-passing enterENV...")
    end
    
    if string.find(cmd, "fsboot") == nil then
        dut.setDelimiter(prompt)
        Log.LogInfo("enterEnv OK. Set prompt to '" .. prompt .. "'. " .. paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
    else
        -- Waiting for NonUI
        xpcall(dut.close, debug.traceback)
        os.execute("sleep " .. tostring(timeout))
    end
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    return true
end

function enterEnv.getEnvVersion(paraTab)
    print(">>>>>>>>")
    comFunc = require("Matchbox/CommonFunc")
    local env = paraTab.AdditionalParameters["env"]
    local logPath = Device.userDirectory.."/uart.log"
    local runTest = Atlas.loadPlugin("RunTest")
    local ret = runTest.getEnvVersion(env, logPath)
    print(logPath)
    print(comFunc.dump(ret))
    
    if ret["result"] == 1 then
        Record.createBinaryRecord(true,paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,paraTab.AdditionalParameters["subsubtestname"])
    else
        Record.createBinaryRecord(false,paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,paraTab.AdditionalParameters["subsubtestname"])
    end
    
    if comFunc.hasKey(ret, "version") then
        local attr = DataReporting.createAttribute(string.upper(env).."_VERSION", ret["version"])
        DataReporting.submit(attr)
    end


    if comFunc.hasKey(ret, "date") then
        
       local attr = DataReporting.createAttribute( string.upper(env).."_BUILD_TIME", ret["date"])
       -- local attr = DataReporting.createAttribute("_BUILD_TIME", "ret")
        DataReporting.submit(attr)
    end
end

function enterEnv.setHangStatus(paraTab)
    return "FALSE"
end

return enterEnv
