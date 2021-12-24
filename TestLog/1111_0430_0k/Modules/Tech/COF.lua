-------------------------------------------------------------------
----***************************************************************
----Action Functions
----Created at: 07/21/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------

local Temp = {}


gErrorCountRTOS = 0
gErrorCountRBM = 0
gErrorCount2 = 0
gErrorCount3 = 0
failureCount = 0
hasEverFailed = true


-- local processControl = require("Tech/ProcessControl")
local enterEnv = require("Tech/enterEnv")
local parser = require("Tech/Parser")
local popup = require("Tech/InteractiveView")
local record = require("Matchbox/record")
local Log = require("Matchbox/logging")
local runTest = Device.getPlugin("runtest")
local dut = Device.getPlugin("dut")
local InteractiveView = Device.getPlugin("InteractiveView")
local x = require("Matchbox/CommonFunc")
local UICount = 0

local systemDirectory = string.gsub(Device.userDirectory,'user','system')
local paraDictUnitPanic = 
           { expect = "1",
            logPath = systemDirectory .. '/' .. "device.log",
            byPASS = 1
           }

function Temp.failureBucket( paraTab )
    print("Enter FailureBucket>>>>>>",x.dump(paraTab))
    
    local unitLog = "device.log"
    local uartLog = "uart.log"
    local resetPattern = "pmu: flt ([abcdef\\d]+):[abcdef\\d]+"
    local hangPattern = "(UNIT\\s+PANIC)"

    local status0,res = xpcall(runTest.failureBucket,debug.traceback,unitLog,uartLog,resetPattern,hangPattern)
    print("End FailureBucket>>>>>>"..tostring(status0)..tostring(res))

    DataReporting.submit(DataReporting.createParametricRecord(tonumber(res.failureBucket), paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters["subsubtestname"] .. "_" ..paraTab.failSubSubTestName))

    -- res = { ["failureBucket"] = -2,}
end


function Temp.checkUSBDisconnect( paraTab )
    print("Enter checkUSBDisconnect>>>>>>")
    local errorCount0 = 0
    
    local paraDict = 
        { expect = "8",
          logPath = "uart.log",
          omit = "0",
          byPASS = 1
        }

    local status0,errorCount0 = xpcall(Temp.checkError,debug.traceback,paraTab,"Uart USB disconnection check",paraDict)
    
    Log.LogInfo("UART USB Disconnection Check - errorCount0: " .. tostring(errorCount0))

    
end


function Temp.checkUnitPanicForRBM( paraTab )
    print("Enter checkUnitPanicForRBM>>>>>>",paraTab.Input)
    if paraTab.Input == "FALSE" then
        local errorCountRBM = 0
        local _,errorCountRBM = xpcall(Temp.checkError,debug.traceback,paraTab,"UNIT PANIC",paraDictUnitPanic)
        errorCountRBM = tonumber(errorCountRBM) - 2  -- discard debug info
        print("errorCountRBM???",errorCountRBM)

        if errorCountRBM > gErrorCountRBM then

        local _,hangResp = xpcall(dut.send,debug.traceback,"cpu 0 cfe echo \"RBM: Are you hang?\"",10)

            if hangResp ~= "Are you hang?" then 
                UICount = UICount + 1
                paraTab.AdditionalParameters["message"] = "Suspected RBM Hang on Slot_" .. Device.systemIndex .. "!!! Call EE engineer to collect data before clicking OK, and click OK to start RTOS Stack Dump through Ctrl+Z!!! (" .. paraTab.TestName .. "HANG/PANIC"
                paraTab.AdditionalParameters["subsubtestname"] = "RBM Hang UI _" .. UICount
                popup.showAlert(paraTab)

            end
        end

        Log.LogInfo("Previous, global errorCountRBM: " .. tostring(gErrorCountRBM))

        gErrorCountRBM = tonumber(errorCountRBM) + 3

        Log.LogInfo("Now, global errorCountRBM: " .. tostring(gErrorCountRBM))

    end
end


function Temp.checkUnitPanicForRTOS( paraTab )
    print("Enter checkUnitPanicForRTOS>>>>>>",paraTab.Input)
    if paraTab.Input == "FALSE" then
        local errorCountRTOS = 0
        local _,errorCountRTOS = xpcall(Temp.checkError,debug.traceback,paraTab,"UNIT PANIC",paraDictUnitPanic)

        errorCountRTOS = tonumber(errorCountRTOS) - 2  -- discard debug info
        print("errorCountRTOS???",errorCountRTOS)

        if errorCountRTOS > gErrorCountRTOS then

        local _,hangResp = xpcall(dut.send,debug.traceback,"echo RTOS: Are you hang?",10)

            if hangResp ~= "PASS echo" then 
                UICount = UICount + 1
                paraTab.AdditionalParameters["message"] = "Suspected PERTOS Hang on Slot_" .. Device.systemIndex .. "!!! Call EE engineer to collect data before clicking OK, and click OK to start RTOS Stack Dump through Ctrl+Z!!! (" .. paraTab.TestName .. "HANG/PANIC"
                paraTab.AdditionalParameters["subsubtestname"] = "RTOS Hang UI _" .. UICount
                popup.showAlert(paraTab)

                print("sendCtrlZ>>")
                local sendCtrlZ = xpcall(dut.send,debug.traceback,string.format("%c",26),10)

                if not sendCtrlZ then 
                    paraTab.AdditionalParameters["message"] = "Suspected RTOS Hang on Slot_" .. Device.systemIndex .. " and CTRL+Z no response!!! Click OK to continue!!!"
                    paraTab.AdditionalParameters["subsubtestname"] = "Send Ctrl + Z _" .. UICount
                    popup.showAlert(paraTab)
                end

            end
        end

        Log.LogInfo("Previous, global errorCountRTOS: " .. tostring(gErrorCountRTOS))

        gErrorCountRTOS = tonumber(errorCountRTOS) + 3

        Log.LogInfo("Now, global errorCountRTOS: " .. tostring(gErrorCountRTOS))

    end

