local USBC = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local flow_log = require("Tech/WriteLog")

local otp_need_program = false
local ret_crc = ""
local otp_name = ""

local usb_flag = nil
local ret_result = nil
local re_Link_state = nil
local ret_Speed = nil
local ret_Link_ERRS = nil
local Link_ERRS = nil
local ReDriver_Number = nil
local ACE_ChipName = nil

local MD5_HARD = "7578a2f984e661b813326ee82662e2e4"
local SHA1_HARD = "7851c80a503e37b8c5cdefb0d24531ac676faf13"
local ace_size = "0x7d780"

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000098_1.0
-- USBC.getOTPWords(start_bit, bit_length,file_name)
-- Function to get OTP_FW bin file Words
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : string,number,number
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function USBC.getOTPWords(start_bit, bit_length, file_name)
    --Word0: Previous CRC "4c4b 603f"
    local OTP_PATH = "/Users/gdlocal/Library/Atlas2/supportFiles/customer/OTP_FW/"
    local path = OTP_PATH .. file_name
    local readBinFile = Device.getPlugin("DockChannel")

    if not tonumber(start_bit) and not tonumber(bit_length) then
        return USBC.getBinFile()
    end
    if not tonumber(start_bit) then
        start_bit = 0
    end
    if not tonumber(bit_length) then
        bit_length = 4
    end
    local result = readBinFile.getBinFileHex(path, tonumber(start_bit), tonumber(bit_length))
    return string.upper(result)

end

function get_keydata_start()
    local KeyDataStart_1 = USBC.getOTPWords(tonumber(0x50C), 1, otp_name)--0x4c
    KeyDataStart_1 = string.gsub(KeyDataStart_1, "0X", "")
    local KeyDataStart_2 = USBC.getOTPWords(tonumber(0x50D), 1, otp_name)--0x04
    KeyDataStart_2 = string.gsub(KeyDataStart_2, "0X", "")
    local KeyDataStart_3 = USBC.getOTPWords(tonumber(0x50E), 1, otp_name)--0x00
    KeyDataStart_3 = string.gsub(KeyDataStart_3, "0X", "")
    local KeyDataStart_4 = USBC.getOTPWords(tonumber(0x50F), 1, otp_name)--0x00
    KeyDataStart_4 = string.gsub(KeyDataStart_4, "0X", "")
    return "0x" .. KeyDataStart_4 .. KeyDataStart_3 .. KeyDataStart_2 .. KeyDataStart_1
end



