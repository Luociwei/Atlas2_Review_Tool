local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'



function func.relay(netname, state)
    
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    fixture.relay_switch(netname,state,slot_num)

end

function func.relay_switch( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local state = param.AdditionalParameters.state or ""
    fixture.relay_switch(netname,state,slot_num)

    if param.AdditionalParameters.netname2 ~=nil and param.AdditionalParameters.netname2~= "" and param.AdditionalParameters.state2 ~=nil and param.AdditionalParameters.state2~="" then
        os.execute('sleep 0.02')
        local netname2 = param.AdditionalParameters.netname2
        local state2 = param.AdditionalParameters.state2
        fixture.relay_switch(netname2,state2,slot_num)
    end

    if subsubtestname then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
end


function func.set_ad8253_gain( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local state = param.AdditionalParameters.state

    fixture.relay_switch(netname,state,slot_num)

    local factor = 1
    if state=="X1" then
        result = 1
    elseif state=="X10" then
        result = 0.1
    elseif state=="X100" then
        result = 0.01
    elseif state=="X1000" then
        result = 0.001
    end

    if param.AdditionalParameters.netname2 ~=nil and param.AdditionalParameters.netname2~= "" and param.AdditionalParameters.state2 ~=nil and param.AdditionalParameters.state2~="" then
        os.execute('sleep 0.01')
        local netname2 = param.AdditionalParameters.netname2
        local state2 = param.AdditionalParameters.state2
        fixture.relay_switch(netname2,state2,slot_num)
    end

    if subsubtestname then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    return result
end

return func


