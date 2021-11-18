-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------

local Smokey = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local dutCmd = require("Tech/DUTCmd")
local Record = require("Matchbox/record")

-- A new function Starts after this
-- Unique Function ID :  Microtest_000046_1.0
-- smokeyRunAndParse
-- Function to run and parse the DFU Smokey command, will power off the UUT if hang Detected and check the BBLib_Ver with VersionCompare file.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the response of smokey command.
function Smokey.smokeyRunAndParse(paraTab,globals,locals,conditions)
    local Regex = Device.getPlugin("Regex")
    local command = paraTab.Commands
    local testname = paraTab.Technology
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local status, response = xpcall(dutCmd.sendCmd, debug.traceback,paraTab)

    if not status and string.find(response,'Hang Detected') ~= nil then 
        Record.createBinaryRecord(false, testname, paraTab.TestName, subsubtestname .. " Hang Detected","Hang Detected")
        error(testname ..'-'.. paraTab.TestName ..'-'.. subsubtestname ..'-'.. "Hang Detected")
        return
    end
    Record.createBinaryRecord(true, testname, paraTab.TestName, subsubtestname)
    -- local response = dut.sendCmd(paraTab)


    local patternResult = "Sequence done[\\s\\S]*(Passed|Failed)"
    local testResult = Regex.groups(response,patternResult,1)
  
    -- local pattern = "\\[BBLOG\\]:\\s+BBLib(Version:)?\\s+(\\S+)"
    local pattern = "\\[BBLOG\\]:\\s+BBLib\\s+(\\S+)"
    local bblibgroupsResult = Regex.groups(response,pattern,1)
    if #bblibgroupsResult > 0 and #bblibgroupsResult[1] > 0 then
        BBLib_Ver = bblibgroupsResult[1][1]
        if BBLib_Ver then
            DataReporting.submit( DataReporting.createAttribute( "BBLib_Ver", BBLib_Ver) )
            local vc = require("Tech/VersionCompare")
            local key = "BBlib"
            local compareValue = vc.getVersions()[key]
            if compareValue and #compareValue > 0 then
                if BBLib_Ver ~= compareValue then
                    Record.createBinaryRecord(false, testname, paraTab.TestName, "BBLib_Ver",'compare failed; expect [' .. compareValue .."]" .. "got [" .. compareValue .. "]")
                else
                    Record.createBinaryRecord(true, testname, paraTab.TestName, "BBLib_Ver")
                end
            else
                Record.createBinaryRecord(false, testname, paraTab.TestName, "BBLib_Ver",'get compareValue failed')
            end
        end
    else
        Record.createBinaryRecord(false, testname, paraTab.TestName, "BBLib_Ver")
    end

    -- local pattern = "dfu results:\\s+(.+)\\s+=\\s+(.*)\\s+\\[min, max\\]\\s+=\\s+\\[([\\d\\w.-]+),([\\d\\w.-]+)\\]\\s+(pass|fail)"
    local pattern = "\\ndfu results:\\s+(.+)\\s+=\\s+(.*)\\s+\\[min, max\\]\\s+=\\s+\\[([\\d\\w.-]+),([\\d\\w.-]+)\\]\\s+(pass|fail)"
    local groupsResult = Regex.groups(response,pattern,1)
    Log.LogInfo("groups results:")
    Log.LogInfo(comFunc.dump(groupsResult))
    
    if type(groupsResult) == "table" and #groupsResult[1] > 0 then
        Log.LogInfo("groups results:----")
        for index, result in ipairs(groupsResult) do
            Log.LogInfo(comFunc.dump(result))
            local report = nil
            if result[1] and result[1] == 'BB_SNUM' then
                DataReporting.submit( DataReporting.createAttribute("BB_SNUM", result[2]))
            end
            if tonumber(result[2]) then
                report = DataReporting.createParametricRecord(tonumber(result[2]),testname,paraTab.TestName..paraTab.testNameSuffix,result[1])
                report.applyLimit(nil,tonumber(result[3]),tonumber(result[4]),nil)
            else 
                local patternVal = "^\\s*([\\d.E-]+)\\s+(\\w+)\\s*$"
                local res = Regex.groups(result[2], patternVal, 1)
                Log.LogInfo(comFunc.dump(res))
                if #res[1] > 0 then
                    report = DataReporting.createParametricRecord(tonumber(res[1][1]),testname,paraTab.TestName..paraTab.testNameSuffix,result[1])
                    report.applyLimit(nil,tonumber(result[3]),tonumber(result[4]),nil,res[1][2])
                else
                    if result[5] == "pass" then 
                        report = DataReporting.createBinaryRecord(true,testname,paraTab.TestName..paraTab.testNameSuffix,result[1])
                    else
                        report = DataReporting.createBinaryRecord(false,testname,paraTab.TestName..paraTab.testNameSuffix,result[1])
                    end
                end
            end
            DataReporting.submit(report)
        end
    end

    Record.createBinaryRecord(true, testname, paraTab.TestName, "Smokey_Hang_Check")
    if #testResult > 0 and #testResult[1] > 0 and testResult[1][1] == "Passed" then
        Record.createBinaryRecord(true,testname,paraTab.TestName,"Smokey_result")
    else
        Record.createBinaryRecord(false,testname,paraTab.TestName,"Smokey_result")
    end
    return response
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000047_1.0
-- smokeyPcieRun
-- Function to run PCIE Smokey command, will power off the UUT if hang Detected.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the response of smokey command.
function Smokey.smokeyPcieRun(paraTab,globals,locals,conditions)
    -- body
    local command = paraTab.Commands
    local testname = paraTab.Technology
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local Regex = Device.getPlugin("Regex")
    -- local timeout = paraTab.timeout
    -- local dut = Device.getPlugin("dut")
    -- local response = dut.send(command)

    local status, response = xpcall(dutCmd.sendCmd, debug.traceback,paraTab)

    if not status and string.find(response,'Hang Detected') ~= nil then 
        error(testname ..'-'.. subtestname ..'-'.. paraTab.AdditionalParameters.subsubtestname ..'-'.. "Hang Detected")
        return
    end

    local patternResult = "Sequence\\s+done[\\s\\S]*(Passed|Failed)"
    local testResult = Regex.groups(response,patternResult,1)

    if #testResult > 0 and #testResult[1] > 0 and testResult[1][1] == "Passed" then
        Record.createBinaryRecord(true,testname,subtestname,subsubtestname)
    else
        Record.createBinaryRecord(false,testname,subtestname,subsubtestname)
    end
    return response
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000048_1.0
-- smokeyPcieParse
-- Function to parse the pcie result with the subsubtestname and input String(the response of pcie command), will create the Parametric Record with the limit which difine on Limits.csv

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : nil
function Smokey.smokeyPcieParse(paraTab,globals,locals,conditions)
    -- body
    local testname = paraTab.Technology
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local Regex = Device.getPlugin("Regex")
    -- local timeout = paraTab.timeout
    local ret = paraTab.Input
    local limitTab = paraTab.limit
    local pattern = subsubtestname.."=([\\d.-]+)"
    local groupsResult = Regex.groups(ret,pattern,1)
    Log.LogInfo(comFunc.dump(groupsResult))
    if #groupsResult>0 and #groupsResult[1]>0 then
        local limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        Record.createParametricRecord(tonumber(groupsResult[1][1]),testname,subtestname..paraTab.testNameSuffix,subsubtestname,limit)
    else
        Record.createBinaryRecord(false,testname,subtestname..paraTab.testNameSuffix,subsubtestname)
    end
end

return Smokey
