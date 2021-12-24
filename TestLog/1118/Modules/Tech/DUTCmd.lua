local DUTCmd = {}
local Log = require("Matchbox/logging")
local csvCommon = require("Matchbox/Matchbox")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")
local createRecordAndLog = require("Tech/Record").createRecordAndLog

function DUTCmd.decimalToBinary(v_dec)
    local bin_str = ""
    if v_dec == 0 or v_dec == nil then
        return 0
    end
    while v_dec > 0 do
        local rr = math.modf(v_dec % 2)
        bin_str = rr .. bin_str
        v_dec = (v_dec - rr) / 2
    end
    return bin_str
end

function DUTCmd.hexToBinary(value, bit_start, bit_end, flag)
    --[1]value [2]bit_start [3]bit_end
    value = DUTCmd.decimalToBinary(tonumber(value))
    if flag == nil then
        value = string.format("%08d", value)
    end
    if bit_start then
        bit_start = string.len(value) - bit_start
        if not (bit_end) then
            bit_end = bit_start
            return string.sub(value, bit_end, bit_start)
        end
        bit_end = string.len(value) - bit_end
        return string.sub(value, bit_end, bit_start)
    end
    return value
end

function DUTCmd.binaryToData(arg)
    local data = 0
    local binary_arg = {}
    if type(arg) == "string" or type(arg) == "number" then
        for v in string.gmatch(arg, "%d") do
            if tonumber(v) > 1 then
                return assert("Input_binary_incorrect!")
            end
            table.insert(binary_arg, v)
        end
    else
        binary_arg = arg
    end
    for i = 1, #binary_arg do
        data = data + math.pow(2, (#binary_arg - i)) * binary_arg[i]
    end
    return data
end

function DUTCmd.dutRead(paraTab)
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"
    if dut.isOpened() ~= 1 then
        dut.open(2)
    end
    local startTime = os.time()
    local timeout = paraTab.Timeout
    if timeout == nil then
        timeout = 2
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
    until (os.difftime(os.time(), lastRetTime) >= timeout)
    local result = content
    flow_log.writeFlowLog(result)
    dut.setDelimiter(default_delimiter)
    return content
end

function DUTCmd.sendCmd(paraTab, sendAsData)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname or ""

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

    local defalut_val = paraTab.Input
    if defalut_val ~= nil then
        cmd = cmd .. " " .. defalut_val
    end

    local cmdReturn = ""

    if cmd ~= nil then

        if (paraTab.AdditionalParameters.delimiter ~= nil) then
            dut.setDelimiter(paraTab.AdditionalParameters.delimiter)
        else
            dut.setDelimiter("] :-) ")
        end

        local commands = cmd .. ";"
        for command in string.gmatch(commands, "(.-);") do
            flow_log.writeFlowLog("[dut-send:] " .. command)
            dut.write(command)
            local status, temp = xpcall(dut.read, debug.traceback, timeout)
            flow_log.writeFlowLog("[dut-recv:] " .. tostring(temp))
            if status and temp ~= nil then
                cmdReturn = cmdReturn .. temp
            end
        end
    end
    --flow_log.writeFlowLog(cmdReturn)
    return cmdReturn
end

function DUTCmd.sendCmdAndParse(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname or ""
    local tick = paraTab.AdditionalParameters.tick
    flow_log.writeFlowLogStart(paraTab)
    if tick == nil then
        Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    end
    local dut = Device.getPlugin("dut")
    local slot_num = tonumber(Device.identifier:sub(-1))
    if dut.isOpened() ~= 1 then
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
        dut.setDelimiter("] :-) ")
    end

    local ret = nil
    local result = nil

    local timeout_sub = 5
    if paraTab.AdditionalParameters.timeout ~= nil then
        timeout_sub = tonumber(paraTab.AdditionalParameters.timeout)
    end

    if paraTab.AdditionalParameters.mark ~= nil then
        xpcall(DUTCmd.dutRead, debug.traceback, { Commands = "\r\n", Timeout = timeout_sub })
    end

    result, ret = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab, 1)
    local raw_ret = ret
    --flow_log.writeFlowLog(ret)
    if paraTab.AdditionalParameters.pattern ~= nil then

        if paraTab.AdditionalParameters.escape ~= nil then
            ret = string.gsub(ret, "\r", "")
            ret = string.gsub(ret, "\n", "")
        end

        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret, pattern)

        if paraTab.AdditionalParameters.bit ~= nil then
            local bit_num = tonumber(paraTab.AdditionalParameters.bit)
            if paraTab.AdditionalParameters.suffix ~= nil then
                ret = "0x" .. tostring(ret)
            end
            ret = DUTCmd.hexToBinary(ret, bit_num, nil, nil)
        end

        if ret ~= nil and ret ~= "" then

            if paraTab.AdditionalParameters.attribute ~= nil and ret then
                DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
            end

        else
            result = false
        end
    else
        result = true
    end
    if paraTab.AdditionalParameters.patterns ~= nil then
        local pattern = paraTab.AdditionalParameters.patterns
        local a, b = string.match(ret, pattern)
        ret = b .. a
    end
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" then

        if paraTab.AdditionalParameters.parametric ~= nil then
            local limitTab = paraTab.limit
            local limit = nil
            if limitTab then
                limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
            end
            result = Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
            if result == false and paraTab.AdditionalParameters.fa_sof == "YES" then
                error('DUTCmd.sendCmdAndParse is error')
            end
            --flow_log.writeFlowLimitAndResult(paraTab, ret)
        else
            local limitTab = paraTab.limit
            local limit = nil
            local str_limit = nil
            if limitTab then
                limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
                if limit ~= nil then
                    if limit.units == "string" then
                        str_limit = limit.upperLimit
                        --flow_log.writeFlowLog("str_limit=="..str_limit)
                    end
                end
            end
            if str_limit ~= nil then
                if tostring(ret) ~= str_limit then
                    result = false
                    -- Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
                    -- flow_log.writeFlowLimitAndResult(paraTab, result)
                end
            end
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
            --flow_log.writeFlowLimitAndResult(paraTab, result)
        end
    end

    if paraTab.AdditionalParameters.return_val ~= nil then
        return raw_ret
    end

    if not result then
        ret = ""
    end
    if tick == nil then
        Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(paraTab, result)
    return ret

end

function DUTCmd.parseWithRegexString(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)

    local ret = paraTab.Input
    local result = true
    flow_log.writeFlowLog(ret)
    if paraTab.AdditionalParameters.pattern ~= nil then
        if paraTab.AdditionalParameters.escape ~= nil then
            ret = string.gsub(ret, "\r", "")
            ret = string.gsub(ret, "\n", "")
        end

        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret, pattern)
        if paraTab.AdditionalParameters.bit ~= nil then
            local bit_num = tonumber(paraTab.AdditionalParameters.bit)
            if paraTab.AdditionalParameters.suffix ~= nil then
                ret = "0x" .. tostring(ret)
            end
            ret = hex2bin(ret, bit_num, nil)
        end

        if ret ~= nil and ret ~= "" then

            if paraTab.AdditionalParameters.attribute ~= nil and ret then
                DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
            end

        else
            result = false
        end
    else
        if ret == nil or ret == "" then
            result = false
        end
    end
    local limitTab = paraTab.limit
    local limit = nil
    local str_limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        if limit ~= nil then
            if limit.units == "string" then
                str_limit = limit.upperLimit
                --flow_log.writeFlowLog("str_limit=="..str_limit)
            end
        end
    end
    if str_limit ~= nil then
        if tostring(ret) ~= str_limit then
            result = false
            -- Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
            -- flow_log.writeFlowLimitAndResult(paraTab, result)
        end
    end
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" then
        if paraTab.AdditionalParameters.parametric ~= nil then
            -- local limitTab = paraTab.limit
            -- local limit = nil
            -- if limitTab then
            --     limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
            -- end
            Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
            flow_log.writeFlowLimitAndResult(paraTab, ret)
        else
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
            flow_log.writeFlowLimitAndResult(paraTab, result)
        end
    end
    if #ret <= 0 then
        return ""
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab, result)
    return ret

