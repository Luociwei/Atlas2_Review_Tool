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
local parser = require("Tech/Parser")
local Record = require("Matchbox/record")

-- A new function Starts after this
-- Unique Function ID :  Microtest_000017_1.0
-- getSlotNum
-- Function to get the slot_num

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
function Fixture.getSlotNum( paraTab )
    local slot_num = Device.systemIndex + 1
    return tostring(slot_num)
end

 
-- A new function Starts after this
-- Unique Function ID :  Microtest_000018_1.0
-- setFixtureID
-- Function to query and upload the fixture_serial_number and headID to PDCA.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
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


-- A new function Starts after this
-- Unique Function ID :  Microtest_000019_1.0
-- sendFixtureCommand
-- Function to Call the fixture plugin function according to the functionName/Args which define in the tech csv line.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return: the result of the plugin function.
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


-- A new function Starts after this
-- Unique Function ID :  Microtest_000020_1.0
-- sendFixtureSlotCommand
-- Function to add the current slot num to the last args of function.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return: the result of the plugin function.
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

-- A new function Starts after this
-- Unique Function ID :  Microtest_000021_1.0
-- parseFuncArgs
-- Function to parse the function args string.

-- Created by: Jayson ye 
-- Initial Creation Date :  07/13/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments: string, seperate by ";"
-- Return : the args table.
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


-- A new function Starts after this
-- Unique Function ID :  Microtest_000022_1.0
-- relaySwitch
-- Function to Switch the relay base on the netname and state which define in the tech csv line.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return: nil
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


-- A new function Starts after this
-- Unique Function ID :  Microtest_000023_1.0
-- readVoltage
-- Function to Read the voltage according to the netname and create the Parametric Record.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return: "PASS" or "FAIL"
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


-- A new function Starts after this
-- Unique Function ID :  Microtest_000024_1.0
-- readGPIO
-- Function toRead the gpio according to the netname and create the Parametric Record.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return: SOF flag "TRUE" or "FALSE", if SOF is TRUE,return fail msg
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

-- A new function Starts after this
-- Unique Function ID :  Microtest_000025_1.0
-- addLogToInsight
-- Function to  add user/ folder to systemArchive.zip,station can choose what file/folder to add by calling Archive.addPathName here.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
function Fixture.addLogToInsight(param)
    Log.LogInfo('adding user/ log folder to insight')
    local status, resp = xpcall(comFunc.runShellCmd, debug.traceback, "cp -r /vault/Atlas/FixtureLog/Microtest ".. Device.userDirectory)
    local status, resp = xpcall(comFunc.runShellCmd, debug.traceback, "cp -r /vault/Atlas/FixtureLog/Suncode ".. Device.userDirectory)
    Archive.addPathName(Device.userDirectory, Archive.when.endOfTest)
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000026_1.0
-- getRpcServerLog
-- Function to get the rpc server log from xavier and move the log to Device.userDirectory

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv 
function Fixture.getRpcServerLog( param )
    local slot_num = tonumber(Device.identifier:sub(-1))
    local rpcLogFile = "/vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num) .. "/server.log"
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    fixturePlugin.get_and_write_xavier_log(rpcLogFile, slot_num)
    local status, resp = xpcall(comFunc.runShellCmd, debug.traceback, "cp -r /vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num) .. " " .. Device.userDirectory)
end

return Fixture