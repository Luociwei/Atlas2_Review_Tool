local func = {}

function func.writeFlowLogStart(testname,subtestname,subsubtestname)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot"..tostring(slot_num).."/system/flow.log"
    local ret = nil
    local f = io.open(filepath, "a")
    if f == nil then return nil, "failed to open file"; end
    local str = "==Test: "..tostring(testname).."\r\n==SubTest: "..tostring(subtestname).."\r\n==SubSubTest: "..tostring(subsubtestname).."\r\n"
    ret = f:write(tostring(os.date("%Y-%m-%d %H:%M:%S\r\n"))..tostring(str))
    f:close()
end

function func.writeFlowLimit(testname,subtestname,subsubtestname)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot"..tostring(slot_num).."/system/flow.log"
    local ret = nil
    local f = io.open(filepath, "a")
    if f == nil then return nil, "failed to open file"; end
    local str = "==Test: "..tostring(testname).."\r\n==SubTest: "..tostring(subtestname).."\r\n==SubSubTest: "..tostring(subsubtestname).."\r\n"
    ret = f:write(tostring(os.date("%Y-%m-%d %H:%M:%S\r\n"))..tostring(str))
    f:close()
end

function func.writeFlowLog(str)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local filepath = "/Users/gdlocal/Library/Logs/Atlas/active/group0-slot"..tostring(slot_num).."/system/flow.log"
    local ret = nil
    local f = io.open(filepath, "a")
    if f == nil then return nil, "failed to open file"; end
    ret = f:write(tostring(os.date("%Y-%m-%d %H:%M:%S\r\n"))..tostring(str))
    f:close()
end

return func