end


function Temp.checkSC184Failure( paraTab )
    local errorCountSC184 = 0
    local paraDict184 = 
     { expect = "strings to parse is empt",
       logPath = "device.log",
       byPASS = 1
     }
    local _,errorCountSC184 = xpcall(Temp.checkError,debug.traceback,paraTab,"Response Error Check",paraDict184)
    paraTab.Output = errorCountSC184
    return errorCountSC184
end


function Temp.checkResponseError( paraTab )
    print("Enter checkResponseError>>>>>>")
    local errorCount2 = 0
    local paraDict2 = 
     { 
        expect = "ERROR",
       logPath = "device.log",
       byPASS = 1
     }
    local _,errorCount2 = xpcall(Temp.checkError,debug.traceback,paraTab,"Response Error Check",paraDict2)
    print("errorCount2>>>>>",errorCount2)
    errorCount2 = tonumber(errorCount2) - 2

    if errorCount2 > gErrorCount2 then
        paraTab.AdditionalParameters['COF'] = 1
    end

    Log.LogInfo("Previous, global errorCount2: " .. tostring(gErrorCount2))

    gErrorCount2 = tonumber(errorCount2) + 3

    Log.LogInfo("Now, global errorCount2: " .. tostring(gErrorCount2))
    
end


function Temp.checkError(paraTab,subTestname,paraDict)
    local checkErrorCount = 0
    local checkError_inner = function ()
        local result = false
        local log = paraDict["logPath"]
        print("Enter log>>" .. tostring(log))

        -- local logPath = Device.userDirectory .. "/" .. paraDict["logPath"]
        -- paraDict["logPath"] = logPath
        -- print("Enter logPath>>" .. tostring(logPath))
        
        local retTable = runTest.checkError(paraDict)
        print("x.dump(retTable)")
        print(x.dump(retTable))
        
        if paraTab.failSubSubTestName then
            DataReporting.submit(DataReporting.createParametricRecord(tonumber(retTable.Count["value"]), paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters["subsubtestname"] .. "_" .. paraTab.failSubSubTestName))
        else
            DataReporting.submit(DataReporting.createParametricRecord(tonumber(retTable.Count["value"]), paraTab.Technology, paraTab.TestName,subTestname))
        end

        checkErrorCount = retTable.Count["value"]

    end
    local status = xpcall(checkError_inner, debug.traceback)
    if not status then
        error("checkError ERROR!")
    end

    print("checkError finish??????",checkErrorCount)
    
    return checkErrorCount
end


---------------- FA common function ---------------------------------------

function Temp.getFanStatus( paraTab )
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local slotNum = tonumber(Device.identifier:sub(-1)) + 1
    local fixtureStatus = fixturePlugin["isFanOk"](slotNum)
    print("isFanOK>>>",fixtureStatus)
    -- if not fixtureStatus then Log.LogError("FanCheck Failed!!") end
end



--------------- finishProcessControl ----------------------------------

function Temp.zipLog(paraTab)
    local paraDict1 = 
       { expect = "3",
         logPath = "device.log",
         byPASS = 1
       }

    local cpCheck = pcall(Temp.checkError,paraTab,"CP Error Check",paraDict1)

    local paraDict2 = 
       { expect = "\\(TestProcess\\).*<Error>.*name",
         logPath = "device.log"
       }

    local status,gErrorCount3 = xpcall(Temp.checkError,debug.traceback,paraTab,"Response Error Check",paraDict2)
    print("status>>",tostring(status))
    if status then
        if tonumber(gErrorCount3) < 0 or tonumber(gErrorCount3) > 1 then
            Log.LogError("value:" .. tostring(gErrorCount3) .. "exceeds limit: [0,1]")
            paraTab.Output = "TRUE"
        end
    end

    local zipLog_inner = function()

        local runShell = Device.getPlugin("runShellCmd")
        local fanStatus = xpcall(Temp.getFanStatus,debug.traceback,paraTab)
        if not fanStatus then Log.LogError("FanCheck Failed!!") end

        local rmFixture = xpcall(runShell.run,debug.traceback,"rm /vault/Atlas/FixtureLog/FixtureLog.zip")
        if not rmFixture then Log.LogError("rm System Call Failed!!!") end

        local zipFixture = xpcall(runShell.run,debug.traceback,"zip -r /vault/Atlas/FixtureLog/FixtureLog.zip /vault/Atlas/FixtureLog")
        if not zipFixture then Log.LogError("zip System Call Failed!!!") end

        os.execute('sleep 3')
    end

    local res = xpcall(zipLog_inner,debug.traceback)
    DataReporting.submit(DataReporting.createBinaryRecord(res, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters["subsubtestname"]))

    --Use Utilities Plugin to upload TP to PDCA 

end



--------------- hang detect ----------------------------------
function Temp.checkHang(paraTab)
    print("checkHang paraTab",x.dump(paraTab))
    local hang = "FALSE"
    local errorMsg = paraTab.failureMessage
    print("errorMsg???",errorMsg)
    if errorMsg and string.find(errorMsg, "Hang Detected") then  hang = "TRUE" end

    DataReporting.submit(DataReporting.createBinaryRecord(true, paraTab.Technology, "FA_" .. paraTab.failSubSubTestName, paraTab.AdditionalParameters["subsubtestname"] .. "_" .. hang))
    return hang
end


return Temp