end

function DUTCmd.detectHibernation(paraTab)

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(paraTab)

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

        if string.find(content, "Event quiesce: TongaPMGR") then
            xpcall(dut.read, debug.traceback, 0.1, '')
            result = true
            break
        end

    until (os.difftime(os.time(), lastRetTime) >= timeout)

    flow_log.writeFlowLog(content)
    dut.setDelimiter(default_delimiter)
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(paraTab, result)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
end

function DUTCmd.enterDFUWithDC(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)

    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    dock_port.setDetectString("DFU Entered", slot_num, port)
    dock_port.waitForString(5000, slot_num, port)
    local read_str = dock_port.readString(slot_num, port)
    flow_log.writeFlowLog(read_str)
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")

end

function DUTCmd.sendCmdAndParseWithDC(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(paraTab)

    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)

    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local cmd = paraTab.Commands
    local port = paraTab.AdditionalParameters.port or 31337

    if tonumber(port) == 31336 then


        local command = string.gsub(tostring(cmd), "*", ",")
        Log.LogInfo("dock channel port:" .. tostring(port) .. " command:" .. command)
        flow_log.writeFlowLog("[31336-Send:]" .. command)
        local ret = dock_port.writeRead(command .. "\r\n", "^-^", 2000, slot_num, tonumber(port))
        flow_log.writeFlowLog("[31336-Recv:]" .. tostring(ret))
        Log.LogInfo('$*** dock channel result: ' .. ret)
        local result = false
        if string.find(ret, "%^%-%^") then
            result = true
        end
        if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
        if result == false then
            error('dock channel setting is error:' .. command)
        end

        Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
        flow_log.writeFlowLimitAndResult(paraTab, result)
        return result

    else

        local commands = cmd .. ";"
        local ret = ""

        dock_port.readString(slot_num, tonumber(port)) -- clear buffer
        for command in string.gmatch(commands, "(.-);") do
            flow_log.writeFlowLog("[31337-Send:]" .. command)
            local sub_ret = dock_port.writeRead(command .. "\r", "] :-)", 5000, slot_num, tonumber(port))
            flow_log.writeFlowLog("[31337-Recv:]" .. tostring(sub_ret))
            if sub_ret ~= nil then
                sub_ret = string.gsub(sub_ret, command, "")
                ret = ret .. sub_ret
            end
        end

        local raw_ret = ret
        if paraTab.AdditionalParameters.pattern ~= nil then
            local pattern = paraTab.AdditionalParameters.pattern
            ret = string.match(ret, pattern)
        end

        if paraTab.AdditionalParameters.patterns ~= nil then
            local pattern = paraTab.AdditionalParameters.patterns
            local a, b, c, d, e, f, g, h = string.match(ret, pattern)
            ret = a .. " " .. b .. " " .. c .. " " .. d .. " " .. e .. " " .. f .. " " .. g .. " " .. h
        end

        if paraTab.AdditionalParameters.bit ~= nil then
            local bit_num = tonumber(paraTab.AdditionalParameters.bit)
            if paraTab.AdditionalParameters.suffix ~= nil then
                ret = "0x" .. tostring(ret)
            end
            ret = DUTCmd.hexToBinary(ret, bit_num, nil, nil)
        end

        if paraTab.AdditionalParameters.getbit ~= nil then

            local bit = tonumber(paraTab.AdditionalParameters.getbit)
            if (bit == 0) then
                ret = math.mod(ret, 2)
            else
                local temp = math.floor((ret / math.pow(2, bit)))
                ret = temp % 2
                Log.LogInfo('$***dock port dp_writeReadGetbit.  :  ' .. tostring(ret))
            end

        end

        if paraTab.AdditionalParameters.hex ~= nil then
            local bit = tonumber(paraTab.AdditionalParameters.hex)
            local temp = DUTCmd.hexToBinary(ret, 0, bit, nil)
            local data = DUTCmd.binaryToData(temp)
            --Log.LogInfo('$***hex2  :  '..tostring(data))
            ret = string.format("0x%02x", data)
        end

        local result = true
        --------------------
        local limitTab = paraTab.limit
        local limit = nil
        local str_limit = ""
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
            if limit ~= nil and limit.units == "string" then
                str_limit = limit.upperLimit
                --flow_log.writeFlowLog("str_limit=="..str_limit)
            end
            -- if str_limit ~= "" and tostring(ret) ~= tostring(str_limit) then
            --     result = false
            -- end
        end
        -------------------------
        if ret ~= nil and ret ~= "" then

            if paraTab.AdditionalParameters.attribute ~= nil and ret then

                local limitTab = paraTab.limit
                local limit = nil
                local str_limit = ""
                if limitTab then
                    limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
                    if limit ~= nil then
                        str_limit = limit.upperLimit
                        --flow_log.writeFlowLog("str_limit=="..str_limit)
                    end
                    if str_limit ~= "" and tostring(ret) ~= tostring(str_limit) then
                        result = false
                    end
                end

                DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, ret))
            elseif limit ~= nil and limit.units == "string" and paraTab.AdditionalParameters.attribute == nil and ret then
                if str_limit ~= "" and tostring(ret) ~= tostring(str_limit) then
                    result = false
                end

            end

        else
            result = false
        end

        if paraTab.AdditionalParameters.parametric ~= nil then
            local limitTab = paraTab.limit
            local limit = nil
            if limitTab then
                limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
            end
            Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
            flow_log.writeFlowLimitAndResult(paraTab, ret)
        else
            if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or result == false then
                Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
            end
            flow_log.writeFlowLimitAndResult(paraTab, result)
        end

        if paraTab.AdditionalParameters.return_val ~= nil then
            return raw_ret
        end

        if not result then
            ret = ""
        end
        Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
        flow_log.writeFlowLimitAndResult(paraTab, "ture")
        return ret
    end
end

function DUTCmd.checkStatusAndParse(paraTab)
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname or ""
    flow_log.writeFlowLogStart(paraTab)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local dut = Device.getPlugin("dut")
    local slot_num = tonumber(Device.identifier:sub(-1))
    if dut.isOpened() ~= 1 then
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
        dut.setDelimiter("] :-) ")
    end

    local ret = nil
    local result = nil
    local pattern = nil

    result, ret = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab, 1)

    if paraTab.AdditionalParameters.pattern ~= nil then
        pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret, pattern)
    end

    flow_log.writeFlowLog("ret0 --> " .. ret)
    if paraTab.AdditionalParameters.parametric ~= nil then
        local limitTab = paraTab.limit
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end

        for i=1,5 do
            if limit ~= nil and  ret ~=  tostring(limit.upperLimit) then
                os.execute("sleep 0.3")
                result, ret = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab, 1)
                ret = string.match(ret, pattern)
                flow_log.writeFlowLog("ret"..tostring(i).." --> " .. ret)
            end
        end

        flow_log.writeFlowLimitAndResult(paraTab, ret)
        result = Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
    end
    return ret
end

return DUTCmd
