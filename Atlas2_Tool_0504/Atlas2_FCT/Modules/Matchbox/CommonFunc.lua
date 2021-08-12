-------------------------------------------------------------------
----***************************************************************
----common functions
----***************************************************************
-------------------------------------------------------------------

local CommonFunc = {}
-- special string used to store nil value
-- to distinguish a variable that is not defined.
CommonFunc.NIL = 'NIL_VARIABLE_VALUE'

-- string split by a single delimiter.
-- Delimiter ",,," will be treated as ",,,".
-- Empty element between delimiters will be treated as empty string.
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitString("a,b,,,c,d",",") => {"a","b","","","c","d"}
function CommonFunc.splitString(input, delimiter)
    if not input or not delimiter then return nil end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if delimiter=='' then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

-- string split by a mixed delimiter.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitBySeveralDelimiter("a&&b||c&&d","&|") => {"a","b","c","d"}
function CommonFunc.splitBySeveralDelimiter(input,delimiter)
    if not input or not delimiter then return nil end
    local resultStrArr = {}
    string.gsub(input,'[^'..delimiter..']+',function (w)
        table.insert(resultStrArr,w)
    end)
    return resultStrArr
end

-- gain delimiter sequence in a string.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return delimiter array in a string
-- e.g. gainDelimiterSequence("a&&b||c&&d","&|") => {"&&","||","&&"}
function CommonFunc.gainDelimiterSequence(input,delimiter)
    if not input or not delimiter then return nil end
    local resultStrArr = {}
    string.gsub(input,'['..delimiter..']+',function (w)
        table.insert(resultStrArr,w)
    end)
    return resultStrArr
end

-- remove extra spaces at begin and end
-- @param str: input string
-- @return string after trimmed
-- e.g. trim(" a == b  ") => "a == b"
function CommonFunc.trim(str)
    if not str then
        return nil
    else
        return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
    end
end

-- present table as key-value string format
-- @param o: input table
-- @return key-value string format
-- e.g. dump({"a","b","c",["d"] = 4, ["e"] = 5,}) => { [1] = a,[2] = b,[3] = c,["d"] = 4,["e"] = 5,}
function CommonFunc.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. CommonFunc.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- deepCompare if 2 object are the same, support table recursively value compare
-- @param t1: a table to compare
-- @param t2: a table to compare against t1.
function CommonFunc.deepCompare(t1, t2)
    local type1 = type(t1)
    local type2 = type(t2)
    if type1 ~= type2 then return false end
    if type(t1) ~= 'table' and type(t2) ~= 'table' then return t1 == t2 end

    -- keys that has been compared
    local compared = {}
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not CommonFunc.deepCompare(v1, v2) then return false end
        compared[k1] = true
    end

    for k2, v2 in pairs(t2) do
        if not compared[k2] then return false end
    end
    return true
end

-- return true if given table1 and table2 are identical: same length, same values.
-- return false and the different node index.
-- used to check if CSV title row is expected.
-- only works for array; do not support dictionary with key-value pairs.
function CommonFunc.arrayCmp(t1, t2)
    local i = 1
    while true do
        if t1[i] == nil and t2[i] == nil then
            return true
        end
        if t1[i] ~= t2[i] then
            return false, i
        end
        i = i + 1
    end
end

-- check if file exists at designated path
-- @param path: string type
-- @return whether the file exists
-- e.g. fileExists("/Users/gdlocal/Library/Atlas2/Assets/Main.csv") => true
function CommonFunc.fileExists(path)
  if not path then return nil end
  local file = io.open(path, "rb")
  if file then
    file:close()
    return true
  end
  return false
end

-- read file contents
-- @param path: string type
-- @return file contents, string type
function CommonFunc.fileRead(path)
  if not path then return nil end
  local file = io.open(path, "r")
  if file then
    data = file:read("*all")
    file:close()
    return data
  end
  return ""
end

-- check if key exists in a dictionary
-- e.g. hasKey({["d"] = 4, ["e"] = 5,},"d") => true
function CommonFunc.hasKey(tab, key)
  if not tab or not key then return nil end
  for k, v in pairs(tab) do
      if k == key then
          return true
      end
  end
  return false
end

-- check if value exists in an array
-- e.g. hasVal({"d", "e",},"d") => true
function CommonFunc.hasVal(valueArr,valueStr)
    for _,value in ipairs(valueArr) do
        if value == valueStr then
            return true
        end
    end
    return false
end

-- return keys of a table
-- e.g. tableKeys({4,5,["a"]="44",}) => {1,2,"a",}
function CommonFunc.tableKeys(input_table)
    if not input_table then return nil end
    local output_keys = {}
    for k, v in pairs(input_table) do
        table.insert(output_keys, k)
    end
    return output_keys
end

-- system sleep
function CommonFunc.sleep(n)
    os.execute("sleep " .. tonumber(n))
end

-- run function catch_f if function f throws any exception
function CommonFunc.try(f, catch_f)
    local status, exception = xpcall(f,debug.traceback)
    if not status
    then
        catch_f(exception)
    end
end

