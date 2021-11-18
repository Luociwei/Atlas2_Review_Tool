--[[
FilePath: /Atlas2/Modules/Tech/restore.lua
Description: In User Settings Edit
Author: Jason
Date: 2020-09-12 17:23:07
LastEditors: Jason
LastEditTime: 2020-09-12 17:45:35
Copyright © 2020 HWTE. All rights reserved.
--]]

local Log = require("Matchbox/logging")
local Restore = {}
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")

-- A new function Starts after this
-- Unique Function ID :  Microtest_000038_1.0
-- getRestoreDeviceLogPath
-- Function to get the restore_device_xxx.log path from DCSD Log Directory

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the path of restore device log file.
function Restore.getRestoreDeviceLogPath( )
    local result = nil
    local files = comFunc.runShellCmd("ls " .. Device.userDirectory .. "/DCSD")['output']
    result = string.match(files, "restore_device_[0-9_-]+%.log")
    if result then 
        result = Device.userDirectory .. '/DCSD/' .. result
    end
    return result
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000039_1.0
-- getRestoreHostLogPath
-- Function to get the restore_host_xxx.log path from DCSD Log Directory

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the path of restore host log file.
function Restore.getRestoreHostLogPath( )
    local result = nil
    local files = comFunc.runShellCmd("ls " .. Device.userDirectory .. "/DCSD")['output']
    result = string.match(files, "restore_host_[0-9_-]+%.log")
    if result then 
        result = Device.userDirectory .. '/DCSD/' .. result
    end
    return result
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000040_1.0
-- restoreDFUModeCheck
-- Function to check if UUT is in DFU Mode according to the USB LocationID 

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the locationID.
function Restore.restoreDFUModeCheck( paraTab )
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local timeout = paraTab.Timeout
    local flagIndex = paraTab.AdditionalParameters.flagIndex or -1
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        error("miss timeout")
    end
    local locationId = Restore.getLocationID(Device.systemIndex+1, flagIndex, timeout)
    Log.LogInfo("locationId>>", locationId)
    if #locationId == 0 then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, subsubtestname,"Get LocationID failed")
        error(paraTab.Technology ..'-'.. paraTab.TestName ..'-'.. subsubtestname ..'-'.. "Get LocationID failed")
    else
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, subsubtestname)
    end
    return locationId
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000041_1.0
-- getLocationID
-- Function to get the USB LocationID accrding the Slot Number

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : string, the locationID.
function Restore.getLocationID(slot_num, flagIndex, timeout)
    local Regex = Device.getPlugin("Regex")
    local locationID = ''
    local flagIndex = tonumber(flagIndex)
    local startTime = os.time()
    local pattern = "Apple Mobile Device \\(DFU Mode\\):[\\s\\S]+?Location ID: 0x(\\S+) /"
    repeat
        local data = comFunc.runShellCmd("system_profiler SPUSBDataType")['output']
        local matchs = Regex.groups(data, pattern, 1)
        Log.LogInfo('$$$$ getLocationID matchs')
        Log.LogInfo(comFunc.dump(matchs))
        if #matchs > 0 and #matchs[1] > 0 then
            for _, v in pairs(matchs) do
                if v and #v > 0 then
                    local result = v[1]
                    result = string.gsub(result,'0','')
                    chr = string.sub(result, flagIndex, flagIndex)
                    Log.LogInfo('$$$$ getLocationID result')
                    Log.LogInfo(comFunc.dump(result))
                    if tonumber(slot_num) == tonumber(chr) then
                        locationID = "0x" .. v[1]
                    end
                end
            end
        end
        if #locationID == 0 then
            comFunc.sleep(0.1)
        end
    until(#locationID > 0 or os.difftime(os.time(), startTime) >= timeout)
    return locationID
end


-- A new function Starts after this
-- Unique Function ID :  Microtest_000042_1.0
-- checkHangAndKernelPanic
-- Function to check the panic message or detect hang issue during the restore process, will power off the UUT if hang detected.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : SOF_Flag("TRUE" or "FALSE"), failureMsg, the uart log during restore.
function Restore.checkHangAndKernelPanic( paraTab )
    local progress = Device.getPlugin("restoreProgressPlugin")
    local timeout = tonumber(paraTab.Timeout)
    if timeout == nil then 
        error("miss timeout")
    end

    local hangTimeout = tonumber(paraTab.AdditionalParameters.hangTimeout)
    if hangTimeout == nil then
        error("miss hangTimeout in AdditionalParameters")
    end

    local dut = Device.getPlugin("dut")
    if dut.isOpened() ~= 1 then
        dut.open(2)
    end
    dut.setDelimiter("")

    local InteractiveView = Device.getPlugin("InteractiveView")
    local panic_msg = "Debugger message: panic;Please go to https://panic.apple.com to report this panic;Nested panic detected;%[iBoot Panic%]"
    local panicKeys = comFunc.splitString(panic_msg, ';')

    local content = ""
    Log.LogInfo("$$$$ kernel_panic check starting")
    local startTime = os.time()
    local lastRetTime = os.time()

    repeat
        local status, ret = xpcall(dut.read, debug.traceback, 1, '')
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret
            if not Restore.checkKernelPanic(paraTab, content, panicKeys) then return content end
        end

        if os.difftime(os.time(),lastRetTime) >= hangTimeout then
            Restore.restoreHangDetectedHandle( paraTab )
            return content
        end
    until(os.difftime(os.time(), startTime) >= timeout or not progress.isRunning())
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "Restore_Hang_Check")
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "Kernel_Panic")
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "Iboot_Panic")
    Log.LogInfo("$$$$ kernel_panic check done")
    return content
