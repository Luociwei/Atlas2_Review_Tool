local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local cal_factor = require("Tech/Calibration")


function func.seteccload( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local command = param.Commands
    local cmd = string.gsub(tostring(command),"*",",")

    if string.find(cmd,"1,cc,0") then
        fixture.rpc_write_read(cmd,10000,slot_num)
        fixture.rpc_write_read("eload.disable(1)",10000,slot_num)

    else
        fixture.rpc_write_read("eload.enable(1)",10000,slot_num)
        local channel,value = string.match(cmd,"eload%.set%((%d*)%,cc%,(%d*%.?%d*)%)")

        channel = tonumber(channel)
        value = tonumber(value)

        value = cal_factor.cal_eload_set_factor(channel,value)
        cmd = "eload.set("..tostring(channel)..",cc,"..tostring(value)..")"
        
        fixture.rpc_write_read(cmd,10000,slot_num)
        if value < 2 then
            os.execute("sleep 1")
        else
            os.execute("sleep 0.1")
        end 
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end

end




function func.set_ccload(param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local command = param.Commands
    local cmd = string.gsub(tostring(command),"*",",")


    local channel,value = string.match(cmd,"eload%.set%((%d*)%,cc%,(%d*%.?%d*)%)")

    local channel = tonumber(channel)
    value = tonumber(value)

    value = cal_factor.cal_eload_set_factor(channel,value)
    cmd = "eload.set("..tostring(channel)..",cc,"..tostring(value)..")"
    local ret = fixture.rpc_write_read(cmd,10000,slot_num)

    local result = true
    if string.find(ret, "ERR") then
        result = false
    end

    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    
end


function func.read_eload_current( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 5000
    local netname = param.AdditionalParameters.netname

    local io_cmd = fixture.get_measure_table(netname,"IO",slot_num)
    fixture.rpc_write_read(io_cmd,timeout,slot_num)
    os.execute("sleep 0.1")

    local chn = tonumber(string.match(netname,"ELOAD_CURRENT_SENSE(%d+)"))
    local cmd = "eload.eload_read_current("..chn..")"
    local ret = fixture.rpc_write_read(cmd,timeout,slot_num)
    local current = tonumber(string.match(ret,"([+-]?%d+%.*%d*)%s*mA"))

    local value = -999
    if ret then
        value = cal_factor.cal_eload_read_factor(chn,current)
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    end

    return tonumber(value)
end


return func


