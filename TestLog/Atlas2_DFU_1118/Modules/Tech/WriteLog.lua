local WriteLog = {}

function WriteLog.writeFlowLogStart(param)
    if param ~= nil then
        local testname = param.AdditionalParameters.testname or param.Technology
        local subtestname = param.AdditionalParameters.subtestname or param.TestName
        local subsubtestname = param.AdditionalParameters.subsubtestname
        if not param.isNotTop and (testname or subtestname or subsubtestname) then
            local slot_num = tonumber(Device.identifier:sub(-1))
            local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot" .. tostring(slot_num) .. "/system/FCT_flow.log"
            local f = io.open(filepath, "a")
            if f == nil then
                return nil, "failed to open file";
            end
            local str = "==Test: " .. tostring(testname) .. "\r\n==SubTest: " .. tostring(subtestname) .. "\r\n==SubSubTest: " .. tostring(subsubtestname) .. "\r\n"
            local time = Device.getPlugin("TimeStamp")
            f:write("\r\n" .. time.getTime() .. "\r\n" .. tostring(str))
            f:close()
        end
    end
end

function WriteLog.writeFlowLog(str)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot" .. tostring(slot_num) .. "/system/FCT_flow.log"
    local f = io.open(filepath, "a")
    if f == nil then
        return nil, "failed to open file";
    end
    local time = Device.getPlugin("TimeStamp").getTime()
    local pos = 0
    str = tostring(str)
    for st, sp in function()
        return string.find(str, '\n', pos, true)
    end do
        f:write(time .. "\t  " .. string.sub(str, pos, st - 1) .. "\n")
        pos = sp + 1
    end
    if string.sub(str, pos) ~= '' then
        f:write(time .. "\t  " .. string.sub(str, pos) .. "\n")
    end
    f:close()
end

function WriteLog.writeFlowLimitAndResult(param, result)
    if param ~= nil then
        local testname = param.AdditionalParameters.testname or param.Technology
        local subtestname = param.AdditionalParameters.subtestname or param.TestName
        local subsubtestname = param.AdditionalParameters.subsubtestname
        if not param.isNotTop and (testname or subtestname or subsubtestname) then
            local limitTab = param.limit
            local limit
            if limitTab then
                limit = limitTab[param.AdditionalParameters.subsubtestname]
            end

            local lower = ''
            local upper = ''
            if limit ~= nil then
                lower = limit.lowerLimit
                upper = limit.upperLimit
            end
            if result == nil then
                result = ""
            end
            local slot_num = tonumber(Device.identifier:sub(-1))
            local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot" .. tostring(slot_num) .. "/system/FCT_flow.log"
            local f = io.open(filepath, "a")
            if f == nil then
                return nil, "failed to open file";
            end
            local str = "  lower: " .. tostring(lower) .. "; upper: " .. tostring(upper) .. "; value: " .. tostring(result) .. "\r\n"
            local time = Device.getPlugin("TimeStamp")
            f:write(time.getTime() .. "\t" .. tostring(str) .. "\r\n\r\n")
            f:flush()
        end
    end
end

return WriteLog


