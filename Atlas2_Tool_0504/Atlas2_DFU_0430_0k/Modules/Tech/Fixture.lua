local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local parser = require("Tech/Parser")
local Record = require 'Matchbox/record'


function func.delaytest(param)
    print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    os.execute('sleep ' .. (param.AdditionalParameters.s))
    print("delaytest")
    print(tostring(param.TestName) .. 'action done')
end

function func.getSlotID(param)
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    -- local report = DataReporting.createParametricRecord( tonumber(slot_num), param.Technology, param.TestName, param.AdditionalParameters.subsubtestname)
    local fixture_serial_number = func.fixture_get_serial_number(param)
    DataReporting.fixtureID(fixture_serial_number, tostring(slot_num))
    Log.LogInfo('$$$$ fixture_serial_number: '..fixture_serial_number..'headID: '..slot_num)
end


function func.callPluginFunction(param)
    print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    print("param.AdditionalParameters.plugin : " .. param.AdditionalParameters.plugin)
    local pluginFunc = Device.getPlugin(param.AdditionalParameters.plugin)
    local actionFunc = param.AdditionalParameters.func
    local funcArags = param.AdditionalParameters.arags
    
    local splitlist = {}
    if funcArags and #funcArags > 0 then
    	if string.find(funcArags,";") == nil then
    		print("debug insert :" .. funcArags)
    		table.insert(splitlist, funcArags)
    	else
		    string.gsub(funcArags, '[^;]+', function(w) table.insert(splitlist, w) end )
		end
	end
    local arags = {}
    for k,v in ipairs(splitlist) do
    	if tonumber(v) ~= nil then
    		table.insert(arags,tonumber(v))
    	else
    		table.insert(arags,v)
    	end
    end
    local cmdReturn = ""
    local aragsCount = #arags

    if aragsCount == 0 then
    	print("DEBUG run :" .. param.AdditionalParameters.plugin .."[" .. actionFunc .."]()")
    	cmdReturn = pluginFunc[actionFunc]()
    elseif aragsCount == 1 then
    	print("DEBUG run :" .. param.AdditionalParameters.plugin .."[" .. actionFunc .."](" .. arags[1] .. ")")
    	cmdReturn = pluginFunc[actionFunc](arags[1]) 
    elseif aragsCount == 2 then
    	print("DEBUG run :" .. param.AdditionalParameters.plugin .."[" .. actionFunc .."](" .. arags[1] .. "," .. arags[2] .. ")")
    	cmdReturn = pluginFunc[actionFunc](arags[1],arags[2])
    elseif aragsCount == 3 then
    	print("DEBUG run :" .. param.AdditionalParameters.plugin .."[" .. actionFunc .."](" .. arags[1] .. "," .. arags[2] .. "," .. arags[3] .. ")")
    	cmdReturn = pluginFunc[actionFunc](arags[1],arags[2],arags[3])
    else
    	print("callPluginFunction error: to many arags")
    end

    print(tostring(param.TestName) .. 'action done')
    return cmdReturn
end

function func.sendFixtureCommand(param)
    print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local actionFunc = param.cmd
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local funcArags = param.AdditionalParameters.args
    
    local splitlist = {}
    if funcArags and #funcArags > 0 then
        if string.find(funcArags,";") == nil then
            print("debug insert :" .. funcArags)
            table.insert(splitlist, funcArags)
        else
            string.gsub(funcArags, '[^;]+', function(w) table.insert(splitlist, w) end )
        end
    end
    local arags = {}
    for k,v in ipairs(splitlist) do
        if tonumber(v) ~= nil then
            table.insert(arags,tonumber(v))
        else
            table.insert(arags,v)
        end
    end
    local cmdReturn = ""
    local aragsCount = #arags

    if aragsCount == 0 then
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."]()")
        cmdReturn = pluginFunc[actionFunc]()
    elseif aragsCount == 1 then
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."](" .. arags[1] .. ")")
        cmdReturn = pluginFunc[actionFunc](arags[1]) 
    elseif aragsCount == 2 then
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."](" .. arags[1] .. "," .. arags[2] .. ")")
        cmdReturn = pluginFunc[actionFunc](arags[1],arags[2])
    elseif aragsCount == 3 then
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."](" .. arags[1] .. "," .. arags[2] .. "," .. arags[3] .. ")")
        cmdReturn = pluginFunc[actionFunc](arags[1],arags[2],arags[3])
    else
        print("callPluginFunction error: to many arags")
    end

    print(tostring(param.TestName) .. 'action done')
    return cmdReturn
end

