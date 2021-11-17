-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------

local Dimension = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")

-- A new function Starts after this
-- Unique Function ID :  Microtest_000006_1.0
-- connectDimensionPort
-- Function to Search the Dimension Serialport and then open the dimension_dut plugin.
---- slot1 : --serial efidmnsA1
---- slot2 : --serial efidmnsB1
---- slot3 : --serial efidmnsC1
---- slot4 : --serial efidmnsD1

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
function Dimension.connectDimensionPort( paraTab )
    local slot_num = Device.systemIndex + 1
    local devPath = "cu.usbmodemefidmns" .. string.char((string.byte('A') + slot_num - 1)) .. "11"
    Log.LogInfo("expect devPath:" .. devPath)
    local startTime = os.time()
    local timeout = paraTab.Timeout
    local dutPluginName = paraTab.AdditionalParameters.dutPluginName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local result = false
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        error("miss timeout")
    end
    if not dutPluginName then 
        error("miss dutPluginName Parameter")
    end

    local devContent = ""
    repeat
        devContent = comFunc.runShellCmd("ls /dev")['output']
        if string.find(devContent, devPath) then
            local dut = Device.getPlugin(dutPluginName)
            local status, ret = xpcall(dut.open, debug.traceback, 3)
            if status then
                result = true
                dut.setDelimiter('] :-)')
            else
                failureMsg = "DimensionSerialport open failed"
                Log.LogInfo("dimension_dut Open failed:" .. tostring(ret))
            end
            break
        else
            comFunc.sleep(0.1)
        end
    until(os.difftime(os.time(), startTime) >= timeout)
    if not result then
        Log.LogInfo("$$$$ device list :" .. devContent)
    end
    Log.LogInfo("$$$$ connectDimensionPort end")
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname,failureMsg)
end

return Dimension