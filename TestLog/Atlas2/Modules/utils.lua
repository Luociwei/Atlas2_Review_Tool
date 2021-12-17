--   utils.lua
--   Torchwood

--   Created by Roy Yang on 2020/7/13.
--   Copyright © 2020 HWTE. All rights reserved.

v_pattern = "%${[\'\"]?(%a+[%w_%-]-)[\'\"]?}" -- ${VAR}

local utils = {}

function utils.print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function utils.hasKey(tab, val)
    for k, v in pairs(tab) do
        -- We grab the first index of our sub-table instead
        if k == val then
            return true
        end
    end
    return false
end

function utils.allKeys(tab)
    local keySet={}
    for k,v in pairs(tab) do
        keySet[#keySet+1] = k
    end
    return keySet
end

function utils.hasValue(tab, val)
    for k, v in pairs(tab) do
        -- We grab the first index of our sub-table instead
        if v == val then
            return true
        end
    end
    return false
end

function utils.file_exists(name)
    if name then
        local f=io.open(name,"r")
        if f~=nil then io.close(f) return true else return false end
    else
        return false
    end
end


function utils.stringSplit(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function traceback(msg)
    local err = {}
    err.message = tostring(msg)
    err.stacktrace = debug.traceback()
    print("Exception captured: " .. err.message .. ", stacktrace: " .. err.stacktrace)
    return err
end

function utils.PCallWithTraceback(func, ...)
    local args = { ... }
    return xpcall(function() func(table.unpack(args)) end, traceback)
end

function utils.convertNil(val)
    if tostring(val) == "nil" then
        return nil
    end
    return val
end

function utils.currFileName()
    local path = debug.getinfo(2, 'S').short_src
    if path then
        return string.match(path, "/([^/]+%.lua)")
    else
        return ""
    end
end

function utils.clone(org)
    local function copy(org, res)
        for k,v in pairs(org) do
            if type(v) ~= "table" then
                res[k] = v;
            else
                res[k] = {};
                copy(v, res[k])
            end
        end
    end
    local res = {}
    copy(org, res)
    return res
end

function utils.hex2str(hex)
    local str, n = hex:gsub("(%x%x)[ ]?", function (word)
        return string.char(tonumber(word, 16))
    end)
    return str
end

function utils.str2hex(str)
    local fullHex = ""
    for i = 1, string.len(str) do
        local charCode = tonumber(string.byte(str, i, i));
        local hexStr = string.format("%02X", charCode);
        if i == 1 then
            fullHex = hexStr
        else
            fullHex = fullHex .. hexStr
        end
    end
    return fullHex
end

return utils