function func.sendFixtureSlotCommand(paraTab)
    local cm = require("Matchbox/CommonFunc")
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    print("paraTab>>" .. tostring(cm.dump(paraTab)))

    print('[sendFixtureSlotCommand Run Action]: ' .. tostring(paraTab.TestName))
    -- print('[sendFixtureSlotCommand Run Action]: ' .. tostring(paraTab.TestName) .. '-' .. tostring(paraTab.actionFunc)..'-'..tostring(paraTab.input)..' Retries: '..tostring(paraTab.Retries))
    local pluginFunc = Device.getPlugin("FixturePlugin")

    local actionFunc = paraTab.Commands
    local timeout = paraTab.AdditionalParameters["Timeout"] or 20
    local funcArgs = paraTab.AdditionalParameters.args
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    print("slot_num fixture_init" .. tostring(slot_num))

    local splitlist = {}
    if funcArgs and #funcArgs > 0 then
        if string.find(funcArgs,";") == nil then
            print("debug insert :" .. funcArgs)
            table.insert(splitlist, funcArgs)
        else
            string.gsub(funcArgs, '[^;]+', function(w) table.insert(splitlist, w) end )
        end
    end
    local arags = {}
    for k,v in ipairs(splitlist) do
        if tonumber(v) ~= nil then
            table.insert(arags,tonumber(v))
        else
            table.insert(arags,v)
        end
    end
    local cmdReturn = ""
    local aragsCount = #arags

    if aragsCount == 0 then
        print(pluginFunc[actionFunc])
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."](".. slot_num ..")")
        cmdReturn = pluginFunc[actionFunc](tonumber(slot_num))
    elseif aragsCount == 1 then
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."](" .. arags[1] .. "," .. slot_num .. ")")
        cmdReturn = pluginFunc[actionFunc](arags[1],tonumber(slot_num)) 
    elseif aragsCount == 2 then
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."](" .. arags[1] .. "," .. arags[2] .. "," .. slot_num .. ")")
        cmdReturn = pluginFunc[actionFunc](arags[1],arags[2],tonumber(slot_num))
    elseif aragsCount == 3 then
        print("DEBUG run :" .. "FixturePlugin" .."[" .. actionFunc .."](" .. arags[1] .. "," .. arags[2] .. "," .. arags[3] .. "," .. slot_num .. ")")
        cmdReturn = pluginFunc[actionFunc](arags[1],arags[2],arags[3],tonumber(slot_num))
    else
        print("callPluginFunction error: to many arags")
    end

    print(tostring(paraTab.TestName) .. 'action done')

    if subsubtestname then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end

    return cmdReturn
end

function func.relay_switch( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    local netname = param.AdditionalParameters.netname
    local state = param.AdditionalParameters.state or ""
    fixture.relay_switch(netname,state,slot_num)
    if subsubtestname then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
end

function func.read_voltage( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    local netname = param.AdditionalParameters.netname
    local value = fixture.read_voltage( netname,slot_num )
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    local inputValue = param.Input
    if inputValue and inputValue == "TRUE" then
        return "TRUE","voltage out of limit"
    end
    if result then
        return "FALSE"
    else
        return "TRUE","voltage out of limit"
    end
end

function func.read_gpio( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    local netname = param.AdditionalParameters.netname
    local value = fixture.read_gpio( netname,slot_num )
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
end

function func.fixture_get_vendor(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.get_vendor("",tonumber(timeout))
    return cmdReturn
end

function func.fixture_get_serial_number(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.get_serial_number()
    return cmdReturn
end

function func.fixture_get_version(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    -- local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.get_version()

    Log.LogInfo('$$$$ fixture_get_version: '..cmdReturn..'########')
    cmdReturn = comFunc.trim(cmdReturn)
    DataReporting.submit(DataReporting.createAttribute( param.AdditionalParameters.attribute, cmdReturn ))
    -- if ( paraTab.AdditionalParameters.attribute ) then
    --     vt.setVar(paraTab.AdditionalParameters.attribute, matchs[1][1])
    --     DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, matchs[1][1]) )
    -- end
    return cmdReturn
end

function func.get_unit_location(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.get_unit_location("",tonumber(timeout))
    return cmdReturn
end

function func.fixture_init(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.init("",tonumber(timeout))
    return cmdReturn
end

function func.fixture_get_usb_location(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.get_usb_location("",tonumber(timeout))
    return cmdReturn
end

function func.fixture_set_led_state(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local action = param.AdditionalParameters["action"]
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.set_led_state(action,tonumber(timeout))
    return cmdReturn
end

function func.fixture_set_force_diags(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local action = param.AdditionalParameters["action"]
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local cmdReturn = pluginFunc.set_force_diags(action,tonumber(timeout))
    return cmdReturn
end

function func.dut_power_off(param)
    -- print('[Run Action]: ' .. tostring(param.TestName) .. '-' .. tostring(param.TestActions)..'-'..tostring(param.InputValues)..' Retries: '..tostring(param.Retries))
    -- Device.updateProgress(param.tech .. ", " .. param.TestName .. ", " .. tostring(param.AdditionalParameters["subsubtestname"]))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
    local cmdReturn = pluginFunc.dut_power_off(tonumber(slot_num))
    return cmdReturn
end

return func


