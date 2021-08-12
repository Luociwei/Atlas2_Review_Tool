local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'

function func.parse( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input

    local pattern = paraTab.AdditionalParameters.pattern
    local matchValue = nil

    local matchs = Regex.groups(ret, pattern, 1)
    if #(matchs[1]) > 0 then
        if ( paraTab.AdditionalParameters.attribute ) then
            matchValue = matchs[1][1]
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, matchs[1][1]) )
        end
        if paraTab.AdditionalParameters.target ~= nil then
            if matchs[1][1] == paraTab.AdditionalParameters.target then
                Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
            else
                Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
            end
        else
            Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
        end
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
    return matchValue
end

function func.parseByte( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input
    local matchValue = nil

    local pattern = paraTab.AdditionalParameters.pattern
    local matchs = Regex.groups(ret, pattern, 1)
    if #(matchs[1]) > 0 then
        local result = matchs[1][1]
        if string.sub(paraTab.AdditionalParameters.attribute, 1, 4) == "RFEM" then
            result = string.gsub( result, '\r', '' )
            result = string.gsub( result, '\n', '' )
            result = string.gsub( result, ' ', '' )
        end
        result = comFunc.trim(result)
        matchValue = result
        DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, result ) )
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
    return matchValue
end

function func.setAddedCondition( paraTab )
    -- local logPath = Device.userDirectory .. "/uart.log"
    -- local content = comFunc.fileRead(logPath)
    local content = paraTab.Input
    local expect = paraTab.AdditionalParameters.expect
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    if content and string.find(content, expect) ~= nil then
        return "TRUE"
    else
        return "FALSE"
    end
end

function func.compare( paraTab )
    local Regex = Device.getPlugin("Regex")
    -- local logPath = Device.userDirectory .. "/uart.log"
    -- local content = comFunc.fileRead(logPath)
    local readVal = paraTab.Input
    local content = tostring(paraTab.InputValues[2])
    local writeVal = ""

    local pattern = paraTab.AdditionalParameters.pattern
    local matchs = Regex.groups(content, pattern, 1)
    if #(matchs[1]) > 0 then
        writeVal = matchs[1][1]
    end

    Log.LogInfo("contentLen: " .. tostring(#content) .. '\n')
    Log.LogInfo("writeVal: " .. writeVal .. '\n')
    Log.LogInfo("readVal : " .. readVal  .. '\n')

    if readVal == writeVal then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
end

function func.getByteLen( paraTab )
    local ret = paraTab.Input
    if ret == nil then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
        return false
    end
    ret = string.gsub( ret, '0x', '')
    ret = string.gsub( ret, ' ', '')
    Log.LogInfo("Byte: " .. ret .. '\n')
    if #ret %2 == 0 then
        local limitTab = paraTab.limit
        local limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        Record.createParametricRecord(tonumber(#ret /2), paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,limit)
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
end

function func.versionCompare( paraTab )
    local vc = require("Tech/VersionCompare")
    local key = paraTab.AdditionalParameters.key
    local versions = vc()[key]
    local val = paraTab.Input
    local sku = ""

    Log.LogInfo( key .. ": " .. comFunc.dump(versions) .. '\n')

    if key == "WSKU" then
        local sn = tostring(paraTab.InputValues[2])
        if sn and #sn == 17 then
            local eeeecode = string.sub(sn,12,15)
            local vc = require("Tech/VersionCompare")
            local versions = vc()["EEEE_CODE"]
            for _,versionValue in ipairs(versions) do
                if string.find(versionValue,eeeecode) then
                    local eeeecode_info = comFunc.splitString(versionValue," ")
                    if eeeecode_info[5] then 
                        sku = eeeecode_info[5] .. " "
                    end
                    break
                end
            end
            local logPath = Device.userDirectory .. "/uart.log"
            local content = comFunc.fileRead(logPath)
            local Regex = Device.getPlugin("Regex")
            local pattern = paraTab.AdditionalParameters.pattern
            local matchs = Regex.groups(content, pattern, 1)
            if #(matchs[1]) > 0 then
                sku = sku .. matchs[1][1]
            end
        else
            Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,"miss input sn")
            return 
        end
    end

    local result = false

    if key == "WSKU" then

        Log.LogInfo( "target: " .. sku .. "    " .. val .. '\n' )
        for _, version in ipairs(versions) do
            if string.find(version, sku) ~= nil and string.find(version, val) ~= nil then
                result = true
                break
            end
        end
    else
        Log.LogInfo( "target: " .. val .. '\n' )
        for _, version in ipairs(versions) do
            if version == val then
                result = true
                break
            end
        end
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
end

return func