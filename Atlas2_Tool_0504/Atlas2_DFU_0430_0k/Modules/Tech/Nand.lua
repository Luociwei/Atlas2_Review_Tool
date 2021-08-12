local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local dutCmd = require("Tech/DUTCmd")
local Record = require 'Matchbox/record'

function func.nanduid( paraTab )
    local Regex = Device.getPlugin("Regex")

    -- local dut = Device.getPlugin("dut")
    -- local ret = dut.send(paraTab.Commands)
    local ret = dutCmd.sendCmd(paraTab)
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    local pattern = "(MSP \\d+ CH \\d+ Die \\d+):\\s([0-9A-F ]+)"
    local matchs = Regex.groups(ret, pattern, 1)

    for _, match in ipairs(matchs) do
        -- comFunc.exLog("index" .. index .. "match" .. comFunc.dump(match))
        -- for key, value in ipairs(match) do
        --     comFunc.exLog("key" .. key .. "value" .. value)
        -- end
        -- comFunc.exLog(match[1] .. "->" .. match[2])
        -- MSP 0 CH 0 Die 0
        local itemName = string.gsub( tostring(match[1]), ' ', '_' )
        local pattern2 = "MSP_(\\d+)_CH_(\\d+)_Die_(\\d+)"
        local matchs2 = Regex.groups(itemName, pattern2, 1)
        itemName = "MSP" .. matchs2[1][1] .. "_CH" .. matchs2[1][2] .. "_Die" .. matchs2[1][3]
        local attName = "NANDUID_" .. itemName
        DataReporting.submit( DataReporting.createAttribute(attName, tostring(match[2])) )
        Record.createBinaryRecord( true, paraTab.Technology, paraTab.TestName, itemName) 
    end

    if #matchs > 0 then
        local count = tonumber( Regex.groups(matchs[#matchs][1], "MSP (\\d+) CH", 1)[1][1] )
        DataReporting.submit( DataReporting.createAttribute("NAND_Total_Controller_Count", tostring(count+1)) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName,"NAND_Total_Controller_Count")
        DataReporting.submit( DataReporting.createAttribute("NAND_Total_Die_Count", tostring(#matchs)) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName,"NAND_Total_Die_Count")
    end
end

function func.nandcsid( paraTab )
    local Regex = Device.getPlugin("Regex")

    -- local dut = Device.getPlugin("dut")
    -- local ret = dut.send(paraTab.Commands)

    local ret = dutCmd.sendCmd(paraTab)
    local result = false

    local pattern
    local matchs

    pattern = "NANDID = ([0-9A-Za-z]+);"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        result = comFunc.trim(matchs[1][1]) == 'match'
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)

    pattern = "NANDCS = ([0-9A-Za-z =]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_CS", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "NAND_CS")
    end

    pattern = "FCE(\\d+)\\s+=\\s+(0x[0-9A-Z]+)"
    matchs = Regex.groups(ret, pattern, 1)
    for _, match in ipairs(matchs) do
        local itemName = "FCE0" .. tostring(match[1])
        local attributeName = "FCE" .. tostring(match[1])
        if attributeName == 'FCE0' then
            DataReporting.submit( DataReporting.createAttribute("NAND_ID", tostring(match[2])))
            Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "NAND_ID")
        end
        DataReporting.submit( DataReporting.createAttribute( attributeName, tostring(match[2])) )
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, itemName)
    end
end

function func.nandinfotool(paraTab)
    local Regex = Device.getPlugin("Regex")

    -- local dut = Device.getPlugin("dut")
    -- local ret = dut.send(paraTab.Commands)

    local ret = dutCmd.sendCmd(paraTab)

    if paraTab.AdditionalParameters.subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end

    local pattern
    local matchs

    pattern = "Vendor:\\s+([A-Za-z]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_VENDOR", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_VENDOR")
    end

    pattern = "Capacity:\\s+([0-9]+GB)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_Capacity", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_Capacity")
    end

    pattern = "Die Name:\\s+([0-9A-Za-z_]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_Die_Name", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_Die_Name")
    end

    pattern = "Controller UID:\\s+([0-9A-Za-z]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_Controller_UID", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_Controller_UID")
    end

    pattern = "Chip ID:\\s+([0-9A-Za-z]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_TYPE", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_TYPE")
    end

    pattern = "Cell Type:\\s+([A-Za-z]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_Cell_Type", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_Cell_Type")
    end
end

function func.nandgetidentify( paraTab )
    local Regex = Device.getPlugin("Regex")

    -- local dut = Device.getPlugin("dut")
    -- local ret = dut.send(paraTab.Commands)

    local ret = dutCmd.sendCmd(paraTab)

    local pattern
    local matchs

    pattern = "Model number\\s+: ([0-9A-Za-z ]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_Model_Number", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_Model_Number")
    end

    pattern = "Firmware version\\s+: ([0-9\\.]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("NAND_FW_Revision", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_FW_Revision")
    end

    pattern = "MSP revision\\s+: ([0-9\\.]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        DataReporting.submit( DataReporting.createAttribute("MSP_Revision", tostring(matchs[1][1])) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName, "NAND_MSP_Revision")
    end
    if paraTab.AdditionalParameters.subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
end

function func.nandsize( paraTab )
    local Regex = Device.getPlugin("Regex")
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local result = true
    local nandsize = "0GB"

    -- local dut = Device.getPlugin("dut")
    -- local ret = dut.send(paraTab.Commands)
    local ret = dutCmd.sendCmd(paraTab)
    if paraTab.AdditionalParameters.pattern then
        local pattern = paraTab.AdditionalParameters.pattern
        local matchs = Regex.groups(ret, pattern, 1)
        if matchs and #matchs > 0 and #matchs[1] > 0 then
            local size = tonumber( matchs[1][1] )
            size = size * 1024 / 1e9
            nandsize = string.format("%d",size) .. "GB"
            if paraTab.AdditionalParameters.attribute then
                DataReporting.submit( DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, nandsize))
            end
        else
            result = false
            failureMsg = 'match failed'
        end
    else
        result = false
        failureMsg = 'miss pattern'
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname,failureMsg)
    return nandsize
