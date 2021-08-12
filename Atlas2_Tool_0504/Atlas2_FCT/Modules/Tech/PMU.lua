local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'


function func.dut_read( paraTab )
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"

    if dut.isOpened() ~= 1 then
        --dut.setDelimiter("")
        dut.open(2)
    end

    local startTime = os.time()
    local timeout = paraTab.Timeout
    if timeout == nil then
        timeout = 5
    end

    dut.setDelimiter("")

    local cmd = paraTab.Commands
    if cmd ~= nil then
        dut.write(cmd)
    end

    local content = ""

    local lastRetTime = os.time()
    repeat
        
        local status, ret = xpcall(dut.read, debug.traceback, 0.1, '')
        
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret

        end

    until(os.difftime(os.time(), lastRetTime) >= timeout)
  
    dut.setDelimiter(default_delimiter)
    return content
end


function func.button( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("BTN_GND","DISCONNECT",slot_num)


    local dut = Device.getPlugin("dut")
    local timeout = 5
    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    dut.setDelimiter("] :-)")
    if param.AdditionalParameters.mark ~=nil then
        xpcall(func.dut_read, debug.traceback, {Commands="\r\n",Timeout=timeout_sub})
    end

    local cmd = param.Commands
    dut.write(cmd)
    os.execute("sleep 0.05")

    
    
    if cmd == "button -h --time 2000" then
        os.execute("sleep 0.1")
        fixture.relay_switch("BTN_GND","GPIO_BTN_POWER",slot_num)
        os.execute("sleep 0.3")
        fixture.relay_switch("BTN_GND","DISCONNECT",slot_num)
        os.execute("sleep 0.1")


    elseif cmd == "button -u --time 2000" then
        os.execute("sleep 0.1")
        fixture.relay_switch("BTN_GND","GPIO_BTN_VOL_UP",slot_num)
        os.execute("sleep 0.3")       
        fixture.relay_switch("BTN_GND","DISCONNECT",slot_num)
        os.execute("sleep 0.1")

    elseif cmd == "button -d --time 2000" then
        os.execute("sleep 0.1")
        fixture.relay_switch("BTN_GND","GPIO_BTN_VOL_DOWN",slot_num)
        os.execute("sleep 0.3")    
        fixture.relay_switch("BTN_GND","DISCONNECT",slot_num)
        os.execute("sleep 0.1")
    
    end

    os.execute("sleep 0.2")
    
    local ret = dut.read(timeout)

    if param.AdditionalParameters.pattern~= nil then

        local pattern = param.AdditionalParameters.pattern
        ret = string.match(ret,pattern)

    end

    local result = false
    if ret~=nil then
        result = true
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

return func