--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000099_1.0
-- USBC.eraseFW( param )
-- Function to erase ace fw
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
function USBC.eraseFW(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 20000
    local read_chipid = fixture.fixture_command("ace_programmer_id", timeout, slot_num)
    local chipid = string.match(string.upper(read_chipid), "ID:(%w+,%w+,%w+)")

    if (chipid == "0X13,0XEF,0X4014") then
        ACE_ChipName = "w25q128"

    elseif (chipid == "0X14,0XC2,0X2814") then
        ACE_ChipName = "mx25v16"

    elseif (chipid == "0X13,0XC8,0X6014") then
        ACE_ChipName = "gd25xxx"   --at25xxx   
    else
        ACE_ChipName = "w25q128"
    end

    local cmd2 = "ace_programmer_erase_" .. ACE_ChipName
    local response = fixture.fixture_command(cmd2, timeout, slot_num)
    flow_log.writeFlowLog(cmd2 .. " " .. response)
    local result = false
    if string.find(response, "erasing target successfully") then
        result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
    return ACE_ChipName

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000100_1.0
-- USBC.programFW( param )
-- Function to program ace fw
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
function USBC.programFW(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 20000
    local cmd = "ace_programmer_only_" .. ACE_ChipName
    local response = fixture.fixture_command(cmd, timeout, slot_num)
    flow_log.writeFlowLog(cmd .. " " .. response)
    local result = false
    if string.find(response, "program ok") then
        result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000101_1.0
-- USBC.checkUUTACEFW( param )
-- Function to check uut fw for md5 and sha1
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
function USBC.checkUUTACEFW(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    local Local_FW = "/tmp/FixtureLog_CH" .. tostring(slot_num) .. "/ACE_FW.readback"
    RunShellCommand.run("rm " .. Local_FW)

    local timeout = 20000
    local addr = "0x00000000"
    local ACE_FW_Name = "/mix/addon/dut_firmware/ch1/ACE_FW.readback"
    local cmd = "ace_program_readverify"
    local ret = fixture.fixture_command(cmd, timeout, slot_num)
    flow_log.writeFlowLog(ret)

    fixture.getAndWriteFile(ACE_FW_Name, Local_FW, slot_num, timeout)
    local MD5_COMPUTED_XV = string.match(RunShellCommand.run("/sbin/md5 " .. Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(RunShellCommand.run("/usr/bin/openssl sha1 " .. Local_FW).output, "SHA1.-=%s(%w+)")

    local result = false
    if MD5_HARD == MD5_COMPUTED_XV and SHA1_HARD == SHA1_COMPUTED_XV then
        result = true
    end
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('USBC.checkUUTACEFW is error')
    end
    flow_log.writeFlowLog(MD5_COMPUTED_XV)
    flow_log.writeFlowLog(SHA1_COMPUTED_XV)

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000102_1.0
-- USBC.readGPIOVoltage(param)
-- Function to read gpio voltage
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
function USBC.readGPIOVoltage(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname or ""

    local ret = fixture.read_gpio_voltage(netname, slot_num)

    flow_log.writeFlowLog(ret)
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, ret)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000103_1.0
-- USBC.powerSet( param )
-- Function to set USB power output
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
function USBC.powerSet(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL", "OFF", slot_num)
    fixture.set_usb_voltage(0, "", slot_num)

    fixture.relay_switch("VDM_CC1", "DISCONNECT", slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR", "TO_PPVBUS_PROT", slot_num)
    os.execute("sleep 0.005")

    fixture.relay_switch("VBUS_OUTPUT_CTL", "ON", slot_num)
    local ret = fixture.set_usb_voltage(14000, "0-14000-3000", slot_num)

    flow_log.writeFlowLog(ret)

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    os.execute("sleep 0.005")
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000104_1.0
-- USBC.powerSetBack( param )
-- Function to reset power to default mode
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
function USBC.powerSetBack(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL", "OFF", slot_num)
    fixture.relay_switch("VDM_CC1", "DISCONNECT", slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR", "TO_PP_EXT", slot_num)
    fixture.relay_switch("VDM_VBUS_TO_PPVBUS_USB_EMI", "CONNECT", slot_num)
    fixture.relay_switch("VBUS_OUTPUT_CTL", "ON", slot_num)
    fixture.relay_switch("VDM_CC1", "TO_ACE_CC1", slot_num)

    local dut = Device.getPlugin("dut")
    local cmd = "ace --pick usbc --4cc SRDY --txdata \"0x00\" --rxdata 0"
    dut.write(cmd)
    local ret = dut.read(10)
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000105_1.0
-- USBC.getProductionMode( param )
-- Function to send diags command to judge dev_fuse_mode or prod_fuse_mode.
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
function USBC.getProductionMode(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern

    local production_mode = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { pattern = pattern, record = "NO", tick = "no" }, isNotTop = true })
    flow_log.writeFlowLog(production_mode)
    otp_name = ""

    local result = ""
    local b_result = true
    if production_mode == "0" then
        otp_name = "ACE2_J407_OTP_NONprod.bin"
        result = "dev_fuse_mode"
    elseif production_mode == "1" then
        otp_name = "ACE2_J407_OTP_Prod.bin"
        result = "prod_fuse_mode"
    else
        otp_name = ""
        result = "UnSet"
        b_result = false
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
    return result

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000106_1.0
-- USBC.setOTPPower( param )
-- Function to disconnect cc PPVBUS;set PPVBUS_PORT to 14v
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
function USBC.setOTPPower(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL", "OFF", slot_num)

    fixture.set_usb_voltage(0, "", slot_num)
    fixture.relay_switch("VDM_CC1", "DISCONNECT", slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR", "TO_PPVBUS_PROT", slot_num)
    os.execute("sleep 0.01")

    fixture.relay_switch("VBUS_OUTPUT_CTL", "ON", slot_num)
    fixture.set_usb_voltage(14000, "0-14000-3000", slot_num)
    os.execute("sleep 0.005")
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000107_1.0
-- USBC.verifyOperatingMode( param )
-- Function to verify ACE2 Operating STATE
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
function USBC.verifyOperatingMode(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern

    local ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { pattern = pattern, record = "NO", tick = "no" }, isNotTop = true })
    flow_log.writeFlowLog(ret)
    local result = "Verify_False"
    local b_result = false
    if ret == "41 50 50 20" or ret == "44 46 55 66" or ret == "42 4F 4F 54" then
        result = "Verify_Ace2_operating_state"
        b_result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
    return result

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000108_1.0
-- USBC.checkOTPCRC( param )
-- Function to Verify region state(CRC)
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
function USBC.checkOTPCRC(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    --Log.LogInfo(">>OTP_File_name=",otp_name)

    otp_need_program = false
    local pattern = "RxData%s*%(4.%).-%:.-0x0000%s*%:%s*(0x%w+%s+0x%w+%s+0x%w+%s+0x%w+)"
    local ret_crc = dutCmd.sendCmdAndParse({ Commands = "ace --4cc OTPr --txdata \"0x80\" --rxdata 4", AdditionalParameters = { pattern = pattern, record = "NO", tick = "no" }, isNotTop = true })

    local Final_CRC = USBC.getOTPWords(tonumber(0x514), 4, otp_name)
    Final_CRC = string.gsub(string.upper(Final_CRC), ",", " ")
    local PREVIOUS_CRC = USBC.getOTPWords(tonumber(0x500), 4, otp_name)
    PREVIOUS_CRC = string.gsub(string.upper(PREVIOUS_CRC), ",", " ")

    local result = ""
    local b_result = true
    if otp_name == "ACE2_J407_OTP_NONprod.bin" then
        if ret_crc == "0x06 0x0C 0x2C 0xD4" then
            --0x06 0x0C 0x2C 0xD4
            otp_need_program = "OTP_Need_Check_Key_Data_Size"
            result = "OTP_NEED_PROGRAM_CUSTOMER_WORDS"

        elseif string.upper(ret_crc) == Final_CRC then
            --0xB2 0x1B 0xA7 0x1D;
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "OTP_Already_PROGRAMMED"

        elseif string.upper(ret_crc) == PREVIOUS_CRC then
            --0xF5 0x43 0x2C 0xDA
            otp_need_program = "OTP_Need_Check_Key_Data_Size"
            result = "OTP_DONTNEED_PROGRAM"

        else
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "FAIL"
            b_result = false
        end

    elseif (otp_name == "ACE2_J407_OTP_Prod.bin") then
        --Only follow prod-fuse,need charge the opt_name to prod-fuse bin file
        -- if ret_crc=="0xC9 0xD9 0x5B 0x4D" then   --only checking
        if ret_crc == "0x06 0x0C 0x2C 0xD4" then
            --0x06 0x0C 0x2C 0xD4
            otp_need_program = "OTP_Need_Check_Key_Data_Size_prod_fuse"
            result = "OTP_NEED_PROGRAM_CUSTOMER_WORDS"

        elseif string.upper(ret_crc) == Final_CRC then
            --0xB2 0x1B 0xA7 0x1D
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "OTP_Already_PROGRAMMED"

        elseif string.upper(ret_crc) == PREVIOUS_CRC then
            --0xF5 0x43 0x2C 0xDA
            otp_need_program = "OTP_Need_Check_Key_Data_Size_prod_fuse"
            result = "OTP_DONTNEED_PROGRAM"

        else
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "FAIL"
            b_result = false
        end
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
    return result

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000109_1.0
-- USBC.getOTPProgramCustomerWords( param )
-- Function to ace OTP write customer words
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
function USBC.getOTPProgramCustomerWords(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local write_words = USBC.getOTPWords(0, 8, otp_name) ----0xaa,0x02,0x9f,0x66,0xb6,0x98,0x00,0x00
    write_words = string.gsub(string.upper(write_words), ",", " ")
    write_words = string.gsub(write_words, "0X", "0x")

    local cmd = "ace --4cc OTPw --txdata \"0x01 " .. write_words .. "\" --rxdata 64"

    local ret_crc = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
    flow_log.writeFlowLog(ret_crc)
    local b_result = true
    if string.find(string.lower(ret), "error") then
        otp_need_program = ""
        b_result = false
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000110_1.0
-- USBC.getOTPProgramFlag( param )
-- Function to flags to Key_Data_Size condition
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
function USBC.getOTPProgramFlag(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local result = ""
    if otp_need_program ~= nil then
        Log.LogInfo("otp_need_program=", otp_need_program)
        result = otp_need_program
        otp_need_program = ""

    else
        result = "OTP_DONTNEED_PROGRAM"
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
    return result

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000111_1.0
-- USBC.getCustomerDataSize( param )
-- Function to Read Application_Customization_Data_Size from bin file
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
function USBC.getCustomerDataSize(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local response = USBC.getOTPWords(tonumber(0x508), 4, otp_name)
    flow_log.writeFlowLog(response)
    response = string.gsub(string.upper(response), "0X", "")
    response = tostring(string.gsub(string.upper(response), ",", ""))

    local result = ""
    local b_result = true
    if response == "00000000" then
        result = "PASS_0"
        b_result = true
    else
        result = "FAIL_Size_Not_0"
        b_result = false
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('>> customer_Data_size 1: ' .. result)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
    return result
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000112_1.0
-- USBC.getKeySize( param )
-- Function to Key data size check
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
function USBC.getKeySize(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local response = USBC.getOTPWords(tonumber(0x510), 1, otp_name) --0x40

    local result = ""
    if response == "0X00" then
        result = tonumber(response)
    else
        result = "OTP_Key_SIZE_NOT_0"
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
    return result

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000113_1.0
-- USBC.writeOTP( param )
-- Function to ace OTP write key data crc
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : bool
-----------------------------------------------------------------------------------]]
function USBC.writeOTP(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1

    local b_result = false
    local result = "FALSE"

    if param1 == "otp_key_Data_flag" then
        --key data flag
        local keydata_flag = USBC.getOTPWords(tonumber(0x513), 1, otp_name)--0x03
        local cmd = "ace --4cc OTPi --txdata \"" .. keydata_flag .. "\" --rxdata 4"
        local ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        flow_log.writeFlowLog(ret)
        if string.find(string.lower(ret), "error") then
            b_result = false
        else
            b_result = true
            result = "TRUE"
        end

    elseif param1 == "otp_key_Data_value" then
        local keydata_value = ""
        local Key_Data_Size = USBC.getOTPWords(tonumber(0x510), 1, otp_name)
        if (string.upper(Key_Data_Size) == "0X20") then
            keydata_value = USBC.getOTPWords(tonumber(get_keydata_start()), 32, otp_name)    --0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8
            for i = 1, 32 do
                keydata_value = keydata_value .. ",0x00"
            end
        else
            keydata_value = USBC.getOTPWords(tonumber(get_keydata_start()), 64, otp_name) --0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8,0xea,0xbc,0xe0,0x4d,0xf1,0x4e,0x5d,0x81,0x22,0x4b,0x4f,0xc4,0x6a,0x25,0x4c,0x13,0x82,0x4e,0x8d,0x4c,0x2a,0xc7,0x1c,0xc8,0x5b,0x87,0xd1,0xa3,0x34,0x2d,0xc2,0x6a
        end
        keydata_value = string.gsub(string.upper(keydata_value), ",", " ")
        keydata_value = string.gsub(keydata_value, "0X", "0x")

        --key data value 0x85 0x1a 0x04 0x06 0xed 0x4f 0x7f 0xa4 0x1c 0x39 0x4b 0x75 0x87 0xab 0x3c 0x74 0x85 0x22 0x27 0x47 0x38 0x55 0x37 0x97 0x50 0x24 0x93 0x97 0x5a 0xef 0xa6 0x6d 0x3b 0xad 0xea 0x44 0xc5 0x9f 0xd0 0x52 0x44 0x32 0xbf 0x4c 0x14 0x3a 0x16 0x29 0xa0 0x66 0xc3 0x92 0xca 0x2e 0xc8 0x06 0xcb 0x39 0x39 0xb0 0x92 0xb8 0xb7 0x61    63
        local cmd = "ace --4cc OTPd --txdata \"" .. keydata_value .. "\" --rxdata 64"
        local ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        flow_log.writeFlowLog(ret)
        if string.find(string.lower(ret), "error") then
            b_result = false
        else
            b_result = true
            result = "TRUE"
        end

    elseif param1 == "key_Data_crc" then
        -- local Keydata_crc=global.getWord6()
        local Keydata_crc = USBC.getOTPWords(tonumber(0x518), 4, otp_name)--0xC4 0xB0 0x76 0x1E
        Keydata_crc = string.gsub(string.upper(Keydata_crc), ",", " ")
        Keydata_crc = string.gsub(Keydata_crc, "0X", "0x")
        --key data CRC  0xEC 0x06 0x28 0xFB
        local cmd = "ace --4cc OTPw --txdata \"0x04 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 " .. Keydata_crc .. "\" --rxdata 64"
        local ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        flow_log.writeFlowLog(ret)
        if string.find(string.lower(ret), "error") then
            b_result = false
        else
            b_result = true
            result = "TRUE"
        end
    else
        b_result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
    return result
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000114_1.0
-- USBC.readAndCheckOTP( param )
-- Function to Ace OTP CRC verify after write
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : bool
-----------------------------------------------------------------------------------]]
function USBC.readAndCheckOTP(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern
    local limitTab = param.limit
    local limit = nil
    local str_limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
        if limit then
            if limit.units == "string" then
                str_limit = limit.upperLimit
                flow_log.writeFlowLog("str_limit" .. limit.upperLimit)
            end
        end

    end
    local ret_crc = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { pattern = pattern, record = "NO", tick = "no" }, isNotTop = true })
    flow_log.writeFlowLog(ret_crc)
    local b_result = false

    if ret_crc ~= nil then

        b_result = true
    else
        ret_crc = "nil"
    end
    if str_limit ~= nil then
        if tostring(ret_crc) ~= str_limit then
            b_result = false
            -- Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
            -- flow_log.writeFlowLimitAndResult(paraTab, result)
        end
    end
    if param.AdditionalParameters.attribute ~= nil then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ret_crc))
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    if b_result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('USBC.readAndCheckOTP is error')
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
    return ret_crc

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000115_1.0
-- USBC.setOTPPowerBack( param )
-- Function to split string according to input split_char and save into one table
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
function USBC.setOTPPowerBack(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL", "OFF", slot_num)
    fixture.relay_switch("VDM_CC1", "DISCONNECT", slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR", "TO_PP_EXT", slot_num)
    fixture.relay_switch("VDM_VBUS_TO_PPVBUS_USB_EMI", "CONNECT", slot_num)

    fixture.set_usb_voltage(5000, "", slot_num)
    fixture.relay_switch("VBUS_OUTPUT_CTL", "ON", slot_num)
    os.execute("sleep 0.005")

    fixture.relay_switch("VDM_CC1", "TO_ACE_CC1", slot_num)
    os.execute("sleep 0.5")

    local ret = dutCmd.sendCmdAndParse({ Commands = "ace --pick usbc --4cc SRDY --txdata \"0x00\" --rxdata 0", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
    return "done"

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000116_1.0
-- USBC.parseLDCMString( param )
-- Function to parse diags response
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
function USBC.parseLDCMString(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local match_pattern = param.AdditionalParameters.pattern
    local match_pattern_limit = param.AdditionalParameters.pattern_limit

    local Set_limit = param.AdditionalParameters.param2
    local _last_diags_response = param.Input

    local report_limit = string.match(_last_diags_response, match_pattern_limit)
    report_limit = string.gsub(report_limit, ",", "_")

    local value = -999
    local result = false
    value = string.match(_last_diags_response, match_pattern)
    if (report_limit ~= Set_limit) then
        result = false
    else
        result = true
    end
    if value == nil then
        value = -998
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000117_1.0
-- USBC.usbfsCopyFile( param )
-- Function to usbfs mounting through ACE top usb
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
function USBC.usbfsCopyFile(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local file_name = param.AdditionalParameters.param1
    local slot_num = tonumber(Device.identifier:sub(-1))

    local host_root_path = param.AdditionalParameters.host_root_path
    local copy_list = param.AdditionalParameters.copy_list
    local toolPath =  param.AdditionalParameters.toolPath
    local cmd1 = "rm nandfs:\\AppleInternal\\usbfs_folder\\USBFS_TESTING.bin"
    local cmd2 = "dir nandfs:\\AppleInternal\\usbfs_folder"

    local ret =dutCmd.sendCmdAndParse({Commands=cmd1,AdditionalParameters={return_val="raw",record="NO",tick="no"}, isNotTop = true})
    flow_log.writeFlowLog(ret)
    ret = dutCmd.sendCmdAndParse({Commands=cmd2,AdditionalParameters={return_val="raw",record="NO",mark="1",timeout=2,tick="no"}, isNotTop = true})
    flow_log.writeFlowLog(ret)
    dutCmd.sendCmdAndParse({Commands='',AdditionalParameters={return_val="raw",record="NO",timeout=1,tick="no"}, isNotTop = true})
    local usbfs = Device.getPlugin("USBFS")
    local efi_dut = Device.getPlugin("dut")
    efi_dut.setDelimiter("] :-) ")
    usbfs.setHostToolPath(toolPath)
    usbfs.setDefaultTimeout(20)
    os.execute("sleep 1.5")
    local status, ret = xpcall(usbfs.copyToDevice, debug.traceback,efi_dut, host_root_path, copy_list)
    Log.LogInfo("$$$$ copyFileByUSBFS status " .. tostring(status) .. " ret " .. tostring(ret).."---end")
    flow_log.writeFlowLog(ret)

    local _last_diags_response = dutCmd.sendCmdAndParse({Commands=cmd2,AdditionalParameters={return_val="raw",record="NO",mark="1",timeout=2,tick="no"}, isNotTop = true})
    flow_log.writeFlowLog(_last_diags_response)
    local b_result = false
    if string.find(_last_diags_response, tostring(file_name)) then

        local ret =dutCmd.sendCmdAndParse({Commands=cmd1,AdditionalParameters={return_val="raw",record="NO",tick="no"}, isNotTop = true})
        b_result = true
        flow_log.writeFlowLog(ret)
        ret = dutCmd.sendCmdAndParse({Commands=cmd2,AdditionalParameters={return_val="raw",record="NO",mark="1",timeout=1,tick="no"}, isNotTop = true})
        flow_log.writeFlowLog(ret)
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000118_1.0
-- USBC.usb3Test( param )
-- Function to run the USB3 smokey test check the connect status
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
function USBC.usb3Test(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 2000

    local param1 = param.AdditionalParameters.param1

    local value = -999

    if param1 == "ACE_CC1" or param1 == "ACE_CC2" then

        dutCmd.sendCmdAndParse({ Commands = "device -k usbphy -e select 0", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        dutCmd.sendCmdAndParse({ Commands = "device -k UsbPhy -e disable usb", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })

        os.execute("sleep 0.1")
        re_Link_state = nil
        ret_Speed = nil
        ret_Link_ERRS = nil
        Link_ERRS = nil
        ReDriver_Number = nil
        dutCmd.sendCmdAndParse({ Commands = "device -k usbphy -e select 0", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })

        local _last_diags_response = dutCmd.sendCmdAndParse({ Commands = "device -k UsbPhy -e enable usb", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        flow_log.writeFlowLog(_last_diags_response)
        if string.find(_last_diags_response, "Enabled Phy!") then
            UsbInit = "Passed"
        end

        if param1 == "ACE_CC1" then

        elseif param1 == "ACE_CC2" then

        end

        flow_log.writeFlowLog(fixture.relay_switch("USB3_TO_5V", "CONNECT", slot_num))
        os.execute("sleep 0.2")

        for i = 1, 7, 1 do

            local _last_diags_response = dutCmd.sendCmdAndParse({ Commands = "device -k UsbPhy -p", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })

            ret_result = tostring(string.match(_last_diags_response, "status%:%s*%p(%a+)%p"))
            ret_Link_state = tostring(string.match(_last_diags_response, "state%:%s*%p(%a%d)%p"))
            ret_Link_ERRS = tostring(string.match(_last_diags_response, "link%s*errors%:%s*%p(%d+)%p"))
            ret_Speed = tostring(string.match(_last_diags_response, "speed%:%s*%p(%a+)%p"))
            ret_Link_ERRS = tonumber(ret_Link_ERRS)

            if ret_result == "Connected" and ret_Link_state == "U0" and ret_Speed == "SS" and ret_Link_ERRS <= 50 then
                ReDriver_Number = i
                dutCmd.sendCmdAndParse({ Commands = "device -k UsbPhy -e disable usb", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
                break
            else

                ret_Link_ERRS = 99999

                dutCmd.sendCmdAndParse({ Commands = "device -k UsbPhy -e disable usb", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
                os.execute("sleep 0.1")

                if i < 7 then

                    fixture.relay_switch("USB3_TO_5V", "DISCONNECT", slot_num)
                    os.execute("sleep 0.1")
                    dutCmd.sendCmdAndParse({ Commands = "device -k usbphy -e select 0", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
                    dutCmd.sendCmdAndParse({ Commands = "device -k UsbPhy -e enable usb", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
                    flow_log.writeFlowLog(fixture.relay_switch("USB3_TO_5V", "CONNECT", slot_num))
                    os.execute("sleep 0.2")

                end
            end

            ReDriver_Number = i

        end

        if ret_result == "Connected" then
            value = 1
        else
            value = -1
        end
    end

    if param1 == "Speed" then

        if ret_Speed == "SS" then

            value = 1
        else
            value = -1
        end
    end

    if param1 == "Link_state" then
        if ret_Link_state == "U0" then
            value = 1
        else
            value = -1
        end
    end

    if param1 == "Link_error" then

        Link_ERRS = tonumber(ret_Link_ERRS)
        if Link_ERRS <= 50 then
            value = 1
        else
            value = -1
        end
    end

    if param1 == "ReDriver" then
        value = ReDriver_Number
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]

        local lower = limit.lowerLimit
        local upper = limit.upperLimit

    end
    local recordResult = Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    if recordResult == false or recordResult == 0 then
        error(testname .. "-" .. subtestname .. "-" .. subsubtestname .. "usb3_test_only-fail")
        Log.LogInfo('sc--usb3_test_only-fail')
    else
        Log.LogInfo('sc--usb3_test_only-pass')
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000119_1.0
-- USBC.calculateACEBoost( param )
-- Function to calculate value = (VB_OUT_noEload)-(VB_OUT) and value=100*(VBUS_Eload_Current*VB_OUT/((IBATT_VB_ON-IBATT_VB_OFF)*VB_IN))
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
function USBC.calculateACEBoost(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1
    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(param.InputDict))
    local value = -9999

    if param1 == "delta" then

        local VB_OUT_noEload = inputDict.VB_OUT_noEload
        local VB_OUT = inputDict.PP5V2_ACE_BOOST_OUT
        value = tonumber(VB_OUT_noEload) - tonumber(VB_OUT)

    elseif param1 == "efficiency" then

        local VBUS_Eload_Current = tonumber(inputDict.VBUS_Eload_Current)
        local VB_OUT = tonumber(inputDict.PP5V2_ACE_BOOST_OUT)
        local IBATT_VB_ON = tonumber(inputDict.IBATT_VB_ON)
        local IBATT_VB_OFF = tonumber(inputDict.IBATT_VB_OFF)
        local VB_IN = tonumber(inputDict.PPVCC_MAIN_VIN)

        value = 100 * (VBUS_Eload_Current * VB_OUT / ((IBATT_VB_ON - IBATT_VB_OFF) * VB_IN))

    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
end

local vbus_result = nil
local cc1_result = nil
local cc2_result = nil

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000120_1.0
-- USBC.readACEVBUS( param )
-- Function to get the ACE report CC2 voltage<cc2*6/1024> cc2= third string 0x[xxxx]
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
function USBC.readACEVBUS(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local index = param.AdditionalParameters.param1

    local value = -999
    if index == "clear" then
        local a = nil
        local b = nil
        local c = nil
        local d = nil
        local e = nil
        local f = nil
        local vbus = nil
        local cc1 = nil
        local cc2 = nil

        vbus_result = nil
        cc1_result = nil
        cc2_result = nil

        dutCmd.sendCmdAndParse({ Commands = "ace --pick usbc", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        local dut_response = dutCmd.sendCmdAndParse({ Commands = "ace -r 0x6a", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
        flow_log.writeFlowLog(dut_response)
        --Log.LogInfo('$*** readvbus: '..tostring(dut_response))

        a, b = string.match(dut_response, "0000000%:%s*%w+%s*%w+%s*%w+%s*%w+%s*(%w+)%s*(%w+)")
        c, d = string.match(dut_response, "0000010%:%s*%w+%s*%w+%s*%w+%s*%w+%s*%w+%s%w+%s*(%w+)%s*(%w+)%s*")
        e, f = string.match(dut_response, "0000010%:%s*%w+%s*%w+%s*%w+%s*%w+%s*%w+%s%w+%s*(%w+)%s*(%w+)%s*")

        --Log.LogInfo('$*** readvbus 2: '..tostring(a).." "..tostring(b).." "..tostring(c).." "..tostring(d).." "..tostring(e).." "..tostring(f))
        a = tostring(a)
        b = tostring(b)
        c = tostring(c)
        d = tostring(d)
        e = tostring(e)
        f = tostring(f)

        vbus = "0x" .. b .. a
        --Log.LogInfo('$*** readvbus 3: '..tostring(vbus))
        vbus = tonumber(vbus)
        --Log.LogInfo('$*** readvbus 4: '..tostring(vbus))
        if vbus ~= nil then
            vbus_result = vbus * 30 / 1024
            cc1 = "0x" .. d .. c
            cc1 = tonumber(cc1)
            cc1_result = cc1 * 6 / 1024
            cc2 = "0x" .. f .. e
            cc2 = tonumber(cc2)
            cc2_result = cc2 * 6 / 1024

            value = 1
        else
            value = -999
        end

    end

    if index == "vbus" then
        value = vbus_result
    end

    if index == "cc1" then
        value = cc1_result
    end

    if index == "cc2" then
        value = cc2_result
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000121_1.0
-- USBC.calculateVBATError( param )
-- Function to pmuadc read vbat.  VBAT_ERROR: value = (PPBATT_VCC-PMU_VBAT)/PPBATT_VCC*100; IBAT_ERROR:value = ((BATT_CURRENT_BIG)-(PMU_IBAT_OUT))/(BATT_CURRENT_BIG)*100
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
function USBC.calculateVBATError(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1
    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(param.InputDict))

    local value = -9999

    if param1 == "VBAT_ERROR" then

        local PPBATT_VCC = tonumber(inputDict.PPBATT_VCC)
        local PMU_VBAT = tonumber(inputDict.PMU_VBAT)
        value = (PPBATT_VCC - PMU_VBAT) / PPBATT_VCC * 100
        value = string.format("%.3f", value)

    elseif param1 == "IBAT_ERROR" then

        local BATT_CURRENT_BIG = tonumber(inputDict.BATT_CURRENT_BIG)
        local PMU_IBAT_OUT = tonumber(inputDict.PMU_IBAT_OUT)

        value = (tonumber(BATT_CURRENT_BIG) - tonumber(PMU_IBAT_OUT)) / tonumber(BATT_CURRENT_BIG) * 100
        value = string.format("%.3f", value)

    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value

end

return USBC


