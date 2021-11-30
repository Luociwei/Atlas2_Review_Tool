-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------


local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")
local versions
local VersionCompare = {}


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000050_1.0
-- VersionCompare.getVersions( )
-- Function to parse the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : N/A
-- Output Arguments : table
-----------------------------------------------------------------------------------]]

function VersionCompare.getVersions( )
    if versions == nil then
        versions = {}
        -- local path = "/Users/gdlocal/Library/Atlas2/supportFiles/VersionCompare.txt"
        local path = "/Users/gdlocal/Public/supportFiles/VersionCompare.txt"
        local content = comFunc.fileRead(path)
        local rows = comFunc.splitString(content, '\n')
        local key
        local index = 1
        for _, row in ipairs(rows) do
            local linearr = comFunc.splitString(row, ':')
            if #linearr == 2 then
                key = linearr[1]
                if linearr[2] ~= "" then
                    versions[key] = comFunc.trim(linearr[2])
                else
                    versions[key] = {}
                    index = 1
                end
            elseif row ~= "" then
                versions[key][index] = comFunc.trim(row)
                index = index + 1
            end
            -- comFunc.exLog("VersionCompare:  " .. comFunc.dump(versions) .. '\n')
        end
    end
    return versions
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000051_1.0
-- VersionCompare.versionCompare( paraTab )
-- Function to compare the GrapeFW/BT_FW/WIFI_FW/RTOS_Version/RBM_Version/WSKU/RFEM/EEEE_CODE with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : N/A
-----------------------------------------------------------------------------------]]

function VersionCompare.versionCompare( paraTab )
    local key = paraTab.AdditionalParameters.comparekey
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local inputDict = paraTab.InputDict
    local result = false

    if inputDict ~= nil then
        if key then
            local versions = VersionCompare.getVersions()[key]
            if not versions then
                result = false
                failureMsg = 'compare value not found'
                Record.createBinaryRecord(result, paraTab.Technology, subtestname, subsubtestname, failureMsg)
                return
            end
            Log.LogInfo( key .. ": " .. comFunc.dump(versions) .. '\n')

            if key == 'GrapeFW' then
                result,failureMsg = grapeFWCompare(inputDict, versions)
            elseif key == 'BT FW' then
                result,failureMsg = btFWCompare(inputDict, versions)
            elseif key == 'WIFI FW' then
                result,failureMsg = wifiFWCompare(inputDict, versions)
            elseif key == 'RTOS' then
                result,failureMsg = rtosVersionCompare(inputDict, versions)
            elseif key == 'RBMVersionList' then
                result,failureMsg = rbmVersionCompare(inputDict, versions)
            elseif key == "WSKU" then
                result,failureMsg = wskuVersionCompare(paraTab, versions)
            elseif key == "RFEM" then
                local inputValues = paraTab.InputValues
                result,failureMsg = rfemVersionCompare(inputValues, versions)
            elseif key == "EEEE_CODE" then
                result,failureMsg = eeeecodeCompare(inputDict, versions)
            else
                result = false
                failureMsg = 'key[' .. key .. '] error'
            end
        else
            result = false
            failureMsg = 'miss comparekey'
        end
    else
        result = false
        failureMsg = 'miss input value'
    end
    Record.createBinaryRecord(result, paraTab.Technology, subtestname, subsubtestname, failureMsg)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000052_1.0
