Common = {}
local Log = require("Matchbox/logging")
local dutCmd = require("Tech/DUTCmd")
local cof = require("Tech/COF")
local enterEnv = require("Tech/enterEnv")
local fixture = require("Tech/Fixture")
local parser = require("Tech/Parser")
local comFunc = require("Matchbox/CommonFunc")
local shell = require("Tech/Shell")
local Record = require 'Matchbox/record'

myOverrideTable ={} 
myOverrideTable.getSN = function()
    local dut = Device.getPlugin("dut")
    local mdParser = Device.getPlugin("MDParser")
    local cmdReturn = dut.send("syscfg print MLB#")
    print("cmdReturn>>>" .. tostring(cmdReturn))
    -- local res = string.match(cmdReturn,"syscfg print MLB# %s*(%w+)")
    local _,res = xpcall(mdParser.parse, debug.traceback,"syscfg print MLB#",cmdReturn)
    print("return>>>" .. comFunc.dump(res))
    return res.MLB_Num
end

function Common.startCB(param)
    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(dutPluginName)..' not found.') end
    local category = param.AdditionalParameters.category
    Log.LogInfo('Starting process control')
    if category ~= nil and category ~= '' then
        ProcessControl.start(dut, category)
    else
        ProcessControl.start(dut, myOverrideTable)
    end
end

function Common.finishCB(param)
    -- do not finish CB if not started.
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Log.LogInfo('Process control finished or not started; skip finishCB.')
        return
    end

    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(param.Input)..' not found.') end

    -- read Poison flag from Input
    local Poison = param.Input
    if Poison == 'TRUE' then
        Log.LogInfo('Poison requested; poisoning CB.')
        ProcessControl.poison(dut, myOverrideTable)
    end
    Log.LogInfo('Finishing process control')
    ProcessControl.finish(dut, myOverrideTable)
end

function Common.stationCommonLuaFunction(param)
    Log.LogInfo('Running station common lua function')
    return true
end

function Common.getSiteFromGHJson(paraTab)
    local StationInfo = Atlas.loadPlugin("StationInfo")
    local site = StationInfo.site()
    return site
end

function Common.dataReportSetup(param)
    local interactiveView = Device.getPlugin("InteractiveView")
    local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    local sn = ""
    Log.LogInfo("$$$$$ getSNFromInteractiveView" .. data)
    if status and #data == 17 then
        sn = data
    end
    Log.LogInfo("$$$$$ dataReportSetup" .. sn)
    if sn and #sn == 17 then
        Log.LogInfo("Unit serial number: ".. sn)
        DataReporting.primaryIdentity(sn)
        -- DataReporting.limitsVersion("v25.4.0.1_DOE")
        Log.LogInfo("Station reporter is ready.")
    end
end