end

function Restore.checkKernelPanic( paraTab, content, panicKeys )
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local InteractiveView = Device.getPlugin("InteractiveView")
    for _, v in ipairs(panicKeys) do
        if #v > 0 and string.find(content, v) then
            local viewConfig = {
                ["message"] = "Kernel panic detected"
            }
            InteractiveView.showView(Device.systemIndex, viewConfig)
            fixturePlugin.dut_power_off(tonumber(Device.identifier:sub(-1)))
            if v == "%[iBoot Panic%]" then
                Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "Iboot_Panic")
            else
                Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "Kernel_Panic")
            end
            return false
        end
    end
    return true
end

function Restore.restoreHangDetectedHandle( paraTab )
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local InteractiveView = Device.getPlugin("InteractiveView")
    Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "Restore_Hang_Check","Hang_detected")
    fixturePlugin.dut_power_off(tonumber(Device.identifier:sub(-1)))
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "dut_power_off")
    local viewConfig = {
        ["message"] = "uart hang detected"
    }
    InteractiveView.showView(Device.systemIndex, viewConfig)
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000043_1.0
-- checkHangAndKernelPanic
-- Function to check the supply Ace Provisioning Power flag during the restore process.

-- Created by: Jayson ye 
-- Initial Creation Date :  27/07/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
function Restore.supplyAceProvisioningPower( paraTab )
    local progress = Device.getPlugin("restoreProgressPlugin")
    local timeout = tonumber(paraTab.Timeout)
    local startTime = os.time()
    if timeout == nil then 
        error("miss timeout")
    end

    local ppvbus_14v_on_flag = false
    local ppvbus_14v_off_flag = false
    local device_log_path = Restore.getRestoreDeviceLogPath()
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local ppvbus_14v_on_signal = "CHECKPOINT END: FIRMWARE:%[0x130A%] install_fud"
    local ppvbus_14v_off_signal = "CHECKPOINT END: %(null%):%[0x067F%] provision_ace2"

    repeat
        -- Supply_ace_provisioning_power
        if device_log_path ~= nil then
            local device_log = comFunc.fileRead(device_log_path)
            if not ppvbus_14v_on_flag then
                if string.find(device_log, ppvbus_14v_on_signal) then
                    fixturePlugin.ace_provisioning_power_on(tonumber(Device.identifier:sub(-1)))
                    Log.LogInfo("$$$$ ace_provisioning_power_on")
                    ppvbus_14v_on_flag = true
                end
            end
            if not ppvbus_14v_off_flag then
                if string.find(device_log, ppvbus_14v_off_signal) then
                    fixturePlugin.ace_provisioning_power_off(tonumber(Device.identifier:sub(-1)))
                    Log.LogInfo("$$$$ ace_provisioning_power_off")
                    ppvbus_14v_off_flag = true
                    break
                end
            end
        else
            device_log_path = Restore.getRestoreDeviceLogPath()
        end
        comFunc.sleep(0.1)
    until(os.difftime(os.time(), startTime) >= timeout or not progress.isRunning())
    if paraTab.AdditionalParameters.subsubtestname then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    end
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000044_1.0
-- restoreProcessCheck
-- Function to check the keywords from device/restore_device/restore_host log.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : SOF_Flag("TRUE" or "FALSE"), failureMsg
function Restore.restoreProcessCheck(paraTab)
    local log_device = tostring(paraTab.AdditionalParameters.log_device)
    local keywords = tostring(paraTab.AdditionalParameters.expect)
    local log_path = Device.userDirectory .. '/../system/device.log'
    Log.LogInfo("$$$$ restoreProcessCheck log_device: " .. log_device)

    if log_device == 'restore_device' then
        log_path = Restore.getRestoreDeviceLogPath()
    elseif log_device == 'restore_host' then
        log_path = Restore.getRestoreHostLogPath()
    end
    local host_log = comFunc.fileRead(log_path)
    local result = string.find(host_log, keywords) ~= nil
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    if paraTab.AdditionalParameters.subsubtestname == 'Restore_successful' then
        if not result then
            error("restore failed.")
        end
    end
