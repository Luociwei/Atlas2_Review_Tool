local func = {}


function func.writeFlowLogStart(param)
    if param ~=nil then
    local slot_num = tonumber(Device.identifier:sub(-1))
        local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot"..tostring(slot_num).."/system/flow.log"

        local testname = param.AdditionalParameters.testname or param.Technology
        local subtestname = param.AdditionalParameters.subtestname or param.TestName
        local subsubtestname = param.AdditionalParameters.subsubtestname
        
        local f = io.open(filepath, "a")
        if f == nil then return nil, "failed to open file"; end
        local str = "==Test: "..tostring(testname).."\r\n==SubTest: "..tostring(subtestname).."\r\n==SubSubTest: "..tostring(subsubtestname).."\r\n"
        --f:write(tostring(os.date("%Y-%m-%d %H:%M:%S\r\n"))..tostring(str))
        local time = Device.getPlugin("TimeStamp")
        f:write(time.getTime().."\r\n"..tostring(str))
        f:close()
    end
end


function func.writeFlowLog(str)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot"..tostring(slot_num).."/system/flow.log"

    local f = io.open(filepath, "a")
    if f == nil then return nil, "failed to open file"; end
    --f:write(tostring(os.date("%Y-%m-%d %H:%M:%S\t"))..tostring(str).."\r\n")
    local time = Device.getPlugin("TimeStamp")
    f:write(time.getTime().."\t"..tostring(str).."\r\n")
    f:close()
end

function func.writeFlowLimitAndResult(param,result)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot"..tostring(slot_num).."/system/flow.log"

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end

    local lower = ""
    local upper = ""
    if limit ~= nil then
        lower = limit.lowerLimit
        upper = limit.upperLimit
    end
    if result == nil then
        result = ""
    end

    local ret = nil
    local f = io.open(filepath, "a")
    if f == nil then return nil, "failed to open file"; end
    local str = "  lower: "..tostring(lower).."; upper: "..tostring(upper).."; value: "..tostring(result).."\r\n"
    --f:write(tostring(os.date("%Y-%m-%d %H:%M:%S\t"))..tostring(str).."\r\n\r\n")
    local time = Device.getPlugin("TimeStamp")
    f:write(time.getTime().."\t"..tostring(str).."\r\n\r\n")
    f:close()
    
end

return func