-- As example, add user/ folder to systemArchive.zip
-- station can choose what file/folder to add by calling Archive.addPathName here.
function Common.addLogToInsight(param)
    Log.LogInfo('adding user/ log folder to insight')
    local runShell = Device.getPlugin("runShellCmd")
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    local recordsPath = Device.userDirectory .. "/../system/records.csv"
    local failedCount = shell.execute("/Users/gdlocal/Library/Atlas2/supportFiles/check_fail_records.py " .. recordsPath)
    Log.LogInfo("$$$$ failedCount " .. tostring(failedCount))
    if failedCount and tonumber(failedCount) > 0 then
        local get_rpc_server_log_resp = shell.execute("/usr/bin/expect /Users/gdlocal/Library/Atlas2/supportFiles/get_rpc_server_log.exp " .. tostring(slot_num-1) .. " /vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num))
        Log.LogInfo("$$$$ get_rpc_server_log_resp " .. tostring(get_rpc_server_log_resp))
        local status, resp = xpcall(runShell.run, debug.traceback, "cp -r /vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num) .. " " .. Device.userDirectory)
    end
    local status, resp = xpcall(runShell.run, debug.traceback, "cp -r /vault/Atlas/FixtureLog/Microtest ".. Device.userDirectory)
    Archive.addPathName(Device.userDirectory, Archive.when.endOfTest)
end

-- to demo retry feature
-- 1st call will fail with error; will pass when trying a given number of times, and this number is specified in param.Input
local counter = 0
function Common.failAndRetry(param)
    counter = counter + 1
    local numTotal = tonumber(param.Input)
    if counter < numTotal then
        error('counter==' .. counter .. ', error out')
    else
        Log.LogInfo('counter >= ' .. numTotal .. ': ' .. counter)
        counter = 0
        -- reset counter for next demo
    end
end

-- Tech function example to generate >= 2 variables in "Output".
function Common.multipleReturns(param)
    -- 1 and 2 is used later as p-record result;
    -- 'YES' is used as condition
    return 1, 2, 'YES'
end

function Common.getRestoreDeviceLogPath()
    local result = nil
    local retryTimes = 5
    repeat
        retryTimes = retryTimes - 1
        local files = shell.execute("ls " .. Device.userDirectory .. "/DCSD")
        result = string.match(files, "restore_device_[0-9_-]+%.log")
        comFunc.sleep(0.1)
    until(retryTimes < 0 or result ~= nil)
    return result
end

function Common.getRestoreHostLogPath()
    local result = nil
    local retryTimes = 5
    repeat
        retryTimes = retryTimes - 1
        local files = shell.execute("ls " .. Device.userDirectory .. "/DCSD")
        result = string.match(files, "restore_host_[0-9_-]+%.log")
        comFunc.sleep(0.1)
    until(retryTimes < 0 or result ~= nil)
    return result
end

-- pass if global var "deviceIndex" match current device index;
-- used to verify different DUT has its own global table in Init, Main and Teardown.csv.
function Common.checkDeviceIndex(param)
    local systemIndex = param.Input
    local record = require 'Matchbox/record'
    if systemIndex ~= Device.systemIndex then
        error('systemIndex check failed: ' .. tostring(systemIndex).. ' ~= ' .. Device.systemIndex)
    end
end

-- call in Init.csv to generate global varible storing device system index
-- this global var is verified in Main and Teardown to ensure each device is using its own
-- globals table.
function Common.setDeviceIndex(param)
    return Device.systemIndex
end

function Common.printVariable(param)
    print('Printing local variable: '..param.Input)
    if param.Input == nil then error() end
end

function Common.error(param)
    print('error out on purpose ')
    error()
end

-- Example: create record using information both from
-- 1. original fail tech line and
-- 2. fa tech line
function Common.createFARecord(param, globals, locals, conditions)
    local record = require 'Matchbox/record'
    local test = param.Technology
    local subtest = param.failTestName .. ' ' .. param.TestName
    local subsubtest = param.failsubsubtestname
    if param.AdditionalParameters.subsubtestname then
        subsubtest = subsubtest .. ' ' .. param.AdditionalParameters.subsubtestname
    end
    record.createBinaryRecord(true, test, subtest, subsubtest)
end

function Common.sleep(param)
    print('sleep')
    os.execute("sleep " .. tonumber(param.AdditionalParameters["time"]))
    return true
end

function Common.disengageFixture(param)
    print('Disengage fixture')
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    fixturePlugin.fixture_disengage()
    return true
end

function Common.engageFixture(param)
    print('Engage fixture')
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    fixturePlugin.fixture_engage()
    return true
end

function Common.fixtureActionUponTeardown(param)

    print('Disengage fixture')
    local InteractiveView = Device.getPlugin("InteractiveView")
    local groupIndex = math.floor(Device.systemIndex/4) + 1
    -- local fixturePlugin = Device.getPlugin("FixturePlugin")
    -- fixturePlugin.fixture_open()
    -- fixturePlugin.fixture_disengage()
    
    -- local loopConfig =  InteractiveView.getLoopConfig()
    -- Log.LogInfo('loopConfig: ' .. tostring(loopConfig))

    -- local isLoopFinished = InteractiveView.isLoopFinished()
    -- local isLoopFinished = InteractiveView.isLoopFinished(groupIndex - 1)
    -- Log.LogInfo('groupIndex: ' .. tostring(groupIndex))
    
    -- Log.LogInfo('isLoopFinished: ' .. tostring(isLoopFinished))


    -- if tonumber(isLoopFinished) > 0 then
    --     print('Loop finished. Quiting Loop...')
    --     return true
    -- end
    
    print('Delay...' .. param.AdditionalParameters["delay"])
    os.execute("sleep " .. tonumber(param.AdditionalParameters["delay"]))

    -- print('Engage fixture')
    -- fixturePlugin.fixture_close()
    -- fixturePlugin.fixture_engage()
    return true
end


function Common.setRTC(paraTab)
    local dut = Device.getPlugin("dut")
    local result, rtc = xpcall(dut.setRTC,debug.traceback)
    print("RTC>>>>",rtc)
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)    
end

function Common.delay(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    os.execute('sleep ' .. ( tonumber(param.AdditionalParameters.delay)/1000) )
    if subsubtestname then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
end

function Common.returnUnsetString(param)
    return "UnSet"
end

function Common.getSNFromInteractiveView(param)
    local interactiveView = Device.getPlugin("InteractiveView")
    local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    Log.LogInfo("$$$$$ getSNFromInteractiveView" .. data)
    if not status or #data ~= 17 then
        data = "no scanned sn"
    end
    return data
end

function Common.checkStopTestFlag(param)
    local result= true 
    local flag = param.Input
    -- local flag,info = table.unpack(param.InputValues)
    if flag and string.lower(flag) == "true" then
        result = false
        stopTestInfo = param.InputValues[2]
        if stopTestInfo then
            error(stopTestInfo)
        else
            error('Unknown error')
        end
    end
    local subsubtestname = param.AdditionalParameters.subsubtestname
    if subsubtestname then
        Record.createBinaryRecord(result, param.Technology, param.TestName, param.AdditionalParameters.subsubtestname)
    end
end

function Common.versionCompare( paraTab )
    local key = paraTab.AdditionalParameters.compareKey
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local passnoshow = paraTab.AdditionalParameters.passnoshow
    local failureMsg = ""
    local inputDict = paraTab.InputDict
    local result = true

    if inputDict ~= nil then
        if key then
            local vc = require("Tech/VersionCompare")
            local versions = vc()[key]

            if not versions then
                result = false
                failureMsg = 'compare value not found'
                Record.createBinaryRecord(result, paraTab.Technology, subtestname, subsubtestname, failureMsg)
                return
            end


            if key == 'GrapeFW' then
                local touch_firmware = inputDict.TOUCH_FIRMWARE
                if touch_firmware ~= nil then
                    Log.LogInfo("TOUCH_FIRMWARE=" .. touch_firmware .. '\n')
                    Log.LogInfo("GrapeFW: " .. comFunc.dump(versions) .. '\n')
                    result = versions == touch_firmware
                else
                    result = false
                    failureMsg = 'value not found'
                end

            elseif key == 'BT FW' then
                local wifi_module = inputDict.WIFI_MODULE
                local bt_firmware = inputDict.BT_FIRMWARE
                if wifi_module ~= nil and bt_firmware ~= nil then
                    Log.LogInfo("WIFI_MODULE=" .. wifi_module .. '\n')
                    Log.LogInfo("BT_FIRMWARE=" .. bt_firmware .. '\n')
                    Log.LogInfo("BT FW: " .. comFunc.dump(versions) .. '\n')
                    result = false

                    for _, version in ipairs(versions) do
                        local arr = comFunc.splitString(version, '\t')
                        if string.find(arr[1], wifi_module) ~= nil and 
                            string.find(arr[2], bt_firmware) ~= nil then
                            Log.LogInfo("Match: " .. version .. '\n')
                            result = true
                            break
                        end
                    end
                else
                    result = false
                    failureMsg = 'value not found'
                end

            elseif key == 'WIFI FW' then
                local wifi_module = inputDict.WIFI_MODULE
                local wifi_firmware = inputDict.WIFI_FIRMWARE
                local wifi_nvram = inputDict.WIFI_NVRAM

                if wifi_module ~= nil and wifi_firmware ~= nil and wifi_nvram ~=nil then
                    Log.LogInfo("WIFI_MODULE=" .. wifi_module .. '\n')
                    Log.LogInfo("WIFI_FIRMWARE=" .. wifi_firmware .. '\n')
                    Log.LogInfo("WIFI_NVRAM=" .. wifi_nvram .. '\n')
                    Log.LogInfo("WIFI FW: " .. comFunc.dump(versions) .. '\n')
                    result = false
                    for _, version in ipairs(versions) do
                        local arr = comFunc.splitString(version, '\t')
                        if string.find(arr[1], wifi_module) ~= nil and 
                            string.find(arr[2], wifi_firmware) ~= nil and 
                            string.find(arr[3], wifi_nvram) ~= nil then
                            Log.LogInfo("Match: " .. version .. '\n')
                            result = true
                            break
                        end
                    end
                else
                    result = false
                    failureMsg = 'value not found'
                end
            elseif key == 'RTOS' then
                local rtos_version = inputDict.RTOS_Version
                if rtos_version ~= nil then
                    Log.LogInfo("rtos_version=" .. rtos_version .. '\n')
                    Log.LogInfo("RTOS: " .. comFunc.dump(versions) .. '\n')
                    result = rtos_version == versions
                else
                    result = false
                    failureMsg = 'value not found'
                end
            elseif key == 'RBMVersionList' then
                local rbm_version = inputDict.RBM_Version
                if rbm_version ~= nil then
                    Log.LogInfo("rbm_version=" .. rbm_version .. '\n')
                    Log.LogInfo("RBMVersionList: " .. comFunc.dump(versions) .. '\n')
                    rbm_version = string.gsub(rbm_version, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
                    result = false
                    for _, version in ipairs(versions) do
                        if string.find(version, rbm_version) ~= nil then
                            Log.LogInfo("Match: " .. version .. '\n')
                            result = true
                            break
                        end
                    end
                else
                    result = false
                    failureMsg = 'value not found'
                end
            else
                result = false
                failureMsg = 'key[' .. key .. '] error'
            end
        else
            result = false
            failureMsg = 'miss compareKey'
        end
    else
        result = false
        failureMsg = 'miss input value'
    end
    if not result or not passnoshow or passnoshow ~= "YES" then
        Record.createBinaryRecord(result, paraTab.Technology, subtestname, subsubtestname, failureMsg)
    end
end

function Common.parseFromLog( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local log_device = paraTab.AdditionalParameters.log_device
    local result = false
    local log_path = Device.userDirectory .. '/../system/device.log'
    if log_device == 'restore' then
        log_path = Common.getRestoreDeviceLogPath()
        if log_path ~= nil then 
            log_path = Device.userDirectory .. "/DCSD/".. log_path
        end
    elseif log_device == 'restore_host' then
        log_path = Common.getRestoreHostLogPath()
        if log_path ~= nil then 
            log_path = Device.userDirectory .. "/DCSD/".. log_path
        end
    elseif log_device == 'uart' then
        log_path = Device.userDirectory .. '/uart.log'
    end

    local log_content = comFunc.fileRead(log_path)
    Log.LogInfo("$$$$ parseFromLog log_path " .. tostring(log_path))
    Log.LogInfo("$$$$ parseFromLog log_content len " .. tostring(#log_content))
    if log_content then
        local pattern = paraTab.AdditionalParameters.pattern
        if pattern then
            local Regex = Device.getPlugin("Regex")
            local matchs = Regex.groups(log_content, pattern, 1)
            if matchs and #matchs > 0 and #matchs[1] > 0 then
                local ret = matchs[1][1]
                result = true
                if paraTab.AdditionalParameters.attribute then
                    DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
                end

                if paraTab.AdditionalParameters.expect then
                    if ret == paraTab.AdditionalParameters.expect then
                        result = true
                    else
                        result = false
                    end
                end
            else
                result = false
                failureMsg = 'match failed'
            end

        else
            result = false
            failureMsg = 'miss pattern'
        end
    else
        result = false
        failureMsg = 'read file content failed'
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname,failureMsg)
end

function Common.parseFromBuffer( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local result = false
    local inputValue = paraTab.Input
    if not inputValue and paraTab.AdditionalParameters.usedbuffer then
        local vt = Device.getPlugin("VariableTable")
        inputValue = vt.getVar(paraTab.AdditionalParameters.usedbuffer)
        Log.LogInfo("$$$$ parse from buffer " .. paraTab.AdditionalParameters.usedbuffer)
    end
    local ret = nil
    if inputValue then
        local pattern = paraTab.AdditionalParameters.pattern
        if pattern then
            local Regex = Device.getPlugin("Regex")
            local matchs = Regex.groups(inputValue, pattern, 1)
            if matchs and #matchs > 0 and #matchs[1] > 0 then
                ret = matchs[1][1]
                result = true
                if paraTab.AdditionalParameters.attribute then
                    DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
                end
                if paraTab.AdditionalParameters.expect then
                    if ret ~= paraTab.AdditionalParameters.expect then
                        result = false
                        failureMsg = "expect[".. paraTab.AdditionalParameters.expect .."]" .. " result:" .. ret
                    end
                end
            else
                failureMsg = "match failed"
            end
        else
            failureMsg = "miss pattern"
        end
    else
        failureMsg = "miss input value"
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname,failureMsg)
    return ret
end

function Common.getSFCURLFromGHJson()
    -- TODO: use StationInfo to do this
    local json = require("Matchbox/json")
    local ghStationInfo = json.decode(comFunc.fileRead("/vault/data_collection/test_station_config/gh_station_info.json"))
    local sfc_url = ghStationInfo.ghinfo.SFC_URL or ""
    return sfc_url
end

function Common.checkExpectFromLastResponse( paraTab )
    print("enter checkExpectFromLastResponse>>>")
    local ret = paraTab.Input
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local expect = paraTab.AdditionalParameters.expect
    if string.find(ret, expect) ~= nil then
        Record.createBinaryRecord(true, paraTab.Technology, subtestname, paraTab.AdditionalParameters.subsubtestname)
        return "PASS"
    else
        Record.createBinaryRecord(false, paraTab.Technology, subtestname, paraTab.AdditionalParameters.subsubtestname,"find error in response")
        return "FAIL"
    end
end

function Common.totalChannelCount( paraTab )
    local GroupTablePlugin = Device.getPlugin("GroupTablePlugin")
    GroupTablePlugin.setVar("totalChannelCount",tonumber(GroupTablePlugin.getVar("totalChannelCount")) + 1)
    Log.LogInfo("$$$$ CurrentChannelCount [" .. tostring(GroupTablePlugin.getVar("totalChannelCount")) .. "]")
end

function Common.syncForAllChannel( paraTab )
    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 150
    end
    local startTime = os.time()
    local GroupTablePlugin = Device.getPlugin("GroupTablePlugin")
    local totalChannelCount = tonumber(GroupTablePlugin.getVar("totalChannelCount"))
    GroupTablePlugin.setVar("readyChannelCount",tonumber(GroupTablePlugin.getVar("readyChannelCount")) + 1)
    repeat
        local readyChannelCount = tonumber(GroupTablePlugin.getVar("readyChannelCount"))
        if readyChannelCount >= totalChannelCount then
            return "PASS"
        end
        comFunc.sleep(1)
        Log.LogInfo("$$$$SyncForAllChannel readyChannelCount[" .. tostring(readyChannelCount) .. "] totalChannelCount[" .. tostring(totalChannelCount) .. "]")
    until(os.difftime(os.time(), startTime) >= timeout)
end

function Common.pluginOpen( paraTab )
    local pluginName = paraTab.AdditionalParameters.pluginName
    local pluginInstance = Device.getPlugin(pluginName)
    local status,ret = xpcall(pluginInstance.open,debug.traceback,3)
    Log.LogInfo("$$$$ ".. pluginName ..".open status" .. tostring(status) .. "ret " .. tostring(ret))
end


-------------- DFU ------------------------------------

function Common.dfu_sof( paraTab )
    print("enter dfu_sof>>>")
    return fixture.sendFixtureSlotCommand(paraTab)
end

function Common.regexParseString( paraTab )
     print("enter regexParseString>>>")
    return parser.regexParseString(paraTab)
end

function Common.regexParseNumber( paraTab )
     print("enter regexParseNumber>>>")
    return parser.regexParseNumber(paraTab)
end

function Common.sendCmdAndCreateRecord( paraTab )
     print("enter sendCmdAndCreateRecord>>>")
    return dutCmd.sendCmdAndCreateRecord(paraTab)
end

function Common.dut_read( paraTab )
     print("enter read>>>")
    return dutCmd.read(paraTab)
end

function Common.sendCmdAndCheckError( paraTab )
     print("enter sendCmdAndCheckError>>>")
    return dutCmd.sendCmdAndCheckError(paraTab)
end

function Common.writeAndRead( paraTab )
     print("enter writeAndRead>>>")
    return dutCmd.writeAndRead(paraTab)
end

function Common.enteriBoot( paraTab )
     print("enter enteriBoot>>>")
    return dutCmd.enteriBoot(paraTab)
end

function Common.enterDiags( paraTab )
     print("enter enterDiags>>>")
    return dutCmd.enterDiags(paraTab)
end

function Common.enterEnvMode( paraTab )
     print("enter enterEnvMode>>>")
    return dutCmd.enterEnvMode(paraTab)
end

function Common.restore_dfu_mode_check( paraTab )
    print("enter restore_dfu_mode_check>>>")
    local restore = require("Tech/Restore")
    return restore.restore_dfu_mode_check(paraTab)
end

function Common.relay_switch( paraTab )
    print("enter relay_switch>>>")
    return fixture.relay_switch(paraTab)
end

function Common.read_voltage( paraTab )
    print("enter read_voltage>>>")
    return fixture.read_voltage(paraTab)
end

function Common.read_gpio( paraTab )
    print("enter read_gpio>>>")
    return fixture.read_gpio(paraTab)
end



-------------- Send Cmd function ----------------------

function Common.sendAndParseCommandWithPlugin( paraTab )
    return dutCmd.sendAndParseCommandWithPlugin(paraTab)
end

function Common.sendAndParseCommandWithRegex( paraTab )
    return dutCmd.sendAndParseCommandWithRegex(paraTab)
end


function Common.sendAndParseCommand( paraTab )
    return dutCmd.sendAndParseCommand(paraTab)
end

function Common.sendData(paraTab)
    return dutCmd.sendData(paraTab)
end

function Common.sendFixtureSlotCommand(paraTab)
    return fixture.sendFixtureSlotCommand(paraTab)
end


-----------------------------------  FA sequence  ----------------------------------------

function Common.checkUSBDisconnect( paraTab )
    return cof.checkUSBDisconnect(paraTab)
end

function Common.checkUnitPanicForRBM( paraTab )
    return cof.checkUnitPanicForRBM(paraTab)
end

function Common.checkUnitPanicForRTOS( paraTab )
    return cof.checkUnitPanicForRTOS(paraTab)
end

function Common.getFanStatus( paraTab )
    return cof.getFanStatus(paraTab)
end

function Common.failureWithProcessControl( paraTab )
    return cof.failureWithProcessControl(paraTab)
end

function Common.checkResponseError( paraTab )
    return cof.checkResponseError(paraTab)
end

function Common.failureBucket( paraTab )
    return cof.failureBucket(paraTab)
end

function Common.checkHang( paraTab )
    return cof.checkHang(paraTab)
end


----------------------------------  finish Process Control ---------------------------  

function Common.enterEnv( paraTab )
    return enterEnv.enterEnv(paraTab)
end

function Common.zipLog( paraTab )
    return cof.zipLog(paraTab)
end



return Common