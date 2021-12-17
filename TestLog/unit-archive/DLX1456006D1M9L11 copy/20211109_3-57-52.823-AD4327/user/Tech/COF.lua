local COF = {}
local InteractiveView = require("Tech/InteractiveView")
local Record = require("Matchbox/record")
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local fixture = require("Tech/Fixture")

local runTest = Device.getPlugin("runtest")
local dut = Device.getPlugin("dut")

function COF.checkUSBDisconnect( paraTab )
    Log.LogInfo("-----------Enter checkUSBDisconnect-----------")
    local errorCount = 0
    
    local paraDict = 
        { 
            expect = "--- Device DETACHED --- : locationID=0x[0-9A-Za-z]{8}",
            logPath = "/Users/gdlocal/Library/Logs/Atlas/active/atlas.log",
            omit = "0",
            byPASS = 0
        }

    local _,errorCount = xpcall(COF.checkError,debug.traceback,paraTab,paraDict)
    
    Log.LogInfo("$$$$ UART USB Disconnection Check - errorCount: " .. tostring(errorCount))   
end

function COF.checkError(paraTab,paraDict)
    local checkErrorCount = 0
    local log = paraDict["logPath"]
    Log.LogInfo("$$$$ Enter log:" .. tostring(log))
    
    local _,retTable = xpcall(runTest.checkError,debug.traceback,paraDict)
   
    Log.LogInfo("$$$$ check error(retTable):", comFunc.dump(retTable))
    checkErrorCount = retTable.Count["value"]
    Record.createParametricRecord(tonumber(checkErrorCount), paraTab.Technology, paraTab.AdditionalParameters["errorname"], paraTab.AdditionalParameters["subsubtestname"])

    Log.LogInfo("$$$$ checkErrorCount" .. tostring(checkErrorCount))
    return checkErrorCount
end

--------------- hang detect ----------------------------------
function COF.checkHang(paraTab)
    Log.LogInfo("$$$$ checkHang paraTab", comFunc.dump(paraTab))
    local hang = "FALSE"
    local errorMsg = paraTab.failureMessage

    if errorMsg and string.find(errorMsg, "Hang Detected") then
        hang = "TRUE" 
    end

    if hang == "TRUE" then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.AdditionalParameters["errorname"], paraTab.failSubSubTestName .. "_" .. paraTab.AdditionalParameters["subsubtestname"],"Dut is hang!!!")
    else
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.AdditionalParameters["errorname"], paraTab.failSubSubTestName .. "_" .. paraTab.AdditionalParameters["subsubtestname"])
    end

    return hang
end

function COF.EnterEnvFail( paraTab )
    --EnterEnv fail skip the following test and Re-power
    local status = xpcall(fixture.dut_power_on,debug.traceback,paraTab)
    Log.LogInfo("$$$$ fixture recycle status" .. tostring(status))
    if not status then
        error("Fixture re-power on fail!!!")
    end
    return "TRUE"
end

function COF.checkDutHang( paraTab )
    local hangtype = paraTab.AdditionalParameters["HangType"]
    local isHang = "FALSE"
    Log.LogInfo("$$$$ Enter check ".. hangtype .. "Hang: " .. paraTab.Input)
    if paraTab.Input == "FALSE" then
        _,isHang = xpcall(COF.checkHang,debug.traceback,paraTab)
        Log.LogInfo("$$$$ Is" .. hangtype .. "Hang? " .. isHang)

        if isHang == "TRUE" then
            if hangtype == "RBM" then
                local hangStatus,_ = xpcall(dut.send,debug.traceback,"cpu 0 cfe echo \"RBM: Are you hang?\"",10)
                if not hangStatus then 
                    paraTab.AdditionalParameters["message"] = "Suspected RBM Hang on Slot_" .. Device.identifier:sub(-1) .. "!!! Call EE engineer to collect data before clicking OK!!! (" .. paraTab.TestName .. ") HANG/PANIC"
                    paraTab.AdditionalParameters["subsubtestname"] = "RBM Hang ShowAlert"
                    InteractiveView.showAlert(paraTab)
                end
            elseif hangtype == "RTOS" then
                local hangStatus,_ = xpcall(dut.send,debug.traceback,"echo RTOS: Are you hang?",10)
                if not hangStatus then 
                    paraTab.AdditionalParameters["message"] = "Suspected PERTOS Hang on Slot_" .. Device.identifier:sub(-1) .. "!!! Call EE engineer to collect data before clicking OK, and click OK to start RTOS Stack Dump through Ctrl+Z!!! (" .. paraTab.TestName .. ") HANG/PANIC"
                    paraTab.AdditionalParameters["subsubtestname"] = "RTOS Hang ShowAlert"
                    InteractiveView.showAlert(paraTab)

                    local sendCtrlZ = xpcall(dut.send,debug.traceback,string.format("%c",26),10)
                    Log.LogInfo("$$$$ sendCtrlZ>>" .. tostring(sendCtrlZ))

                    if not sendCtrlZ then 
                        paraTab.AdditionalParameters["message"] = "Suspected RTOS Hang on Slot_" .. Device.identifier:sub(-1) .. " and CTRL+Z no response!!! Click OK to continue!!!"
                        paraTab.AdditionalParameters["subsubtestname"] = "Send Ctrl + Z"
                        InteractiveView.showAlert(paraTab)
                    end
                end
            end
            local status = xpcall(fixture.dut_power_on,debug.traceback,paraTab)
            Log.LogInfo("$$$$ fixture recycle status" .. tostring(status))
            if not status then
                error("Fixture re-power on fail!!!")
            end
        end
    end
    return isHang
end

return COF
