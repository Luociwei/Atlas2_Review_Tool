-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------

local Fixture = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000017_1.0
-- Fixture.getSlotNum( paraTab )
-- Function to get the slot_num
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string
-----------------------------------------------------------------------------------]]

function Fixture.getSlotNum( paraTab )
    local slot_num = Device.systemIndex + 1
    local limitTab = paraTab.limit
    local limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    end
    if paraTab.AdditionalParameters.attribute then
        DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, tostring(slot_num)) )
    end
    Record.createParametricRecord(tonumber(slot_num), paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,limit)
    return tostring(slot_num)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000018_1.0
-- Fixture.setFixtureID(paraTab)
-- Function to query and upload the fixture_serial_number and headID to PDCA.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Fixture.setFixtureID(paraTab)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local slot_num = tonumber(Device.identifier:sub(-1))
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local fixture_serial_number = fixturePlugin.get_serial_number()
    DataReporting.fixtureID(fixture_serial_number, tostring(slot_num))
    Log.LogInfo('$$$$ fixture_serial_number: '..fixture_serial_number..'headID: '..slot_num)
    if subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, subsubtestname)
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000019_1.0
-- Fixture.sendFixtureCommand(paraTab)
-- Function to Call the fixture plugin function according to the function name and args which define in the tech csv line.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string
-----------------------------------------------------------------------------------]]

function Fixture.sendFixtureCommand(paraTab)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Log.LogInfo('[Run Action]: ' .. tostring(paraTab.TestName) .. '-' .. tostring(paraTab.TestActions)..'-'..tostring(paraTab.InputValues)..' Retries: '..tostring(paraTab.Retries))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local actionFunc = paraTab.Commands
    local funcArgs = paraTab.AdditionalParameters.args
    local args = Fixture.parseFuncArgs(funcArgs)
    local cmdReturn = ""
    if #args > 0 then
        cmdReturn = pluginFunc[actionFunc](table.unpack(args))
    else
        cmdReturn = pluginFunc[actionFunc]()
    end
    Log.LogInfo(tostring(paraTab.TestName) .. 'action done')

    if paraTab.AdditionalParameters.attribute then
        cmdReturn = comFunc.trim(cmdReturn)
        DataReporting.submit(DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, cmdReturn ))
    end

    if subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, subsubtestname .. paraTab.testNameSuffix)
    end
    return cmdReturn
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000020_1.0
-- Fixture.sendFixtureSlotCommand(paraTab)
-- Function to add the current slot num after the last args and call the fixturePlugin function.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string
-----------------------------------------------------------------------------------]]

function Fixture.sendFixtureSlotCommand(paraTab)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Log.LogInfo('[Run Action]: ' .. tostring(paraTab.TestName) .. '-' .. tostring(paraTab.TestActions)..'-'..tostring(paraTab.InputValues)..' Retries: '..tostring(paraTab.Retries))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local actionFunc = paraTab.Commands
    local funcArgs = paraTab.AdditionalParameters.args
    local slot_num = tonumber(Device.identifier:sub(-1))
    local args = Fixture.parseFuncArgs(funcArgs)
    local cmdReturn = ""
    if #args > 0 then
        cmdReturn = pluginFunc[actionFunc](table.unpack(args),slot_num)
    else
        cmdReturn = pluginFunc[actionFunc](slot_num)
    end
    Log.LogInfo(tostring(paraTab.TestName) .. 'action done')

    if paraTab.AdditionalParameters.attribute then
        cmdReturn = comFunc.trim(cmdReturn)
        DataReporting.submit(DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, cmdReturn ))
    end

    if subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, subsubtestname .. paraTab.testNameSuffix)
    end
    return cmdReturn
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000021_1.0
-- Fixture.parseFuncArgs( argsStr )
-- Function to parse the function args string.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : string(seperate by ";")
-- Output Arguments : table
-----------------------------------------------------------------------------------]]

function Fixture.parseFuncArgs( argsStr )
    local args = {}
    if argsStr then
        local splitlist = comFunc.splitString(argsStr,";")
        if splitlist then
            for k,v in ipairs(splitlist) do
                if tonumber(v) ~= nil then
                    table.insert(args,tonumber(v))
                else
                    table.insert(args,v)
                end
            end
        end
    end
    return args
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000022_1.0
-- Fixture.relaySwitch( paraTab )
-- Function to Switch the relay base on the netname and state which define in the tech csv line.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Fixture.relaySwitch( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = paraTab.AdditionalParameters.netname
    local state = paraTab.AdditionalParameters.state or ""
    fixturePlugin.relay_switch(netname,state,slot_num)
    if subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, subsubtestname)
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000023_1.0
-- Fixture.readVoltage( paraTab )
-- Function to Read the voltage according to the netname and create the Parametric Record.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string("PASS"/"FAIL")
-----------------------------------------------------------------------------------]]

function Fixture.readVoltage( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = paraTab.AdditionalParameters.netname
    local value = fixturePlugin.read_voltage( netname, slot_num )
    local limitTab = paraTab.limit
    local limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(value), paraTab.Technology, paraTab.TestName, subsubtestname .. paraTab.testNameSuffix,limit)
    if result then
        return "PASS"
    else
        return "FAIL"
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000024_1.0
-- Fixture.readGPIO( paraTab )
-- Function toRead the gpio according to the netname and create the Parametric Record.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Fixture.readGPIO( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = paraTab.AdditionalParameters.netname
    local value = fixturePlugin.read_gpio( netname,slot_num )
    local limitTab = paraTab.limit
    local limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), paraTab.Technology, paraTab.TestName, subsubtestname .. paraTab.testNameSuffix,limit)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000026_1.0
-- Fixture.readGPIO( paraTab )
-- Function to get the rpc server log from xavier and move the log to Device.userDirectory
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Fixture.getRpcServerLog( paraTab )
    local slot_num = tonumber(Device.identifier:sub(-1))
    local rpcLogFile = "/vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num) .. "/server.log"
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    fixturePlugin.get_and_write_xavier_log(rpcLogFile, slot_num)
    local status, resp = xpcall(comFunc.runShellCmd, debug.traceback, "cp -r /vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num) .. " " .. Device.userDirectory)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000061_1.0
-- Fixture.getFanStatus( paraTab )
-- Function to check the fan status
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Fixture.getFanStatus( paraTab )
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local fanStatus = fixturePlugin["isFanOk"](slot_num)
    Log.LogInfo("isFanOK>>>" .. tostring(fanStatus))
    Record.createBinaryRecord(fanStatus, paraTab.Technology, paraTab.AdditionalParameters["subsubtestname"], paraTab.failSubSubTestName and paraTab.failSubSubTestName .. "_" .. paraTab.AdditionalParameters["information"] or paraTab.AdditionalParameters["information"])
    if not fanStatus then 
        error("FanCheck Failed!!") 
    end
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000062_1.0
-- Fixture.dut_power_on(paraTab)
-- Function to power on the DUT
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function Fixture.dut_power_on(paraTab)
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local cmdReturn = fixturePlugin.dut_power_on(tonumber(slot_num))
    return cmdReturn
end

return Fixture