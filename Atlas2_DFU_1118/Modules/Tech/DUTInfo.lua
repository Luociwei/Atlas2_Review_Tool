local DUTInfo = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000030_1.0
-- DUTInfo.getStationID( paraTab )
-- Function to get station name
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function DUTInfo.getStationID(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local station_type = "LA"
    local failureMsg = ""
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname, failureMsg)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000031_1.0
-- DUTInfo.getSiteName( paraTab )
-- Function to get factory site
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function DUTInfo.getSiteName(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local station_type = "LA_LH"
    local failureMsg = ""
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, station_type)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000032_1.0
-- DUTInfo.getBoardID( paraTab )
-- Function to get MLB board type, 0x12 is MLB_B, 0x10 is MLB_A
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function DUTInfo.getBoardID(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local input = paraTab.Input
    local ret = ""
    if input == "0x12" then
        ret = "MLB_B"
    elseif input == "0x10" then
        ret = "MLB_A"
    else
        ret = "Unknown"
    end

    local result = true

    if paraTab.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
    end
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Log.LogInfo("$$$$ get bd: " .. ret)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, ret)
    return ret

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000033_1.0
-- DUTInfo.getScannedSerialNumber(paraTab)
-- Function to get Scanned Serial Number for MLB
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function DUTInfo.getScannedSerialNumber(paraTab)
    Log.LogInfo("$$$$$ getSNFromInteractiveView start")
    local sn = ""
    local interactiveView = Device.getPlugin("InteractiveView")
    local status, data = xpcall(interactiveView.getData, debug.traceback, Device.systemIndex)
    Log.LogInfo("$$$$$ getSNFromInteractiveView" .. data)
    if not status or data == nil then
        sn = ""
    else
        sn = data
    end
    return sn
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000034_1.0
-- DUTInfo.checkScannedSNAndMLBSN( paraTab )
-- Function to check MLB Scanned SN And MLBSN
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function DUTInfo.checkScannedSNAndMLBSN(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)

    local interactiveView = Device.getPlugin("InteractiveView")
    local status, data = xpcall(interactiveView.getData, debug.traceback, Device.systemIndex)
    local mlbsn = data or ""

    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    local cmd = paraTab.Commands
    local ret = ""

    dock_port.readString(slot_num, port) -- clear buffer
    local ret = dock_port.writeRead(cmd .. "\r", "] :-)", 5000, slot_num, port)
    flow_log.writeFlowLog(ret)
    ret = string.gsub(ret, "\r", "")
    ret = string.gsub(ret, "\n", "")

    if paraTab.AdditionalParameters.pattern ~= nil then
        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret, pattern)
    end

    if ret ~= nil and ret ~= "" then
        if paraTab.AdditionalParameters.attribute ~= nil and ret then
            DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
        end

    end

    local result = false
    if ret == mlbsn then
        result = true
    end
    if result == false and paraTab.AdditionalParameters.fa_sof == "YES" then
        error('DUTInfo.checkScannedSNAndMLBSN is error')
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, result)
end

return DUTInfo