local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'

local flow_log = require("Tech/WriteLog")

function func.setEload( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local cmd = param.Commands
    flow_log.writeFlowLog(cmd)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local channel,mode,value = string.match(cmd,"eload%.set%((%d)%*(%w*)%*(%d*)%)")
    local ret = fixture.eload_set(tonumber(channel),tostring(mode),tonumber(value),slot_num)
    local result = true
    if string.find(ret,"ERR") then
        result = false
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

end

function func.read_eload_current( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local value = fixture.read_eload_current(netname,slot_num)

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