-- grapeFWCompare( inputDict, versions )
-- Function to compare the GrapeFW with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function grapeFWCompare( inputDict, versions )
    local result = false
    local failureMsg = ""
    local touch_firmware = inputDict.TOUCH_FIRMWARE
    if touch_firmware ~= nil then
        Log.LogInfo("TOUCH_FIRMWARE=" .. touch_firmware .. '\n')
        Log.LogInfo("GrapeFW: " .. comFunc.dump(versions) .. '\n')
        result = versions == touch_firmware
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000053_1.0
-- btFWCompare( inputDict, versions )
-- Function to compare the BT FW with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function btFWCompare( inputDict, versions )
    local result = false
    local failureMsg = ""
    local wifi_module = inputDict.WIFI_MODULE
    local bt_firmware = inputDict.BT_FIRMWARE
    if wifi_module ~= nil and bt_firmware ~= nil then
        Log.LogInfo("WIFI_MODULE=" .. wifi_module .. '\n')
        Log.LogInfo("BT_FIRMWARE=" .. bt_firmware .. '\n')
        Log.LogInfo("BT FW: " .. comFunc.dump(versions) .. '\n')
        for _, version in ipairs(versions) do
            local arr = comFunc.splitString(version, '\t')
            if string.find(arr[1], wifi_module) ~= nil and 
                string.find(arr[2], bt_firmware) ~= nil then
                Log.LogInfo("Match: " .. version .. '\n')
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000054_1.0
-- wifiFWCompare( inputDict, versions )
-- Function to compare the WIFI FW with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function wifiFWCompare( inputDict, versions )
    local result = false
    local failureMsg = ""
    local wifi_module = inputDict.WIFI_MODULE
    local wifi_firmware = inputDict.WIFI_FIRMWARE
    local wifi_nvram = inputDict.WIFI_NVRAM
    if wifi_module ~= nil and wifi_firmware ~= nil and wifi_nvram ~=nil then
        Log.LogInfo("WIFI_MODULE=" .. wifi_module .. '\n')
        Log.LogInfo("WIFI_FIRMWARE=" .. wifi_firmware .. '\n')
        Log.LogInfo("WIFI_NVRAM=" .. wifi_nvram .. '\n')
        Log.LogInfo("WIFI FW: " .. comFunc.dump(versions) .. '\n')
        for _, version in ipairs(versions) do
            local arr = comFunc.splitString(version, '\t')
            if string.find(arr[1], wifi_module) ~= nil and 
                string.find(arr[2], wifi_firmware) ~= nil and 
                string.find(arr[3], wifi_nvram) ~= nil then
                Log.LogInfo("Match: " .. version .. '\n')
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000055_1.0
-- rtosVersionCompare( inputDict, versions )
-- Function to compare the RTOS Version with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function rtosVersionCompare( inputDict, versions )
    local result = false
    local failureMsg = ""
    local rtos_version = inputDict.RTOS_Version
    if rtos_version ~= nil then
        Log.LogInfo("rtos_version=" .. rtos_version .. '\n')
        Log.LogInfo("RTOS: " .. comFunc.dump(versions) .. '\n')
        result = rtos_version == versions
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000056_1.0
-- rbmVersionCompare( inputDict, versions )
-- Function to compare the RBM Version with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function rbmVersionCompare( inputDict, versions )
    local result = false
    local failureMsg = ""
    local rbm_version = inputDict.RBM_Version
    if rbm_version ~= nil then
        Log.LogInfo("rbm_version=" .. rbm_version .. '\n')
        Log.LogInfo("RBMVersionList: " .. comFunc.dump(versions) .. '\n')
        rbm_version = string.gsub(rbm_version, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
        for _, version in ipairs(versions) do
            if string.find(version, rbm_version) ~= nil then
                Log.LogInfo("Match: " .. version .. '\n')
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000057_1.0
-- wskuVersionCompare( paraTab, versions )
-- Function to compare the WSKU Version with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function wskuVersionCompare( paraTab, versions )
    local result = false
    local failureMsg = ""
    local inputValues = paraTab.InputValues
    local wsku_value = inputValues[1]
    local sn = tostring(inputValues[2])
    local sku = ""
    if sn and #sn > 0 then
        local eeeecode = string.sub(sn,12,15)
        local eeeecode_versions = VersionCompare.getVersions()["EEEE_CODE"]
        for _,versionValue in ipairs(eeeecode_versions) do
            if string.find(versionValue,eeeecode) then
                local eeeecode_info = comFunc.splitString(versionValue," ")
                if eeeecode_info[5] then 
                    sku = eeeecode_info[5] .. " "
                end
                break
            end
        end
        local smokey_wdfu_resp = tostring(inputValues[3])
        local Regex = Device.getPlugin("Regex")
        local pattern = paraTab.AdditionalParameters.pattern
        if pattern then
            local matchs = Regex.groups(smokey_wdfu_resp, pattern, 1)
            if #(matchs[1]) > 0 then
                sku = sku .. matchs[1][1]
            end
        end
        Log.LogInfo( "target: " .. sku .. "    " .. wsku_value .. '\n' )
        for _, version in ipairs(versions) do
            if string.find(version, sku) ~= nil and string.find(version, wsku_value) ~= nil then
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000058_1.0
-- rfemVersionCompare( inputValues, versions )
-- Function to compare the RFEM Version with the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function rfemVersionCompare( inputValues, versions )
    local result = false
    local failureMsg = ""
    local rfem_val = inputValues[1]
    if rfem_val ~= nil then
        Log.LogInfo( "target: " .. rfem_val .. '\n' )
        for _, version in ipairs(versions) do
            if version == rfem_val then
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000059_1.0
-- eeeecodeCompare( inputDict, versions )
-- Function to compare the BOARD_ID/NAND_SIZE/MEMORY_SIZE with eeeecode and the VersionCompare file.
-- Created By : Jayson Ye
-- Initial Creation Date : 15/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : table, table
-- Output Arguments : bool, string
-----------------------------------------------------------------------------------]]

function eeeecodeCompare( inputDict, versions )
    local result = false
    local failureMsg = ""
    local sn = tostring(inputDict.MLB_Num)
    local boardid = inputDict.BOARD_ID
    local nandsize = inputDict.NAND_SIZE
    local memorysize = inputDict.MEMORY_SIZE
    if #sn > 0 then
        eeee_code = string.sub(sn,12,15)
    end
    if sn ~= nil and boardid ~= nil and nandsize ~= nil and memorysize ~= nil and eeee_code ~= nil then
        local value = eeee_code .. ' ' .. boardid .. ' ' .. nandsize .. ' ' .. memorysize
        Log.LogInfo("current: " .. value .. '\n')
        for _,versionValue in ipairs(versions) do
            if string.find(versionValue,value) then
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result,failureMsg
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID : Microtest_000060_1.0
-- VersionCompare.getExpectedVersionWithKey( paraTab )
-- Function to get expected version with key.
-- Created By : Jayson Ye
-- Initial Creation Date : 22/09/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : Microtest
-- Primary Usage : DFU
-- Input Arguments : param table
-- Output Arguments : string
-----------------------------------------------------------------------------------]]

function VersionCompare.getExpectedVersionWithKey( paraTab )
    local key = paraTab.AdditionalParameters.key
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local version = ""
    local result = false
    local failureMsg = ""
    if key then 
        version = VersionCompare.getVersions()[key]
        if version and #version > 0 then 
            result = true
        else
            failureMsg = "value not found"
        end
    else
        failureMsg = "key missing"
    end
    if subsubtestname then
        Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname, failureMsg)
    end
    if not result then
        error(failureMsg)
    end
    return version
end


return VersionCompare