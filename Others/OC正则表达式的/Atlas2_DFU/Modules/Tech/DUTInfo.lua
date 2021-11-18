-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------

local DUTInfo = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")


-- A new function Starts after this
-- Unique Function ID :  Microtest_000010_1.0
-- writeICTCB
-- Function to Query the ICT result from SFC according to the SN, and then write ICT CB.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Reutrn :bool, pass or fail
function DUTInfo.writeICTCB( paraTab )
    local sn = tostring(paraTab.Input)
    Log.LogInfo("$$$$ sn"..sn)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    if sn == nil or sn == '' then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"no input sn")
        return
    end
    
    local dut = Device.getPlugin("dut")
    local failureMsg = ""
    local result = true
    offset = 0x0a
    local sfc = Device.getPlugin("SFC")
    local sfc_result = sfc.getAttributesByStationType( sn, "ICT", {"result"})
    Log.LogInfo("$$$$ sfc_result")
    Log.LogInfo(comFunc.dump(sfc_result))
    local ict_result = sfc_result['result']

    if ict_result and #ict_result > 0 then
        if ict_result == 'PASS' then
            local nonce = dut.getNonce(offset)
            local password = Security.signChallenge(tostring(offset), nonce)
            if password then
                dut.writeCB(offset, 0, password, 'MT')
            else
                result = false
                failureMsg = 'get password failed'
            end
            -- resp = dut.readCBStatus(offset)
            -- result = resp == 0
            -- DataReporting.submit( DataReporting.createBinaryRecord( result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname) )
        else
            local ict_flag = 2
            if string.lower(ict_result) == 'incomplete' then
                ict_flag = 1
            elseif string.lower(ict_result) == 'untested' then
                ict_flag = 3
            end
            -- 1 incomplete 
            -- 2 fail
            -- 3 untested
            dut.writeCB(offset, ict_flag, nil, 'MT')
        end
    else
        result = false
        failureMsg = 'query result failed'
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname, failureMsg)
    return result
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000011_1.0
-- writeAndCompareSN
-- Function to write the scanned sn to UUT, and then read the sn from UUT and compare with the scanned sn to check the result.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
function DUTInfo.writeAndCompareSN( paraTab )
    sn = tostring(paraTab.Input)
    Log.LogInfo("$$$$ sn: "..sn)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    if sn == nil or sn == '' then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"no input sn")
        return
    end

    DataReporting.submit( DataReporting.createAttribute( "sn", sn ) )

    local dut = Device.getPlugin("dut")
    local result, resp = xpcall(dut.send,debug.traceback,"syscfg add MLB# " .. sn,3)
    if result and string.find(resp, "Finish!") ~= nil then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "WRITE_SN","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "WRITE_SN","cannot find 'Finish!' in response")
    end
    -- local sn  = dut.getSN()
    -- Log.LogInfo("$$$$ getSN:"..sn ..'****')
    local result, printVal = xpcall(dut.mlbSerialNumber,debug.traceback,3)
    Log.LogInfo("mlbSerialNumber>>>" .. comFunc.dump(printVal))
    if result then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "READ_SN","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "READ_SN","command run failed")
    end

    if printVal == sn then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "CHECK_SN","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "CHECK_SN","sn match failed")
    end
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000012_1.0
-- writeAndCompareCFG
-- Function to Query the config of UUT from SFC according to the SN, and then write mlb cfg.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
function DUTInfo.writeAndCompareCFG( paraTab )
    sn = tostring(paraTab.Input)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    if sn == nil or sn == '' then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"no input sn")
        return
    end

    local dut = Device.getPlugin("dut")
    local sfc = Device.getPlugin("SFC")
    local cfg_info = sfc.getAttributes( sn, {"mlb_cfg"} )
    Log.LogInfo("$$$$ mlb_cfg")
    Log.LogInfo(comFunc.dump(cfg_info))

    local cfg = cfg_info["mlb_cfg"]
    if cfg ~= nil and cfg ~= "" then
        DataReporting.submit( DataReporting.createAttribute( "cfg", cfg ) )
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "QUERY_CFG","")

        local result, ret = xpcall(dut.send,debug.traceback,"syscfg add CFG# " .. cfg,3)
        if result and string.find(ret, "Finish!") ~= nil then
            Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "WRITE_CFG","")
        else
            Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "WRITE_CFG","cannot find 'Finish!' in response")
        end
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "QUERY_CFG","get mlb_cfg failed")
        return 
    end

    local result, printVal = xpcall(dut.send,debug.traceback,"syscfg print CFG#",3)
    cfg = string.gsub(cfg, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
    if result and string.find(printVal, cfg) then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "READ_CFG","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "READ_CFG","cfg match failed")
    end
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000013_1.0
-- setTypeCondition
-- Function to Check MLB Type with the input string. 

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Reutrn: string,"MLB_A"/"MLB_B"
function DUTInfo.setTypeCondition( paraTab )
    local ret = paraTab.Input
    if ret == nil then
        local Restore = require("Tech/Restore")
        local device_log_path = Restore.getRestoreDeviceLogPath()
        ret = comFunc.fileRead(device_log_path)
    end
    if ret == nil or #ret == 0 then 
        error("miss inputValue or restore device log")
    end
    local mlb_b = comFunc.splitString(paraTab.AdditionalParameters.mlb_b, ';' )
    local mlb_type = "MLB_A"
    for _, expect in ipairs(mlb_b) do
        if string.find(ret, expect) ~= nil then
            mlb_type = "MLB_B"
            break
        end
    end
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    return mlb_type
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000014_1.0
-- getStorageSize
-- Function to Get the memory size from the Input string and regex. Return "0GB" if did not match any values with the Regex.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Reutrn: string,The memory size of UUT(xxGB)
function DUTInfo.getStorageSize( paraTab )
    local Regex = Device.getPlugin("Regex")
    local logFile = Device.userDirectory .. "/uart.log"
    local ret = ""
    local inputValue = paraTab.Input
    if inputValue then
        Log.LogInfo("$$$$ getStorageSize from inputValue")
        ret = inputValue
    else
        Log.LogInfo("$$$$ getStorageSize from uart.log")
        ret = comFunc.fileRead(logFile)
    end
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local divisor = 1
    local result = true
    local storageSize = '0GB'

    if paraTab.AdditionalParameters.pattern then
        local Regex = Device.getPlugin("Regex")
        local pattern = paraTab.AdditionalParameters.pattern
        local matchs = Regex.groups(ret, pattern, 1)
        if matchs and #matchs > 0 and #matchs[1] > 0 then
            ret = matchs[1][1]
        else
            result = false
            failureMsg = 'match failed'
        end
    else
        result = false
        failureMsg = 'miss pattern'
    end

    if paraTab.AdditionalParameters.divisor then
        if tonumber(paraTab.AdditionalParameters.divisor) ~= 0 then
            divisor = tonumber(paraTab.AdditionalParameters.divisor)
        else
            result = false
            failureMsg = 'divisor error'
        end
    end

    if result then
        storageSize = string.format("%dGB",(tonumber(ret) / divisor))
        if paraTab.AdditionalParameters.attribute then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, storageSize ) )
        end
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname, failureMsg)
    return storageSize
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000015_1.0
-- getScannedSerialNumber
-- Function to get the scanned serial number

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
function DUTInfo.getScannedSerialNumber(paraTab)
    local sn = ""
    local interactiveView = Device.getPlugin("InteractiveView")
    local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    Log.LogInfo("$$$$$ getSNFromInteractiveView" .. data)
    if not status or data == nil then
        sn = ""
    else
        sn = data
    end
    return sn
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000016_1.0
-- setRTC
-- Function to set dut rtc time

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
function DUTInfo.setRTC(paraTab)
    local dut = Device.getPlugin("dut")
    local result, rtc = xpcall(dut.setRTC,debug.traceback)
    Log.LogInfo("RTC>>>>",rtc)
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)    
end

return DUTInfo