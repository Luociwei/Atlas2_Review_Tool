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
local M = {}
local comFunc = require("Matchbox/CommonFunc")
local shell = require("Tech/Shell")
local Record = require 'Matchbox/record'

function getRestoreDeviceLogPath()
    local result = nil
    local retryTimes = 5
    repeat
        retryTimes = retryTimes - 1
        local files = shell.execute("ls " .. Device.userDirectory .. "/DCSD")
        result = string.match(files, "restore_device_[0-9_-]+%.log")
        comFunc.sleep(0.1)
    until(retryTimes < 0 or result ~= nil)
    return result
end

function getRestoreHostLogPath()
    local result = nil
    local retryTimes = 5
    repeat
        retryTimes = retryTimes - 1
        local files = shell.execute("ls " .. Device.userDirectory .. "/DCSD")
        result = string.match(files, "restore_host_[0-9_-]+%.log")
        comFunc.sleep(0.1)
    until(retryTimes < 0 or result ~= nil)
    return result
end

function M.restore_dfu_mode_check( parmTab )
    local vt = Device.getPlugin("VariableTable")
    local subsubtestname = parmTab.AdditionalParameters.subsubtestname
    vt.setVar("restore_finish",false)
    vt.setVar("ppvbus_14v_on_flag", false)
    vt.setVar("ppvbus_14v_off_flag", false)

    local locationId = getLocationID(Device.identifier)
    print("Device.identifier>>", Device.identifier)
    print("locationId>>", locationId)
    if #locationId == 0 then
        Record.createBinaryRecord(false, parmTab.Technology, parmTab.TestName, subsubtestname,"Get LocationID failed")
        error(parmTab.Technology ..'-'.. paraTab.TestName ..'-'.. subsubtestname ..'-'.. "Get LocationID failed")
        -- local fixture = Device.getPlugin("FixturePlugin")
        -- local slot_num = tonumber(Device.identifier:sub(-1)) + 1
        -- fixture.dut_power_off(slot_num)
        -- DataReporting.submit( DataReporting.createBinaryRecord(false, parmTab.Technology, parmTab.TestName, 'Set_DUT_Power_OFF') )

    else
        -- vt.setVar("locationID",locationId)
        Record.createBinaryRecord(true, parmTab.Technology, parmTab.TestName, subsubtestname)
    end

    return locationId

end

