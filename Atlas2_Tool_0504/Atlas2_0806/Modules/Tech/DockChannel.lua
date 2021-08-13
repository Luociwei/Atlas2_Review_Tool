local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

local function dec2bin(v_dec)
    local bin_str = ""
    if v_dec==0 then return 0 end
    while v_dec > 0 do
        local rr = math.modf(v_dec%2)
        bin_str = rr .. bin_str
            v_dec = (v_dec-rr)/2
    end
  return bin_str
end

local function hex2bin(value,bit_start,bit_end) --[1]value [2]bit_start [3]bit_end
    value = tonumber(value)
    value = dec2bin(value)
    --value = string.gsub(value,".0","")
  --Log.LogInfo('$*** hex2bin '..tostring(value))
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

local function binary_to_data(arg)
    local data=0
    local binary_arg={}
    if type(arg)=="string" or type(arg)=="number" then
        for v in string.gmatch(arg,"%d") do
            if tonumber(v)>1 then
                return assert("Input_binary_incorrect!")
            end
           table.insert(binary_arg,v)
        end
    else
        binary_arg=arg
    end
    for i=1,#binary_arg do
        data=data+math.pow(2,(#binary_arg-i))*binary_arg[i]
    end
    return data
end

function func.writeRead( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Log.LogInfo('$*** dock channel send ')
    
    local dock_config = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local port = 31776
    local command = param.Commands
    local cmd = string.gsub(tostring(command),"*",",")
    Log.LogInfo('$*** dock channel cmd: '..cmd)
    local ret = dock_config.writeRead(cmd.."\r\n","^-^",2000,slot_num,port)
    flow_log.writeFlowLog(ret)
    Log.LogInfo('$*** dock channel result: '..ret)
    local result = false
    if string.find(ret, "%^%-%^") then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
end


function func.waitDFU( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Log.LogInfo('$*** waitDFU**** ')
    
    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    dock_port.setDetectString("DFU Entered",slot_num,port)
    dock_port.waitForString(5000,slot_num,port)
    dock_port.readString(slot_num,port)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
end

function func.dut_writeAndRead( paraTab )
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"

    if dut.isOpened() == 0 then
        dut.setDelimiter("")
        dut.open(2)
    end

    local startTime = os.time()
    local timeout = paraTab.Timeout

    local timeout = 5

    local cmd = paraTab.Commands
    if cmd ~= nil then
        dut.write(cmd)
    end

    local content = ""
    local delimiter = "%] %:%-%)" 
    local lastRetTime = os.time()
    repeat
        local status, ret = xpcall(dut.read, debug.traceback, 0.1, '')
        local cmd_index = -1
        local delimiter_index = -1
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret

            if #content >0 then
                delimiter_index = string.find(content, delimiter)
                if cmd ~= nil and #cmd > 0 then
                    cmd_index = string.find(content, cmd)
                    if cmd_index and cmd_index>0 and delimiter_index and delimiter_index > cmd_index then
                        break
                    end
                else
                    if delimiter_index and delimiter_index > 0 then
                        break
                    end
                end
            end
        end

    until(os.difftime(os.time(), startTime) >= timeout)
  
    dut.setDelimiter(default_delimiter)
    return content
end

function func.dp_writeRead( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local port = 31337
    local cmd = paraTab.Commands
    local commands = cmd..";"
    local ret = ""
    
    dock_port.readString(slot_num,port) -- clear buffer
    for command in string.gmatch(commands,"(.-);") do
        local sub_ret = dock_port.writeRead(command.."\r","] :-)",5000,slot_num,port)
        if sub_ret~= nil then
            sub_ret = string.gsub(sub_ret,command,"")
            ret = ret..sub_ret
        end 
    end

    flow_log.writeFlowLog(ret)
    local raw_ret = ret
    --Log.LogInfo('$***dock port:  '..ret)
    if paraTab.AdditionalParameters.pattern ~=nil then
        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret,pattern)
    end

    if paraTab.AdditionalParameters.patterns ~=nil then
        local pattern = paraTab.AdditionalParameters.patterns
        local a,b,c,d,e,f,g,h = string.match(ret,pattern)
        ret = a.." "..b.." "..c.." "..d.." "..e.." "..f.." "..g.." "..h
    end

    local result = true
    if ret~=nil and ret~="" then

        if paraTab.AdditionalParameters.attribute ~= nil and ret then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
        end
    
    else
        result = false
    end


    if paraTab.AdditionalParameters.parametric ~=nil then
        local limitTab = paraTab.limit
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)

    else
        if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result==false then
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

function func.dp_writeReadBit( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local port = 31337
    local cmd = paraTab.Commands
    local commands = cmd..";"
    local ret = ""
    
    dock_port.readString(slot_num,port) -- clear buffer
    for command in string.gmatch(commands,"(.-);") do
        local sub_ret = dock_port.writeRead(command.."\r","] :-)",5000,slot_num,port)
        if sub_ret~= nil then
            sub_ret = string.gsub(sub_ret,command,"")
            ret = ret..sub_ret
        end 
    end

    flow_log.writeFlowLog(ret)

    if paraTab.AdditionalParameters.pattern ~=nil then
        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret,pattern)
    end

    if paraTab.AdditionalParameters.bit ~=nil then
        local bit_num = tonumber(paraTab.AdditionalParameters.bit)
        if  paraTab.AdditionalParameters.suffix ~=nil then
            ret = "0x"..tostring(ret)
        end
        ret = hex2bin(ret,bit_num,nil)
    end

    local result = true
    if ret~=nil and ret~="" then

        if paraTab.AdditionalParameters.attribute ~= nil and ret then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
        end
    
    else
        result = false
    end


    if paraTab.AdditionalParameters.parametric ~=nil then
        local limitTab = paraTab.limit
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)

    else
        if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result==false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end

end

function func.dp_parse( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local input = paraTab.Input
    local ret = ""
    if paraTab.AdditionalParameters.pattern ~=nil then
        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(input,pattern)
    end
    local result = true
    if ret~=nil and ret~="" then

        if paraTab.AdditionalParameters.attribute ~= nil and ret then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
        end
    else
        result = false
    end
    if paraTab.AdditionalParameters.parametric ~=nil then
        local limitTab = paraTab.limit
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
    else
        if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result==false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end
    if ret==nil then
        ret =""
    end
    return ret

end


function func.dp_writeReadtBitHex( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337
    local cmd = paraTab.Commands
    
    dock_port.readString(slot_num,port) -- clear buffer
    local ret = dock_port.writeRead(cmd.."\r","] :-)",5000,slot_num,port)
    
    flow_log.writeFlowLog(ret)
    if paraTab.AdditionalParameters.pattern ~=nil then
        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret,pattern)
    end

    if paraTab.AdditionalParameters.getbit ~=nil then

        local bit = tonumber(paraTab.AdditionalParameters.getbit)
        if(bit == 0) then
            ret =  math.mod(ret,2)
        else
            local temp = math.floor((ret/math.pow(2,bit)))
            ret =  temp%2
            Log.LogInfo('$***dock port dp_writeReadGetbit.  :  '..tostring(ret))
        end

    end

    if paraTab.AdditionalParameters.hex ~=nil then
        local bit = tonumber(paraTab.AdditionalParameters.hex)
        local temp = hex2bin(ret,0,bit)
        local data = binary_to_data(temp)
        --Log.LogInfo('$***hex2  :  '..tostring(data))
        ret =  string.format("0x%02x",data)
    end
    local result = true
    if ret~=nil and ret~="" then

        if paraTab.AdditionalParameters.attribute ~= nil and ret then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
        end
    
    else
        result = false
    end
    if paraTab.AdditionalParameters.parametric ~=nil then
        local limitTab = paraTab.limit
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)

    else
        if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result==false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end

end


return func