end

-- A new function Starts after this
-- Unique Function ID :  Microtest_000045_1.0
-- restore
-- Function to restore device.

-- Created by: Jayson ye 
-- Initial Creation Date :  15/06/2021
-- Current_Version:  1.0
-- Vendor_Name : Microtest
-- Primary Usage: DFU
-- Input Arguments:  type is table, param of tech csv line
-- Return : nil
function Restore.restore(paraTab)
    Log.LogInfo("DCSD Restore ------>>>>>", parmTab)
    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        error("miss timeout")
    end

    local locationId = paraTab.Input
    if locationId == nil or #locationId < 1 then
        error("miss locationId")
        return
    end

    local usb_url = "lockdown://"..tostring(locationId)
    Log.LogInfo("usb_url>>", usb_url)

    local dcsd_plugin = Device.getPlugin("DCSD")
    -- local dcsd_plugin = Atlas.loadPlugin("DCSD")
    -- plugin.registerDevicePlugin(Device.identifier,"DCSD",dcsd_plugin)

    Log.LogInfo("lockdown URL for SWDLRestore: ", usb_url)
    Log.LogInfo("Device.userDirectory: ", Device.userDirectory)
    local workspace = Device.userDirectory .. "/DCSD"
    local startTime = os.time()
    local restoreErrorMsg = ""
    local dcsd_dut = dcsd_plugin.get_dcsd_dut_plugin(usb_url, workspace)

    -- "bundleLocation":"\/Users\/gdlocal\/RestorePackage\/CurrentBundle\/Restore"
    -- "prLocation":"\/Users\/gdlocal\/Library\/Application Support\/PurpleRestore\/DFU.pr"

    -- local pr_doc_path = "/Users/gdlocal/Library/Application Support/PurpleRestore/SoftwareDownload_SMT.pr"
    -- local pr_doc_path = burninUtil.choosePRFile()
    local pr_doc_path = "/Users/gdlocal/Library/Application Support/PurpleRestore/DFU.pr"
    if pr_doc_path == "" then
        error("Can't file correct PR file, please check your overlay")
    end
    local unit_start_time_string = tostring(os.date("%Y-%m-%d_%H-%M-%S"))
    -- local progress = dcsd_plugin.get_progress_plugin()
    local progress = Device.getPlugin("restoreProgressPlugin")
    dcsd_dut.restore_device(
                        pr_doc_path,                  -- PR_DOC_PATH
                        unit_start_time_string,       -- start date in yyyy-MM-dd_HH-mm-ss"
                        "sw_name",                    -- SWName
                        "sw_version",                 -- SWVersion
                        false,                    	  -- Whether to write SFC record
                        false,               		  -- Whether to use MPNRC from SFC
                        progress   					  -- For progress update
                        )
    repeat
        msg = progress.getMessage()
        if msg ~= nil
        then
            Device.updateProgress(msg)
            Log.LogInfo(msg)
            if string.find(msg,"restore failed") ~= nil then
                restoreErrorMsg = restoreErrorMsg == "" and msg or restoreErrorMsg .."," .. "msg"
            end
        end
    until(os.difftime(os.time(), startTime) >= timeout or not progress.isRunning())

    -- Log.LogInfo("$$$$ get progress\n")
    -- local command_result = progress.getResultAndError()
    -- local cmd_ret = command_result[progress.CMD_RETURN]
    -- local err_msg = command_result[progress.ERROR_MSG]
    -- local err_code = command_result[progress.ERROR_CODE]
    -- Log.LogInfo("$$$$\n" .. cmd_ret .. "\n" .. err_msg .. "\n" .. err_code .. "\n" .. "\n")
    local result = true
    if progress.isRunning() then
        Log.LogInfo("Restore failed with reason: timeout error")
        result = false
        error("Restore timeout error")
    end
    if restoreErrorMsg ~= "" then
        Log.LogInfo("Restore failed with reason: ", restoreErrorMsg)
        result = false
        error(restoreErrorMsg)
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    Log.LogInfo("$$$$ restore done")
end

return Restore