local func = {}
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'
local cal_factor = require("Tech/Calibration")
local flow_log = require("Tech/WriteLog")

function func.set_power(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local value = nil
    local start = nil
    local step = nil
    local pwr = nil

    if param.AdditionalParameters.powertype and param.Commands~= nil and param.Commands ~="" then
        value = tonumber(param.Commands)*1000
        pwr =  param.AdditionalParameters.powertype


    elseif param.AdditionalParameters.powertype and param.AdditionalParameters.start and param.AdditionalParameters.stop and param.AdditionalParameters.step then
        local start_num = param.AdditionalParameters.start
        local stop_num = param.AdditionalParameters.stop
        local step_num = param.AdditionalParameters.step

        pwr =  param.AdditionalParameters.powertype
        start = tonumber(start_num)*1000
        value = tonumber(stop_num)*1000
        step = tonumber(step_num)*1000

    end


    if string.upper(pwr) == "USB" then 
        if value < 0 or value > 17500 then assert(false,"\n VBUS SET Wrong\n)") end
        if start then 
            start = (start -1221)/4 
            if start <0 then
                start = 0
            end
        end

        if step then step = (step -1221)/4 end

        if value ~= 0 then 
            if param.AdditionalParameters.cal ~= nil then
                value = cal_factor.usb_set_with_cal_factor(value)
            end
            value = ((value-1221)/4 ) 
        end

    elseif string.upper(pwr) == "PP5V0" then
        if value < 0 or value > 5300 then assert(false,"\n PP5V0 SET Wrong\n)") end
        if start then 
            start = (start -1221)/4 
            if start <0 then
                start = 0
            end
        end
        if step then step = (step -1221)/4 end
        if value ~= 0 then
            value = ((value-1221)/4 )
        end 

    elseif string.upper(pwr) == "BATT" then
        if value < -10 or value > 4500 then assert(false,"\n VBATT SET Wrong\n") end

        value = cal_factor.vbatt_set_with_cal_factor(value)
        
        if value < 0 then value = 0 end

    elseif string.upper(pwr) == "ELOAD" then 
        if value < 0 or value > 3000 then assert(false,"\n ELOAD SET Wrong\n") end

    elseif string.upper(pwr) == "VB" then 
        value = (tonumber(value)/1000 )

    end

    local pwr_tab = {
            BATT = "a",
            USB  = "d",
            ELOAD = "b",
            PP5V0 = "c",
            VB = "b",
            }

    value = string.format("%.0f",value)
    local cmd = nil
    if start ~= nil then 
        cmd = "blade.dac_step_set("..pwr_tab[string.upper(pwr)]..","..start..","..value..","..step..")"
    else
        cmd = "blade.dac_set("..pwr_tab[string.upper(pwr)]..","..value..")"
    end 
    local ret = fixture.rpc_write_read(cmd,5000,slot_num)
    flow_log.writeFlowLog(cmd.." "..ret)
    os.execute("sleep 0.005")
    local result = true
    if string.find(ret, "ERR") then
        result = false
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


