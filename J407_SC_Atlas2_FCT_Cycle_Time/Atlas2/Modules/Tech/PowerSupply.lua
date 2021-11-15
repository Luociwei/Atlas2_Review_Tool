local func = {}
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

function func.set_power(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local result = false
    local powertype = param.AdditionalParameters.powertype
    if powertype:upper() == "BATT" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_battery_voltage(tonumber(stop),tostring(start).."-"..tostring(stop).."-"..tostring(step),slot_num)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_battery_voltage(tonumber(value),"",slot_num)
        end
        
        if not string.find(ret, "ERR") then
            result = true
        end

    elseif powertype:upper() == "USB" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_usb_voltage(tonumber(stop),tostring(start).."-"..tostring(stop).."-"..tostring(step),slot_num)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_usb_voltage(tonumber(value),"",slot_num)
        end
        
        if not string.find(ret, "ERR") then
            result = true
        end

    elseif  powertype:upper() == "PP5V0" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_pp5v0_output(tonumber(stop),tostring(start).."-"..tostring(stop).."-"..tostring(step),slot_num)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_pp5v0_output(tonumber(value),"",slot_num)
        end
        
        if not string.find(ret, "ERR") then
            result = true
        end

    elseif powertype:upper() == "ELOAD" then

        local ret = ""
        if param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then

            local start = param.AdditionalParameters.start
            local stop = param.AdditionalParameters.stop
            local step = param.AdditionalParameters.step
            ret = fixture.set_eload_output(tonumber(stop),tostring(start).."-"..tostring(stop).."-"..tostring(step),slot_num)
        else
            local value = tonumber(param.Commands)
            ret = fixture.set_eload_output(tonumber(value),"",slot_num)
        end
        
        if string.find(ret, "ERR") then
            error("power supply set error!")
        else
            result = true
        end

    end

    return result

end


function func.power_supply(param )

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local result = func.set_power(param)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

end

return func