-- calculate boolean logic for condition column
-- @param str: input condition string
-- @return boolean value
-- e.g. calConditionVal(" sn == 2 && ver != 4",{["sn"] = "2",["ver"] = "4",["boardid"] = "C"}) => false
function CommonFunc.calConditionVal(str,conditionValueTable)
    if type(str) ~= "string" then
        error("expect a string equation")
    end

    local boolStrArr = CommonFunc.splitBySeveralDelimiter(CommonFunc.trim(str),"&|")
    local boolLogicArr = CommonFunc.gainDelimiterSequence(CommonFunc.trim(str),"&|")
    local boolValArr = {}
    for _,v in ipairs(boolStrArr) do
        local vGroup = CommonFunc.splitBySeveralDelimiter(v,"!=")
        local vLogic = CommonFunc.gainDelimiterSequence(v,"!=")[1]
        local vLeft = CommonFunc.trim(vGroup[1])
        local vRight = CommonFunc.trim(vGroup[2])
        local vLeftVal,vRightVal
        if conditionValueTable[vLeft] == nil and conditionValueTable[vRight] == nil then
            error('Condition ' .. vLeft .. ' or ' .. vRight .. ' value not set')
        end

        if conditionValueTable[vLeft] then
            vLeftVal = conditionValueTable[vLeft]
        else
            vLeftVal = tostring(vLeft)
        end

        if conditionValueTable[vRight] then
            vRightVal = conditionValueTable[vRight]
        else
            vRightVal = tostring(vRight)
        end

        if vLogic == "==" then
            table.insert(boolValArr,vLeftVal == vRightVal)
        elseif vLogic == "!=" then
            table.insert(boolValArr,vLeftVal ~= vRightVal)
        else
            -- other valid boolean logics can be expanded here

            error(string.format("Invalid operator : %s",vLogic))
        end
    end

    local conditionResult = boolValArr[1]
    for i,v in ipairs(boolLogicArr) do
        if v == "&&" then
            conditionResult = conditionResult and boolValArr[i+1]
        elseif v == "||" then
            conditionResult = conditionResult or boolValArr[i+1]
        else
            -- other valid boolean logics can be expanded here

            error(string.format("Invalid operator : %s",v))
        end
    end

    return conditionResult
end

-- parse and return parameter list for further indexing, support dictionaries and arrays
-- @param paraStr: input parameter string
-- @return parameter dictionary or array
-- e.g. parseParameter("{\"Input\":\"success\",\"Output\":\"SN\",\"timeout\": 50}")
--      => { ["Input"] = "success",["Output"] = "SN",["timeout"] = "50",}
--      parseParameter("[a,b,c,1,2,3]")
--      => {"a","b","c","1","2","3"}
function CommonFunc.parseParameter(paraStr)
    local paraList = {}
    local json = require("Matchbox/json")
    if paraStr == "" then
        return paraList
    else
        return json.decode(paraStr)
    end
end

-- parse static conditions and store in an array
-- @param allowValStr: allowable value string, seperate by ";"
-- @return condition array
-- e.g. parseValArr("00011a;00011b;000111") => {"00011a","00011b","000111",}
function CommonFunc.parseValArr(allowValStr)
    local allowValArr = {}
    allowValStr = CommonFunc.trim(allowValStr)
    allowValArr = CommonFunc.splitBySeveralDelimiter(allowValStr,";")
    for i in ipairs(allowValArr) do
        allowValArr[i] = CommonFunc.trim(allowValArr[i])
    end
    return allowValArr
end

-- run shell commands
function CommonFunc.runShellCmd(cmd)
    local RunShellCommand = Device.getPlugin("RunShellCommand")
    return RunShellCommand.run(cmd)
end

-- create extra log
function CommonFunc.exLog(...)
  local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
  local homePath = RunShellCommand.run("echo ~")
  homePath = homePath.output
  homePath = CommonFunc.trim(homePath)
  local file = io.open(homePath .. "/Desktop/extra.log", "a+")
  if file then
    for _,v in ipairs({...}) do
        file:write(tostring(v))
    end
    file:close()
    return nil
  end
  return nil
end

-- return tech sequence from tech csv for indexing
function CommonFunc.techSequence(techPath)
    local ftcsv = require("Matchbox/ftcsv")
    local techCsvTab = ftcsv.parse(techPath,",")
    local techSequence = {}
    for _,rowContent in ipairs(techCsvTab) do
        if rowContent.TestName ~= "" then
            techSequence[#techSequence+1] = rowContent.TestName
        end
    end
    return techSequence
end

-- return a cloned table.
function CommonFunc.clone(org)
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

-- create a read-only reference of a given table.
-- caller specify what error msg to report
-- when table write is attempted.
function CommonFunc.readOnly(t, msg)
    local proxy = {}
    local mt = {
        __index = t,
        __newindex = function(t, name, value)
            local msg = 'Not allowed to modify local/global/condition table; use tech csv Output column to set values.'
            error(msg, 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

-- the "map" operation: generate a new array by calling given function
-- to every item in current array
function CommonFunc.map(func, t)
    local ret = {}
    for i=1, #t, 1 do
        ret[i] = func(t[i])
    end
    return ret
end

-- process message to fit in failure reason:
-- 1. remove line returns
-- 2. trim to 512 bytes
function CommonFunc.trimFailureMsg(msg)
    --remove all \r and \n so this does not corrupt records.csv
    msg = string.gsub(msg, '[\r\n]', '; ')

    -- insight does not allows error message > 512 bytes.
    if (#msg > 512) then
        msg = string.sub(msg, 1, 509) .. '...'
    end

    return msg
end

-- check if given string is boolean Y/N/y/n
function CommonFunc.isCharBooleanOrEmpty(c)
    return c ~= nil and CommonFunc.hasVal({'', 'Y', 'N'}, c:upper())
end

-- check if given item is nil or empty, for csv cell.
function CommonFunc.notNILOrEmpty(c)
    return c ~= nil and c ~= ''
end


return CommonFunc
