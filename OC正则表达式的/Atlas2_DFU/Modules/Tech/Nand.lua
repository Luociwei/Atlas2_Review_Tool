-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------

local Nand = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local dutCmd = require("Tech/DUTCmd")
local Record = require("Matchbox/record")


-- A new function Starts after this
-- Unique Function ID :  Microtest_000027_1.0
-- parseMSP
-- Function to Parse nanduid and create MSP_[i]_CH_[i]_Die_[i] records according to the input string(response of nanduid).

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
function Nand.parseMSP( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input
    local pattern = "MSP (\\d+) CH (\\d+) Die (\\d+):\\s([0-9A-F ]+)"
    local matchs = Regex.groups(ret, pattern, 1)
    for _, match in ipairs(matchs) do
        local itemName = "MSP" .. match[1] .. "_CH" .. match[2] .. "_Die" .. match[3]
        local attributeName = "NANDUID_" .. itemName
        DataReporting.submit( DataReporting.createAttribute(attributeName, tostring(match[4])) )
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, itemName)
    end
    if #matchs > 0 then
        local count = tonumber( matchs[#matchs][1] )
        DataReporting.submit( DataReporting.createAttribute("NAND_Total_Controller_Count", tostring(count+1)) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName,"NAND_Total_Controller_Count")
        DataReporting.submit( DataReporting.createAttribute("NAND_Total_Die_Count", tostring(#matchs)) )
        Record.createBinaryRecord(true,paraTab.Technology, paraTab.TestName,"NAND_Total_Die_Count")
    end
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000028_1.0
-- parseFCE
-- Function to Parse nandid and create FCE0[i] records according to the input string(response of nandcsid).

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
function Nand.parseFCE( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input
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

-- A new function Starts after this
-- Unique Function ID :  Microtest_000029_1.0
-- nandParse
-- Function to Match one or more values with the input string, and then return the sum of those values.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : nil
function Nand.nandParse( paraTab )
    local Regex = Device.getPlugin("Regex")
    local ret = paraTab.Input

    local sum = 0
    local values = comFunc.splitString( paraTab.AdditionalParameters.values, '+')

    for _, value in ipairs(values) do
        local arr = comFunc.splitString(value, '&')
        local id = arr[1]
        local offset = tonumber(arr[2])
        local pattern = "\\s+" .. id .. "\\s+[0-9]+\\s+([0-9A-F]+)"
        local matchs = Regex.groups(ret, pattern, 1)
        if #matchs > 0 then
            local value = matchs[1][1]
            if ( tonumber(offset) ~= nil ) then
                value = string.sub(value, (offset-1)*8+1, offset*8)
            end
            value = tonumber( "0x" .. value )
            sum = sum + value
        end
    end

    if paraTab.AdditionalParameters.values == "1008&1" then
        local value_1005 = nil
        local pattern = "\\s+" .. "1005" .. "\\s+[0-9]+\\s+([0-9A-F]+)"
        local matchs = Regex.groups(ret, pattern, 1)
        if #matchs > 0 then
            local value = matchs[1][1]
            value_1005 = tonumber( "0x" .. value )
        end
        local report = DataReporting.createParametricRecord(sum, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
        if value_1005 > 2 then
            report.applyLimit(nil, 0, 800, nil)
        end
        DataReporting.submit( report )
    else
        local limitTab = paraTab.limit
        local limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        Record.createParametricRecord(sum,paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname,limit)
    end
end

return Nand