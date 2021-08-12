local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local common = require("Tech/Common")
local shell = require("Tech/Shell")
local Record = require 'Matchbox/record'

function func.openDimensionSerialport( paraTab )
    local cmd = paraTab.Commands
    local spec = '--serial efidmns'
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local result = false
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    if string.find(cmd, spec) then
        spec_replace = spec .. string.char((string.byte('A') + slot_num - 1))
        cmd = string.gsub(cmd,spec,spec_replace)
        local dut = Device.getPlugin("dut")
        local status, resp = xpcall(dut.send,debug.traceback,cmd,3)
        local expect = paraTab.AdditionalParameters.expect or "OK"
        if status and string.find(resp, expect) then
            result = true
        else
            failureMsg = 'expect error'
        end
    else
        failureMsg = 'command error'
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname,failureMsg)
end

function func.connectDimensionPort( paraTab )
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    local devPath = "cu.usbmodemefidmns" .. string.char((string.byte('A') + slot_num - 1)) .. "11"
    Log.LogInfo("expect devPath:" .. devPath)
    local startTime = os.time()
    local shell = require("Tech/Shell")
    local timeout = paraTab.Timeout
    local dutPluginName = paraTab.AdditionalParameters.dutPluginName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local result = false
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 20
    end

    local devContent = ""
    repeat
        devContent = shell.execute("ls /dev")
        if string.find(devContent, devPath) then
            if dutPluginName then
                local dut = Device.getPlugin(dutPluginName)
                local status, ret = xpcall(dut.open, debug.traceback, 3)
                if status then
                    result = true
                    dut.setDelimiter('] :-)')
                else
                    failureMsg = "DimensionSerialport open failed"
                end
            else
                failureMsg = "miss dutPluginName Parameter"
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

return func