function getLocationID(device) 
    local Regex = Device.getPlugin("Regex")

    local locationID = ''
    local startTime = os.time()
    local timeout = 10
    local pattern = "Apple Mobile Device \\(DFU Mode\\):[\\s\\S]+?Location ID: 0x(\\S+) /"

    repeat
        local data = shell.execute("system_profiler SPUSBDataType")
        local matchs = Regex.groups(data, pattern, 1)
        Log.LogInfo('$$$$ getLocationID matchs')
        Log.LogInfo(comFunc.dump(matchs))
        if #matchs > 0 and #matchs[1] > 0
        then
            for _, v in pairs(matchs) do
                if v and #v > 0 then
                    local result = v[1]
                    result = string.gsub(result,'0','')
                    chr = string.sub(result, -1, -1)
                    Log.LogInfo('$$$$ getLocationID result')
                    Log.LogInfo(comFunc.dump(result))
                    if tonumber(string.sub(device, -1, -1)) + 1 == tonumber(chr) then
                        locationID = "0x" .. v[1]
                    end
                end
            end
        end
        if #locationID == 0 then
            comFunc.sleep(1)
        end
    until(#locationID > 0 or os.difftime(os.time(), startTime) >= timeout)

    return locationID

end

function M.delayToStartRestore( parmTab )
    local delay_per_slot = parmTab.AdditionalParameters.delay_per_slot
    local subsubtestname = parmTab.AdditionalParameters.subsubtestname
    if delay_per_slot ~= nil then
        delay_per_slot = tonumber(delay_per_slot)
    else
        delay_per_slot = 10
    end
    local GroupTablePlugin = Device.getPlugin("GroupTablePlugin")
    local delayTimes = GroupTablePlugin.getVar("restore_delay_count") * delay_per_slot
    GroupTablePlugin.setVar("restore_delay_count",GroupTablePlugin.getVar("restore_delay_count") + 1)
    Log.LogInfo("$$$$$ delayToStartRestore "  .. tostring(delayTimes))
    comFunc.sleep(delayTimes)
    if subsubtestname then
        Record.createBinaryRecord(true,parmTab.Technology, parmTab.TestName,subsubtestname,"")
    end
end

function M.kernel_panic( parmTab )
    local vt = Device.getPlugin("VariableTable")
    
    local startTime = os.time()
    local timeout = 1500
    local hangTimeout = tonumber(parmTab.AdditionalParameters.hangTimeout_s)

    if hangTimeout == nil then
        hangTimeout = 125
    end

    -- hangTimeout = 1

    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        error("No timeout setting be found for restore, please check your TP")
    end

    local dut = Device.getPlugin("dut")
    -- if dut.isOpened() == 1 then
    --     dut.close()
    -- end
    -- dut.setDelimiter("")
    -- dut.open(2)

    if dut.isOpened() ~= 1 then
        dut.setDelimiter("")
        dut.open(2)
    else
        dut.setDelimiter("")
    end

    local InteractiveView = Device.getPlugin("InteractiveView")

    local logPath = Device.userDirectory .. "/uart.log"
    local panic_msg = "Debugger message: panic;Please go to https://panic.apple.com to report this panic;Nested panic detected;%[iBoot Panic%]"
    local panicKeys = comFunc.splitString(panic_msg, ';')

    local content = ""
    Log.LogInfo("$$$$ kernel_panic check starting")
    local lastRetTime = os.time()
    repeat
        -- local ret = dut.read()
        -- local status = true
        local status, ret = xpcall(dut.read, debug.traceback, 3, '')
        -- Log.LogInfo("$$$$ dut.read \n"..ret..'\n')
        -- local status, ret = xpcall(dut.read,debug.traceback)
        if status and ret and #ret > 0
        then
            lastRetTime = os.time()
            content = content .. ret
            vt.setVar("restore_uart_log",content)
            for _, v in ipairs(panicKeys) do
                if #v > 0 and string.find(content, v) then
                    local viewConfig = {
                        ["message"] = "Kernel panic detected"
                    }
                    vt.setVar("restore_finish",true)
                    InteractiveView.showView(Device.systemIndex, viewConfig)
                    local fixture = Device.getPlugin("FixturePlugin")
                    local slot_num = tonumber(Device.identifier:sub(-1)) + 1
                    fixture.dut_power_off(slot_num)
                    if v == "%[iBoot Panic%]" then
                        Record.createBinaryRecord(false, parmTab.Technology, "NonUI-DCSD", "Kernel_Panic")
                    else
                        Record.createBinaryRecord(false, parmTab.Technology, "NonUI-DCSD", "Iboot_Panic")
                    end
                    return "TRUE","Kernel panic detected during restore."
                end
            end
        end

        if os.difftime(os.time(),lastRetTime) >= hangTimeout then
            Record.createBinaryRecord(false, parmTab.Technology, "NonUI-DCSD", "Restore_Hang_Check","Hang_detected")
            vt.setVar("restore_finish",true)
            local fixture = Device.getPlugin("FixturePlugin")
            local slot_num = tonumber(Device.identifier:sub(-1)) + 1
            fixture.dut_power_off(slot_num)
            Record.createBinaryRecord(true, parmTab.Technology, "hangTimeout", "dut_power_off")
            local viewConfig = {
                ["message"] = "uart hang detected"
            }
            InteractiveView.showView(Device.systemIndex, viewConfig)
            error(parmTab.Technology ..'-'.. parmTab.TestName ..'-'.. parmTab.AdditionalParameters.subsubtestname ..'-'.. "Hang_detect")
            return "TRUE","uart hang detected during restore."
        end
    until(vt.getVar("restore_finish") or os.difftime(os.time(), startTime) >= timeout)
    Record.createBinaryRecord(true, parmTab.Technology, "NonUI-DCSD", "Restore_Hang_Check")
    Record.createBinaryRecord(true, parmTab.Technology, "NonUI-DCSD", "Kernel_Panic")
    Record.createBinaryRecord(true, parmTab.Technology, "NonUI-DCSD", "Iboot_Panic")
    Log.LogInfo("$$$$ kernel_panic check done")
    return "FALSE",content
end

-- function M.check( parmTab )
--     local cycleTime_csv_path = Device.userDirectory .. '/DCSD/CycleTime.csv'
--     local cycleTime_log = comFunc.fileRead(cycleTime_csv_path)
--     local result = string.find(cycleTime_log, parmTab.AdditionalParameters.expect) ~= nil
--     -- Log.LogInfo("$$$$ check :"..cycleTime_log..'\n\n\n $$$$ expect'..parmTab.AdditionalParameters.expect..'\n\n\n')
--     DataReporting.submit(DataReporting.createBinaryRecord(result, parmTab.Technology, parmTab.TestName, parmTab.AdditionalParameters.subsubtestname))
-- end

function M.checkBoardType( parmTab )
    -- Board ID: 0x6
    local start_time = os.time()
    repeat
        comFunc.sleep(1)
    until (getRestoreDeviceLogPath() ~= nil or os.difftime(os.time(), start_time) > 20)

    local device_log_path = Device.userDirectory .. '/DCSD/' .. getRestoreDeviceLogPath()


    start_time = os.time()
    local result = false
    repeat
        comFunc.sleep(1)
        local device_log = comFunc.fileRead(device_log_path)
        result = string.find(device_log, parmTab.AdditionalParameters.expect) ~= nil
    until (result or os.difftime(os.time(), start_time) > 10)

    local mlb_type = "MLB_A"
    if result
    then
        mlb_type = "MLB_B"
    end
    Record.createBinaryRecord(true, parmTab.Technology, "NonUI-DCSD", parmTab.AdditionalParameters.subsubtestname)
    return mlb_type
end

-- function M.check_device( parmTab )
--     local device_log_path = Device.userDirectory .. '/../system/device.log'
--     local device_log = comFunc.fileRead(device_log_path)
--     local result = string.find(device_log, parmTab.AdditionalParameters.expect) ~= nil
--     -- Log.LogInfo("$$$$ check :"..device_log..'\n\n\n $$$$ expect'..parmTab.AdditionalParameters.expect..'\n\n\n')
--     DataReporting.submit( DataReporting.createBinaryRecord( result, parmTab.Technology, parmTab.TestName, parmTab.AdditionalParameters.subsubtestname) )
-- end

-- function M.check_restore_device( parmTab )
--     local device_log_path = Device.userDirectory .. '/DCSD/' .. common.getRestoreDeviceLogPath()
--     local device_log = comFunc.fileRead(device_log_path)
--     local result = string.find(device_log, parmTab.AdditionalParameters.expect) ~= nil
--     -- Log.LogInfo("$$$$ check :"..device_log..'\n\n\n $$$$ expect'..parmTab.AdditionalParameters.expect..'\n\n\n')
--     DataReporting.submit( DataReporting.createBinaryRecord( result, parmTab.Technology, parmTab.TestName, parmTab.AdditionalParameters.subsubtestname) )
-- end

-- function M.check_restore_host( parmTab )
--     local host_log_path = Device.userDirectory .. '/DCSD/' .. common.getRestoreHostLogPath()
--     local host_log = comFunc.fileRead(host_log_path)
--     local result = string.find(host_log, parmTab.AdditionalParameters.expect) ~= nil
--     -- Log.LogInfo("$$$$ check :"..host_log..'\n\n\n $$$$ expect'..parmTab.AdditionalParameters.expect..'\n\n\n')
--     DataReporting.submit( DataReporting.createBinaryRecord( result, parmTab.Technology, parmTab.TestName, parmTab.AdditionalParameters.subsubtestname) )
-- end

function _Supply_ace_provisioning_power( parmTab )
    local vt = Device.getPlugin("VariableTable")

    local device_log_name = nil
    local ppvbus_14v_on_flag = vt.getVar("ppvbus_14v_on_flag")
    local ppvbus_14v_off_flag = vt.getVar("ppvbus_14v_off_flag")
    local ppvbus_14v_on_signal = "CHECKPOINT END: FIRMWARE:%[0x130A%] install_fud"
    local ppvbus_14v_off_signal = "CHECKPOINT END: %(null%):%[0x067F%] provision_ace2"

    device_log_name = getRestoreDeviceLogPath()

    if device_log_name ~= nil then

        local device_log_path = Device.userDirectory .. '/DCSD/' .. device_log_name
        local device_log = comFunc.fileRead(device_log_path)
        if not ppvbus_14v_on_flag then
            if string.find(device_log, ppvbus_14v_on_signal) then
                Log.LogInfo("$$$$ find keywords: " .. ppvbus_14v_on_signal .. '\n')
                local fixture = Device.getPlugin("FixturePlugin")
                local slot_num = tonumber(Device.identifier:sub(-1)) + 1
                -- DataReporting.submit( DataReporting.createBinaryRecord( true, "Restore", "Restore", "ace_provisioning_power_on") )
                fixture["ace_provisioning_power_on"](tonumber(slot_num))
                Log.LogInfo("$$$$ ace_provisioning_power_on")
                vt.setVar("ppvbus_14v_on_flag", true)
            end
        end
        if not ppvbus_14v_off_flag then
            if string.find(device_log, ppvbus_14v_off_signal) then
                Log.LogInfo("$$$$ find keywords: " .. ppvbus_14v_off_signal .. '\n')
                local fixture = Device.getPlugin("FixturePlugin")
                local slot_num = tonumber(Device.identifier:sub(-1)) + 1
                -- DataReporting.submit( DataReporting.createBinaryRecord( true, "Restore", "Restore", "ace_provisioning_power_off") )
                fixture["ace_provisioning_power_off"](tonumber(slot_num))
                Log.LogInfo("$$$$ ace_provisioning_power_off")
                vt.setVar("ppvbus_14v_off_flag", true)

            end
        end
    end

end

function M.restore_process_check(parmTab)
    local vt = Device.getPlugin("VariableTable")
    local startTime = os.time()
    local timeout = 300
    local result = false
    -- local progress = vt.getVar('restore_process')
    local log_device = tostring(parmTab.AdditionalParameters.log_device)
    local keywords = tostring(parmTab.AdditionalParameters.expect)

    
    local log_path = Device.userDirectory .. '/../system/device.log'

    local file_exists = false
    repeat
        if log_device == 'restore' then
            log_path = getRestoreDeviceLogPath()
            if log_path ~= nil then 
                file_exists = true 
                log_path = Device.userDirectory .. "/DCSD/".. log_path
            end
        elseif log_device == 'restore_host' then
            log_path = getRestoreHostLogPath()
            if log_path ~= nil then 
                file_exists = true 
                log_path = Device.userDirectory .. "/DCSD/".. log_path
            end
        else
            local files = shell.execute("ls " .. Device.userDirectory .. '/../system/')
            if string.match(files, "device.log") ~= nil then file_exists = true end
        end
    until (file_exists == true)


    -- local dcsd_plugin = Device.getPlugin("DCSD")
    -- local progress = dcsd_plugin.get_progress_plugin()
    Log.LogInfo("$$$$ restore_process_check log_device: " .. log_device)

    -- Device.updateProgress("progress check: "..keywords.." start")
    repeat
        _Supply_ace_provisioning_power(parmTab)
        local host_log = comFunc.fileRead(log_path)
        result = string.find(host_log, keywords) ~= nil
        -- if not progress.isRunning() then vt.setVar("restore_finish", true) end
        if result then break end

    until(vt.getVar("restore_finish") or os.difftime(os.time(), startTime) >= timeout)

    if parmTab.AdditionalParameters.subsubtestname == 'Restore_successful' then
        if not result then
            local fixture = Device.getPlugin("FixturePlugin")
            local slot_num = tonumber(Device.identifier:sub(-1)) + 1
            fixture.dut_power_off(slot_num)
            return "TRUE","restore failed."
        end
    end
    Record.createBinaryRecord(result, parmTab.Technology, parmTab.TestName, parmTab.AdditionalParameters.subsubtestname)
    return "FALSE"    
end

function M.startLogging(parmTab)
    Log.LogInfo('startLogging ....')
    local logger = Device.getPlugin("logger")

    if logger.isOpened() == 0 then
        logger.open()
    end

end

function M.stopLogging(parmTab)
    Log.LogInfo('stopLogging ....')
    local logger = Device.getPlugin("logger")

    if logger.isOpened() == 1 then
        logger.close()
    end
end

-- get_plugin_info @selector(getPluginInfo:)
-- parse_log_folder @selector(extractTestDataFromDeviceLog:hwModel:ecid:error:)
-- get_dcsd_dut_plugin @selector(loadDCSDDutPlugin:workspace:error:)
-- get_dcsd_cable_plugin @selector(loadDCSDCablePluginForUsbLocation:error:)
-- load_plist_file @selector(loadDCSDSettingsPluginWithFile:error:)
-- get_progress_plugin @selector(loadProgressPlugin:)

function M.restore(parmTab)
    Log.LogInfo("DCSD Restore ------>>>>>", parmTab)
    local timeout = parmTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 1500
    end

    local vt = Device.getPlugin('VariableTable')
    local locationId = parmTab.Input
    if locationId == nil or #locationId < 1 then
        vt.setVar("restore_finish",true)
        error("miss locationId")
        return
    end

    local usb_url = "lockdown://"..tostring(locationId)
    print("usb_url>>", usb_url)

    -- local dcsd_plugin = Device.getPlugin("DCSD")
    local dcsd_plugin = Atlas.loadPlugin("DCSD")
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
    local progress = dcsd_plugin.get_progress_plugin()
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
        -- Device.updateProgress("Restore...")
        comFunc.sleep(3)
    until(vt.getVar("restore_finish") or os.difftime(os.time(), startTime) >= timeout or not progress.isRunning())

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
    Record.createBinaryRecord(result, parmTab.Technology, "NonUI-DCSD", parmTab.AdditionalParameters.subsubtestname)
    
    local vt = Device.getPlugin("VariableTable")
    vt.setVar("restore_finish",true)
    Log.LogInfo("$$$$ restore done")
end

return M