end


function func.nand_parse( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input
    local id = paraTab.AdditionalParameters.id
    local offset = tonumber( paraTab.AdditionalParameters.offset )

    local pattern
    local matchs

    pattern = "\\s+" .. id .. "\\s+[0-9]+\\s+([0-9A-F]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        local value = matchs[1][1]
        if ( tonumber(offset) ~= nil ) then
            value = string.sub(value, (offset-1)*8+1, offset*8)
        end
        value = tonumber( "0x" .. value )
        local limitTab = paraTab.limit
        local limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        Record.createParametricRecord(value,paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,limit)
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
end

function func.eeee_code_compare( paraTab )
    local inputDict = paraTab.InputDict
    local vc = require("Tech/VersionCompare")

    local versions = vc()["EEEE_CODE"]

    Log.LogInfo("EEEE_CODE: " .. comFunc.dump(versions) .. '\n')

    local sn = tostring(inputDict.sn)
    local boardid = inputDict.BOARD_ID
    local nandsize = inputDict.NAND_SIZE
    local memorysize = inputDict.MEMORY_SIZE
    local eeee_code = nil
    if #sn == 17 then
        eeee_code = string.sub(sn,12,15)
    end

    if sn ~= nil and boardid ~= nil and nandsize ~= nil and memorysize ~= nil and eeee_code ~= nil then
        local value = eeee_code .. ' ' .. boardid .. ' ' .. nandsize .. ' ' .. memorysize
        local result = false
        Log.LogInfo("current: " .. value .. '\n')
        for _,versionValue in ipairs(versions) do
            if string.find(versionValue,value) then
                result = true
                break
            end
        end
        -- local result = comFunc.hasVal(versions, value)
        Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
end

function func.nand_parse_add( paraTab )
    local Regex = Device.getPlugin("Regex")
    ret = paraTab.Input

    local sum = 0
    local values = comFunc.splitString(paraTab.AdditionalParameters.values, '+')

    local pattern
    local matchs
    
    for _, value in ipairs(values) do
        local arr = comFunc.splitString(value, '&')
        local id = arr[1]
        local offset = tonumber(arr[2])

        pattern = "\\s+" .. id .. "\\s+[0-9]+\\s+([0-9A-F]+)"
        matchs = Regex.groups(ret, pattern, 1)
        if #matchs > 0 then
            local value = matchs[1][1]
            if ( tonumber(offset) ~= nil ) then
                value = string.sub(value, (offset-1)*8+1, offset*8)
            end
            value = tonumber( "0x" .. value )
            sum = sum + value
        end
    end
    local limitTab = paraTab.limit
    local limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    Record.createParametricRecord(sum,paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,limit)
end

function func.nand_parse_1008( paraTab )
    local Regex = Device.getPlugin("Regex")
    ret = paraTab.Input
    local pattern
    local matchs

    local offset = 1
    local value_1008
    local value_1005

    pattern = "\\s+" .. "1008" .. "\\s+[0-9]+\\s+([0-9A-F]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        local value = matchs[1][1]
        value = string.sub(value, (offset-1)*8+1, offset*8)
        value_1008 = tonumber( "0x" .. value )
    end

    pattern = "\\s+" .. "1005" .. "\\s+[0-9]+\\s+([0-9A-F]+)"
    matchs = Regex.groups(ret, pattern, 1)
    if #matchs > 0 then
        local value = matchs[1][1]
        value_1005 = tonumber( "0x" .. value )
    end

    local report = DataReporting.createParametricRecord(value_1008, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    if value_1005 > 2 then
        report.applyLimit(nil, 0, 800, nil)
    end

    DataReporting.submit( report )
end

return func
