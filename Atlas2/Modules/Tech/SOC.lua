local SOC = {}
local Log = require ("Matchbox/logging")
local Record = require("Matchbox/record")
local comFunc = require("Matchbox/CommonFunc")

local runShellCommand = Atlas.loadPlugin("RunShellCommand")

function SOC.UOPCheck(paraTab)
    local InteractiveView = Device.getPlugin("InteractiveView")
    local failMsg = nil
    local result = true
    local status, res = xpcall(ProcessControl.amIOK, debug.traceback)
    Log.LogInfo("$$$$ amIOK:", res)

    if res then
        failMsg = string.match(res,"unit_process_check=(.*)\";")
        if failMsg then
            result = false
            paraTab.AdditionalParameters["message"] = failMsg
            local viewConfig = {
                         ["title"] = paraTab.AdditionalParameters["subsubtestname"],
                         ["message"] = paraTab.AdditionalParameters["message"],
                         ["button"] = { "OK" } 
                       }
            Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname, failMsg)
            InteractiveView.showView(Device.systemIndex, viewConfig)
            error(failMsg)
        end
    end  
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname, failMsg)
end

function SOC.addLogToInsight(paraTab)
    Log.LogInfo('adding user/ log folder to insight')
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local vendor = fixturePlugin.getVendor()
    Log.LogInfo('$$$$ vendor:' .. vendor)
    runShellCommand.run("ditto -c -k --sequesterRsrc --keepParent /vault/Atlas/FixtureLog/".. vendor .. " " .. Device.userDirectory .. "/FixtureLog.zip")
    runShellCommand.run("cp -r ~/Library/Atlas2/Assets ".. Device.userDirectory)
    runShellCommand.run("cp -r ~/Library/Atlas2/Modules/Tech ".. Device.userDirectory)
    runShellCommand.run("rm -r ".. Device.userDirectory .. "/Assets/InteractiveView.bundle ".. Device.userDirectory .. "/Assets/PopupBundle.bundle " .. Device.userDirectory .. "/Assets/StatusCollection.bundle " .. Device.userDirectory .. "/Assets/parseDefinitions")
    runShellCommand.run("cp -r /vault/data_collection/test_station_config/gh_station_info.json " .. Device.userDirectory)
    local serialNumber = paraTab.Input
    if serialNumber ~= nil and #serialNumber > 0 then
        comFunc.runShellCmd("mv " .. Device.userDirectory .. "/uart.log ".. Device.userDirectory .. "/" .. serialNumber .. ".log")
    end
    local endOfDevice = nil
    if (Atlas.compareVersionTo("2.33") ~= Atlas.versionComparisonResult.lessThan) then
        endOfDevice = Archive.when.deviceFinish
    else
        endOfDevice = Archive.when.endOfTest
    end
    Archive.addPathName(Device.userDirectory, endOfDevice)
end

function SOC.setLimitsVersion(paraTab) 
    local prefix, suffix = string.match(paraTab.InputDict["TPVersion"],"(TP)(.+)")
    DataReporting.limitsVersion(tostring(prefix .. "_" .. paraTab.InputDict["CPRV"] .. "_" .. suffix .. paraTab.InputDict["NonRetestable"]))
end

function SOC.getEnvVersion(paraTab)
    local env = paraTab.AdditionalParameters["env"]
    local logPath = Device.userDirectory.."/uart.log"
    local runTest = Atlas.loadPlugin("RunTest")
    local ret = runTest.getEnvVersion(env, logPath)
    local expect = paraTab.AdditionalParameters["expect"]

    if comFunc.hasKey(ret, "version") then

        Log.LogInfo("$$$$$expect", expect)
        Log.LogInfo("$$$$$ret[version]", ret["version"])
        
        if expect ~= nil then
            if expect ~= ret["version"] and string.find(ret["version"], string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1") )== nil then

                Record.createBinaryRecord(false,paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,paraTab.AdditionalParameters["subsubtestname"],"The Env Version is not the same as expected!!!")
                error("The Env Version is not the same as expected!!!")
            end
        end

        DataReporting.submit(DataReporting.createAttribute(string.upper(env).."_VERSION", ret["version"]))
        Record.createBinaryRecord(true,paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,paraTab.AdditionalParameters["subsubtestname"])
    else
        Record.createBinaryRecord(false,paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,paraTab.AdditionalParameters["subsubtestname"],"Get Env Version fail!!!")
    end

    if comFunc.hasKey(ret, "date") then
        DataReporting.submit(DataReporting.createAttribute(string.upper(env).."_BUILD_TIME", ret["date"]))
    end

    return ret["version"]
end

function SOC.setHangStatus(paraTab)
    return "FALSE"
end

return SOC