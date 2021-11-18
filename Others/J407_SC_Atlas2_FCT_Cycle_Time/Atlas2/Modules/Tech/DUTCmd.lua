
local ActionFunc = {}
local Log = require("Matchbox/logging")
local csvCommon = require("Matchbox/Matchbox")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

local function dec2bin(v_dec)
    local bin_str = ""
    if v_dec==0 or v_dec== nil then return 0 end
    while v_dec > 0 do
        local rr = math.modf(v_dec%2)
        bin_str = rr .. bin_str
        v_dec = (v_dec-rr)/2
    end
    return bin_str
end

local function hex2bin(value,bit_start,bit_end) --[1]value [2]bit_start [3]bit_end
    value = tonumber(value)
    --Log.LogInfo('$*** hex2bin 0: '..tostring(value))
    value = dec2bin(value)
    --Log.LogInfo('$*** hex2bin 1: '..tostring(value))
    value = string.format("%08d",value)
    if bit_start then
        bit_start = string.len(value) - bit_start
        if not(bit_end) then
            bit_end = bit_start
            return string.sub(value,bit_end,bit_start)
        end
        bit_end = string.len(value) - bit_end
        return string.sub(value,bit_end,bit_start)
    end
    return value
end


function ActionFunc.dut_read( paraTab )
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"

    if dut.isOpened() ~= 1 then
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
        local status, ret = xpcall(dut.read, debug.traceback, 0.5)
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret

        end

    until(os.difftime(os.time(), lastRetTime) >= timeout)
    dut.setDelimiter(default_delimiter)
    return content
end

function ActionFunc.dutsendcmd(paraTab, sendAsData)
    local dutPluginName = paraTab.AdditionalParameters.dutPluginName
    local dut = nil
    if dutPluginName then
        dut = Device.getPlugin(dutPluginName)
    else
        dut = Device.getPlugin("dut")
    end
    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 5
    end

    local cmd = paraTab.Commands
    local cmdReturn = ""

    if cmd ~= nil then
        
        if (paraTab.AdditionalParameters.delimiter ~= nil) then
            dut.setDelimiter(paraTab.AdditionalParameters.delimiter)
        else
            dut.setDelimiter("] :-)")
        end

        local commands = cmd..";"
        for command in string.gmatch(commands,"(.-);") do
            dut.write(command)
            local status, temp = xpcall(dut.read, debug.traceback, timeout)
            if status and temp~= nil then
                cmdReturn = cmdReturn..temp
            end 
        end
    end
    flow_log.writeFlowLog(cmdReturn)
    return cmdReturn
end

function ActionFunc.dut_writeRead( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname or ""
    local dut = Device.getPlugin("dut")
    local slot_num = tonumber(Device.identifier:sub(-1))
    if dut.isOpened() ~= 1 then
        --Log.LogInfo("$$$$ dut.open")
        dut.open(2)
    end

    local timeout = paraTab.Timeout

    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 5
    end

    if paraTab.AdditionalParameters.delimiter then
        dut.setDelimiter(paraTab.AdditionalParameters.delimiter)
    else
        dut.setDelimiter("] :-)")
    end

    local ret = nil
    local result = nil

    local timeout_sub = 5
    if paraTab.AdditionalParameters.timeout ~= nil then
        timeout_sub = tonumber(paraTab.AdditionalParameters.timeout)
    end

    if paraTab.AdditionalParameters.mark~= nil then
        xpcall(ActionFunc.dut_read, debug.traceback, {Commands=nil,Timeout=timeout_sub})
    end
    
    result, ret = xpcall(ActionFunc.dutsendcmd, debug.traceback, paraTab,1)

    local raw_ret = ret
    flow_log.writeFlowLog(ret)
    if paraTab.AdditionalParameters.pattern~= nil then


        if paraTab.AdditionalParameters.escape~= nil then
            ret = string.gsub(ret,"\r","")
            ret = string.gsub(ret,"\n","")
        end

        local pattern = paraTab.AdditionalParameters.pattern

        ret = string.match(ret,pattern)

        if paraTab.AdditionalParameters.bit ~=nil then

            local bit_num = tonumber(paraTab.AdditionalParameters.bit)
            if  paraTab.AdditionalParameters.suffix ~=nil then
                ret = "0x"..tostring(ret)
            end
            ret = hex2bin(ret,bit_num,nil)
        end

        if ret~=nil and ret~="" then

            if paraTab.AdditionalParameters.attribute ~= nil and ret then
                DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
            end
        
        else
            result = false
        end
    else
        result = true
    end

    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" then

        if paraTab.AdditionalParameters.parametric ~=nil then
            local limitTab = paraTab.limit
            local limit = nil
            if limitTab then
                limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
            end
            Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
        else

            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end
    
    if paraTab.AdditionalParameters.return_val ~=nil then
        return raw_ret
    end

    if not result then
        ret =""
    end

    return ret

end


function ActionFunc.dut_parse( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    local ret = paraTab.Input
    
    local result = true
    if paraTab.AdditionalParameters.pattern~= nil then

        if paraTab.AdditionalParameters.escape~= nil then
            ret = string.gsub(ret,"\r","")
            ret = string.gsub(ret,"\n","")
        end

        local pattern = paraTab.AdditionalParameters.pattern

        ret = string.match(ret,pattern)

        if paraTab.AdditionalParameters.bit ~=nil then

            local bit_num = tonumber(paraTab.AdditionalParameters.bit)
            if  paraTab.AdditionalParameters.suffix ~=nil then
                ret = "0x"..tostring(ret)
            end
            ret = hex2bin(ret,bit_num,nil)
        end

        if ret~=nil and ret~="" then

            if paraTab.AdditionalParameters.attribute ~= nil and ret then
                DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
            end
        
        else
            result = false
        end
    else
        if ret ==nil or ret == "" then
            result = false
        end
    end

    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" then
        if paraTab.AdditionalParameters.parametric ~=nil then
            local limitTab = paraTab.limit
            local limit = nil
            if limitTab then
                limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
            end
            Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
        else
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end

    if #ret <=0 then
        return ""
    end
    return ret

end


function ActionFunc.dut_sendString( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    local dut = Device.getPlugin("dut")

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    local cmd = paraTab.Commands
    if cmd ~= nil then
        dut.write(cmd)
    end
    os.execute('sleep 0.1')
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
end

function ActionFunc.dut_detect_Hibernation( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    local startTime = os.time()
    local timeout = 60

    dut.setDelimiter("")
    dut.write("\r\n")
    
    local content = ""
    local lastRetTime = os.time()
    local result = false
    repeat  
        local status, ret = xpcall(dut.read, debug.traceback, 0.1, '')
        
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret
        end

        if string.find(content,"Event quiesce: TongaPMGR") then
            xpcall(dut.read, debug.traceback, 0.1, '')
            result = true
            break
        end

    until(os.difftime(os.time(), lastRetTime) >= timeout)
    
    flow_log.writeFlowLog(content)
    dut.setDelimiter(default_delimiter)
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
end


return ActionFunc
