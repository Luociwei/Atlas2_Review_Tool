local Fixture = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

local MD5_HARD = "7578a2f984e661b813326ee82662e2e4"
local SHA1_HARD = "7851c80a503e37b8c5cdefb0d24531ac676faf13"
local fw_version = "J407-USBC-2.116.0.3-P0_R-AP-S.bin"

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000037_1.0
-- Fixture.sendLedCommand(param)
-- Function to control fixture LED display, running LED, PASS LED, FAIL LED
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.sendLedCommand(param)
    local testname = param.Technology
    local subtestname = param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local eowyn = Device.getPlugin("Eowyn")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local command = param.Commands
    if command == "led_progress_on" then
        eowyn.led_inprogress_on(slot_num)

    elseif command == "led_red_on" then
        eowyn.led_red_on(slot_num)

    elseif command == "led_green_on" then
        eowyn.led_green_on(slot_num)
    end

    flow_log.writeFlowLog(command)
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "True")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000038_1.0
-- Fixture.getSlotID(param)
-- Function to send command to eeprom, get each slot ID
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function Fixture.getSlotID(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local fixture = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20

    local fixture_serial_number = fixture.get_serial_number("testbase", slot_num)
    DataReporting.fixtureID(fixture_serial_number, tostring(slot_num))
    --Log.LogInfo('$$$$ fixture_serial_number: '..fixture_serial_number..' headID: '..slot_num)
    flow_log.writeFlowLog(fixture_serial_number)

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(slot_num), testname, subtestname, subsubtestname, limit)

    flow_log.writeFlowLimitAndResult(param, slot_num)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    return fixture_serial_number
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000039_1.0
-- Fixture.getVendorID(param)
-- Function to get FCT vendor ID, suncode ID is 1
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function Fixture.getVendorID(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local vendor_id = fixture.get_vendor_id()

    local limit = nil
    local limitTab = param.limit
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(vendor_id), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, vendor_id)
    return vendor_id
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000040_1.0
-- Fixture.getStationName(param)
-- Function to get FCT station name, J407 is LA
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function Fixture.getStationName(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local station_name = "LA"
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, station_name)
    return station_name
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000041_1.0
-- Fixture.checkLocalACEFW(param)
-- Function to compare ACE fw md5 and hash code from Mac mini
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.checkLocalACEFW(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)

    local local_fw_path = "/Users/gdlocal/Library/Atlas2/supportFiles/customer/ACE_FW/bin"
    local local_fw_fullpath = tostring(local_fw_path .. "/" .. fw_version)
    Log.LogInfo('$$$$ local_fw_fullpath: ' .. local_fw_fullpath)
    flow_log.writeFlowLog(local_fw_fullpath)
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")

    local MD5_COMPUTED_MM = string.match(RunShellCommand.run("/sbin/md5 " .. local_fw_fullpath).output, "MD5.-=%s(%w+)")
    Log.LogInfo('$$$$ MD5_COMPUTED_MM: ' .. MD5_COMPUTED_MM)
    flow_log.writeFlowLog(MD5_COMPUTED_MM)
    local SHA1_COMPUTED_MM = string.match(RunShellCommand.run("/usr/bin/openssl sha1 " .. local_fw_fullpath).output, "SHA1.-=%s(%w+)")
    Log.LogInfo('$$$$ openssl_COMPUTED_MM: ' .. SHA1_COMPUTED_MM)
    flow_log.writeFlowLog(SHA1_COMPUTED_MM)
    local result = false
    if MD5_HARD == MD5_COMPUTED_MM and SHA1_HARD == SHA1_COMPUTED_MM then
        result = true
    end
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('Fixture.checkLocalACEFW is error')
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(param, result)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000042_1.0
-- Fixture.checkXavierACEFW(param)
-- Function to compare ACE fw md5 and hash code from Xavier
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.checkXavierACEFW(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local slot_num = tonumber(Device.identifier:sub(-1))

    local Save_path = "/tmp/FixtureLog_CH" .. tostring(slot_num)
    local Local_FW = Save_path .. "/" .. fw_version
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    RunShellCommand.run("mkdir " .. Save_path)
    RunShellCommand.run("rm " .. Local_FW)
    Log.LogInfo(">RunShellCommand.run>===")

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 5000
    local ret = fixture.getAndWriteFile("/mix/addon/dut_firmware/ch1/" .. fw_version, Local_FW, slot_num, timeout)
    flow_log.writeFlowLog(ret)
    local MD5_COMPUTED_XV = string.match(RunShellCommand.run("/sbin/md5 " .. Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(RunShellCommand.run("/usr/bin/openssl sha1 " .. Local_FW).output, "SHA1.-=%s(%w+)")

    local result = false
    if MD5_HARD == MD5_COMPUTED_XV and SHA1_HARD == SHA1_COMPUTED_XV then
        result = true
    end
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('Fixture.checkXavierACEFW is error')
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000043_1.0
-- Fixture.resetXavier(param)
-- Function to reset Xavier, call fixture.reset(slot_num) function 
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.resetXavier(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ret = fixture.reset(slot_num)

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    if string.find(string.lower(tostring(ret)), "err") and param.AdditionalParameters.fa_sof == "YES" then
        error('Fixture.resetXavier is error')
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000044_1.0
-- Fixture.checkDUT(param)
-- Function to check MLB in fixture or not. if voltage <100mV, then fixture has MLB, otherwise, no MLB in fixture
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.checkDUT(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ret = tonumber(fixture.dut_detect(slot_num))

    local result = false
    if ret == 1 then
        result = true
    end
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('Fixture.checkDUT is error')
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, tostring(result))
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000045_1.0
-- Fixture.checkSlotSN(param)
-- Function to check whether this fixture SN is for this slot and Mac mini
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.checkSlotSN(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)

    local StationInfo = Atlas.loadPlugin("StationInfo").station_id()
    local station_number = comFunc.splitBySeveralDelimiter(StationInfo, '_')[3]
    flow_log.writeFlowLog("station_number : " .. tostring(station_number))

    if tonumber(station_number) < 10 then
        station_number = "00" .. station_number
    elseif tonumber(station_number) >= 10 and tonumber(station_number) < 100 then
        station_number = "0" .. station_number
    end

    local station_type = "LA"
    local slot_num = tonumber(Device.identifier:sub(-1))
    local data_str = station_type .. "_FCT_#" .. station_number .. "_UUT" .. tostring(slot_num)
    log.LogInfo(string.format("fixtureSN: %s", data_str))

    local ret = param.Input

    flow_log.writeFlowLog(tostring(ret))
    local result = false
    if ret == data_str then
        result = true
    end
    if param.AdditionalParameters.attribute ~= nil and result == true then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ret))
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end
function Fixture.check_fixture_sn(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local ret1 = Fixture.checkboardsn("wib")
    local ret2 = Fixture.checkboardsn("sib")
    local ret = ret1 .. ret2
    local result = false
    if string.find(ret, "-1") then
        result = false
    else
        result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(param, result)
end
function Fixture.checkboardsn(board)
    local sn_addr = ""
    local data_str = ""
    local station_type = ""
    local fixture = Device.getPlugin("FixturePlugin")
    local product = Atlas.loadPlugin("StationInfo").product()
    local slot_num = tonumber(Device.identifier:sub(-1))
    local StationInfo = Atlas.loadPlugin("StationInfo").station_id()
    local station_number = comFunc.splitBySeveralDelimiter(StationInfo, '_')[3]

    if tonumber(station_number) < 10 then
        station_number = "00" .. station_number
    elseif tonumber(station_number) >= 10 and tonumber(station_number) < 100 then
        station_number = "0" .. station_number
    end

    if tostring(product) == "J407" then
        station_type = "LA"
    end

    if board == "testbase" then
        sn_addr = "0x0A70"
        data_str = station_type .. "_FCT_#" .. station_number .. "_UUT" .. tostring(slot_num)
    elseif board == "power" then
        sn_addr = "0x00"
        data_str = station_type .. "FCT#" .. station_number .. "_POWER" .. tostring(slot_num)
    elseif board == "wib" then
        sn_addr = "0x00"
        data_str = station_type .. "_FCT_#" .. station_number .. "_WIB1"
    elseif board == "sib" then
        sn_addr = "0x00"
        if tostring(slot_num) == "1" or tostring(slot_num) == "2" then
            data_str = station_type .. "_FCT_#" .. station_number .. "_SIB1"
        elseif tostring(slot_num) == "3" or tostring(slot_num) == "4" then

            data_str = station_type .. "_FCT_#" .. station_number .. "_SIB2"
        end
    elseif board == "bridge" then
        sn_addr = "0x00"
        data_str = station_type .. "_FCT_#" .. station_number .. "_HUB1"
    end
    local sn = fixture.get_serial_number(tostring(board), slot_num)
    -- sn = string.match(sn,"ACK%(%s*\"(.-)\"%s*;DONE")
    flow_log.writeFlowLog("board" .. board .. "data_str==" .. data_str .. "sn==" .. tostring(sn))
    if sn == data_str then
        return sn
    else
        return "--Fail---1"
    end

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000046_1.0
-- Fixture.readMIXModuleSN(param)
-- Function to read Eload-module,OAB3-module,Scope-module,VDM-module SN
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.readMIXModuleSN(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local cmd = param.Commands
    local ret = fixture.fixture_command(cmd, 5000, slot_num)
    local b_result = false
    local board_version = string.sub(ret, 12, 15)
    if string.find(cmd, "vdm") then
        if board_version == "Q1QP" then
            b_result = true
        else
            b_result = false
        end
    elseif string.find(cmd, "eload") then
        if board_version == "LWFT" then
            b_result = true
        else
            b_result = false
        end
    elseif string.find(cmd, "scope") then
        if board_version == "LWFV" then
            b_result = true
        else
            b_result = false
        end
    elseif string.find(cmd, "oab3") then
        if board_version == "MKQX" then
            b_result = true
        else
            b_result = false
        end
    end
    flow_log.writeFlowLog(cmd .. " " .. tostring(ret))
    if param.AdditionalParameters.attribute ~= nil and b_result == true then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ret))
    end

    -- local b_result = false
    -- if #ret >0 then
    --     b_result = true
    -- end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        if b_result == false then
            Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
        end
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000047_1.0
-- Fixture.readMIXVersion(param)
-- Function to read xavier FW version
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.readMIXVersion(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ver = fixture.get_fw_version(slot_num)

    if param.AdditionalParameters.attribute ~= nil and ver then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ver))
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, true)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000048_1.0
-- Fixture.checkMIXIP(param)
-- Function to read xavier IP address by each slot
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.checkMIXIP(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ret = fixture.fixture_command("get_xavier_ip", 5000, slot_num)

    flow_log.writeFlowLog(ret)
    local ip = "169.254.1.3" .. tostring(1 + slot_num)
    if param.AdditionalParameters.attribute ~= nil and ip then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ip))
    end

    local result = false
    if ret == ip then
        result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000049_1.0
-- Fixture.sendFixtureCmd( param )
-- Function to send command to Xavier
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.sendFixtureCmd(param)
    flow_log.writeFlowLogStart(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local command = param.Commands

    flow_log.writeFlowLog("[fixture_cmd_send] :  " .. command)
    local ret = fixture.fixture_command(command, 10000, slot_num)
    flow_log.writeFlowLog("[fixture_cmd_recv] : " .. tostring(ret))

    if param.AdditionalParameters.pattern ~= nil then
        local pattern = param.AdditionalParameters.pattern
        ret = string.match(ret, pattern)
        if param.AdditionalParameters.reference ~= nil and ret ~= param.AdditionalParameters.reference then
            for i = 1, 10 do
                ret = fixture.fixture_command(command, 10000, slot_num)
                os.execute("sleep 0.5")
                flow_log.writeFlowLog(command .. " ---> " .. ret)
                ret = string.match(ret, pattern)
                if ret == param.AdditionalParameters.reference then
                    break
                end
            end
        end
    end

    local result = true
    if string.find(ret, "ERR") then
        result = false
    elseif param.AdditionalParameters.reference ~= nil and ret ~= param.AdditionalParameters.reference then
        result = false
    end
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('Fixture.sendFixtureCmd is error')
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        if param.AdditionalParameters.parametric ~= nil then
            local limitTab = param.limit
            local limit = nil
            if limitTab then
                limit = limitTab[param.AdditionalParameters.subsubtestname]
            end
            Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
        else
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end
    flow_log.writeFlowLimitAndResult(param, "true")
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000050_1.0
-- Fixture.sendVDMCmd( param )
-- Function to send VDM command
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Fixture.sendVDMCmd(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local cmd = param.Commands
    local pdo_number, voltage, max_current, source_switch = string.match(cmd, "%((%d)%*(%d*)%*(%d*)%*(%S*)%)")
    local timeout = 5000
    local ret = fixture.vdm_set_source_capabilities(tonumber(pdo_number), source_switch, tonumber(voltage), tonumber(max_current), "", slot_num, timeout)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLog(ret)
    flow_log.writeFlowLimitAndResult(param, "sendVDMCmd_Done")
    return ret
end

function Fixture.checkEloadVersion(param)
    flow_log.writeFlowLogStart(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local command = param.Commands
    local result = true
    flow_log.writeFlowLog("[fixture_cmd_send] :  " .. command)
    local ret = fixture.fixture_command(command, 10000, slot_num)
    flow_log.writeFlowLog("[fixture_cmd_recv] : " .. tostring(ret))

    if param.AdditionalParameters.pattern ~= nil then
        local pattern = param.AdditionalParameters.pattern
        ret = string.match(ret, pattern)
    end
    if ret ~= "02D" then
        result = false
    end
    
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('Fixture.checkEloadVersion is error')
    end

    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)

end
return Fixture


