local USBC = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local plist2lua = require("Matchbox/plist2lua")

local ACE_ChipName = nil

local otp_need_program =false
local ret_crc = ""
local otp_name = ""

local ACE_FW_CONFIG = plist2lua.read("/Users/gdlocal/Library/Atlas2/supportFiles/customer/ACE_FW/bin/checksum.plist")
local ACE_BIN_FILE_NAME = ACE_FW_CONFIG["ACE_FW"]["BIN_FILE_NAME"]
local MD5_HARD = ACE_FW_CONFIG["ACE_FW"]["MD5"]
local SHA1_HARD = ACE_FW_CONFIG["ACE_FW"]["SHA1"]


local function sendCmdAndParse(paraTab)
    local ret = dutCmd.sendCmd(paraTab)
    if paraTab.AdditionalParameters.pattern ~= nil then
        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret, pattern)
    end

    return ret
end


local function readAll(filePath)
    local f = assert(io.open(filePath, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local function bytesToHexStr(filePath, start_bit, bit_length)
    local content = readAll(filePath)
    local result = ""
    local len = string.len(content)
    if start_bit == -1 then
        start_bit = 0
    end
    if bit_length == -1 then
        bit_length = #len
    end
    for i = start_bit+1, start_bit+bit_length do
        local charcode = tonumber(string.byte(content, i, i))
        local hexstr = string.format("0x%02X ", charcode)
        result = result .. hexstr
    end
    if #result > 0 then
        result = string.sub(result,0,#result-1)
    end

    return result
end

local function get_keydata_start()
    local KeyDataStart_1=USBC.getOTPWords(tonumber(0x50C),1,otp_name)--0x4c
    KeyDataStart_1=string.gsub(KeyDataStart_1,"0X","")
    local KeyDataStart_2=USBC.getOTPWords(tonumber(0x50D),1,otp_name)--0x04
    KeyDataStart_2=string.gsub(KeyDataStart_2,"0X","")
    local KeyDataStart_3=USBC.getOTPWords(tonumber(0x50E),1,otp_name)--0x00
    KeyDataStart_3=string.gsub(KeyDataStart_3,"0X","")
    local KeyDataStart_4=USBC.getOTPWords(tonumber(0x50F),1,otp_name)--0x00
    KeyDataStart_4=string.gsub(KeyDataStart_4,"0X","")
    return "0x"..KeyDataStart_4..KeyDataStart_3..KeyDataStart_2..KeyDataStart_1
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000098_1.0
-- USBC.getOTPWords(start_bit, bit_length,file_name)
-- Function to get OTP_FW bin file Words with lua code
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : Roy Fang
-- Modification Date             : 10/27/2021     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : string,number,number
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function USBC.getOTPWords(start_bit, bit_length,file_name)
    local OTP_PATH = "/Users/gdlocal/Library/Atlas2/supportFiles/customer/OTP_FW/"
    local path = OTP_PATH..file_name

    if not tonumber(start_bit) and not tonumber(bit_length) then return bytesToHexStr(path,-1,-1) end
    if not tonumber(start_bit) then start_bit=0 end
    if not tonumber(bit_length) then bit_length=4 end
    local x = 1
    local result =bytesToHexStr(path,tonumber(start_bit),tonumber(bit_length))
    -- return result
    return string.upper(result)
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
function USBC.getProductionMode( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    -- local cmd = param.Commands
    -- local pattern = param.AdditionalParameters.pattern

    local production_mode = sendCmdAndParse(param)
    Log.LogInfo(production_mode)
    otp_name=""
    
    local result = ""
    local b_result = true
    if production_mode == "0" then
        otp_name="ACE2_J407_OTP_NONprod.bin"
        result = "dev_fuse_mode"
    elseif production_mode == "1" then
        otp_name="ACE2_J407_OTP_Prod.bin"
        result = "prod_fuse_mode"
    else
        otp_name=""
        result = "UnSet"
        b_result = false
        error('Error: Fail to get otp_name[production_mode == '..production_mode..']')
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result==false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('getProductionMode_production_mode:'..result..'_end')
    
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
function USBC.setOTPPower( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.ace_provisioning_power_on(tonumber(Device.identifier:sub(-1)))

    os.execute("sleep 0.005")
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    
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
function USBC.verifyOperatingMode( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern

    local ret = sendCmdAndParse(param)
    -- Log.LogInfo(ret)
    local result = "Verify_False"
    local b_result = false
    if ret == "41 50 50 20" or ret == "44 46 55 66" or ret =="42 4F 4F 54" then
        result = "Verify_Ace2_operating_state"
        b_result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('verifyOperatingMode_otp_check_crc_flag:'..result..'end')
    
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
function USBC.checkOTPCRC( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    --Log.LogInfo(">>OTP_File_name=",otp_name)
    Log.LogInfo(">>checkOTPCRC_otp_name="..otp_name..'--end')

    otp_need_program = false
    local pattern = "RxData%s*%(4.%).-%:.-0x0000%s*%:%s*(0x%w+%s+0x%w+%s+0x%w+%s+0x%w+)"
    param.Commands="ace --4cc OTPr --txdata \"0x80\" --rxdata 4"
    param.AdditionalParameters.pattern = pattern
    local ret_crc = sendCmdAndParse(param)
    Log.LogInfo('checkOTPCRC_ret_crc'..ret_crc..'--end')
    local Final_CRC=USBC.getOTPWords(tonumber(0x514),4,otp_name)
    Final_CRC=string.gsub(string.upper(Final_CRC),","," ")
    local PREVIOUS_CRC=USBC.getOTPWords(tonumber(0x500),4,otp_name)
    PREVIOUS_CRC=string.gsub(string.upper(PREVIOUS_CRC),","," ")
    Log.LogInfo('PREVIOUS_CRC: '..PREVIOUS_CRC..' Final_CRC:'..Final_CRC)

    local result = ""
    local b_result = true
    if otp_name=="ACE2_J407_OTP_NONprod.bin" then
        if ret_crc=="0x06 0x0C 0x2C 0xD4" then  --0x06 0x0C 0x2C 0xD4
            otp_need_program = "OTP_Need_Check_Key_Data_Size"
            result = "OTP_NEED_PROGRAM_CUSTOMER_WORDS"

        elseif string.upper(ret_crc) == Final_CRC then  --0xB2 0x1B 0xA7 0x1D;
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "OTP_Already_PROGRAMMED"

        elseif string.upper(ret_crc)==PREVIOUS_CRC then --0xF5 0x43 0x2C 0xDA
            otp_need_program = "OTP_Need_Check_Key_Data_Size"
            result = "OTP_DONTNEED_PROGRAM"

        else
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "FAIL"
            b_result = false
        end

    elseif(otp_name=="ACE2_J407_OTP_Prod.bin")then --Only follow prod-fuse,need charge the opt_name to prod-fuse bin file
        -- if ret_crc=="0xC9 0xD9 0x5B 0x4D" then   --only checking
        if ret_crc=="0x06 0x0C 0x2C 0xD4" then  --0x06 0x0C 0x2C 0xD4
            otp_need_program = "OTP_Need_Check_Key_Data_Size_prod_fuse"
            result = "OTP_NEED_PROGRAM_CUSTOMER_WORDS"

        elseif string.upper(ret_crc) == Final_CRC then  --0xB2 0x1B 0xA7 0x1D
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "OTP_Already_PROGRAMMED"

        elseif string.upper(ret_crc)==PREVIOUS_CRC then --0xF5 0x43 0x2C 0xDA
            otp_need_program = "OTP_Need_Check_Key_Data_Size_prod_fuse"
            result = "OTP_DONTNEED_PROGRAM"

        else
            otp_need_program = "OTP_DONTNEED_PROGRAM"
            result = "FAIL"
            b_result = false
        end
    end
    Log.LogInfo('check otp_need_program '..otp_need_program..'--end')

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('checkOTPCRC_otp_program_words_flag'..result..'--end')
    
    if b_result == false then
        error('CRC Check FAIL')
    end
    
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
function USBC.getOTPProgramCustomerWords( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    Log.LogInfo(">>getOTPProgramCustomerWords_otp_name="..otp_name..'--end')
    local write_words=USBC.getOTPWords(0,8,otp_name) ----0xaa,0x02,0x9f,0x66,0xb6,0x98,0x00,0x00
    write_words=string.gsub(string.upper(write_words),","," ")
    write_words=string.gsub(write_words,"0X","0x")

    local cmd = "ace --4cc OTPw --txdata \"0x01 "..write_words.."\" --rxdata 64"
    param.Commands = cmd
    local ret = sendCmdAndParse(param)
    -- Log.LogInfo(ret)
    local b_result = true
    if string.find(ret,"Error") then
        otp_need_program=""
        b_result = false
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end

    if b_result == false then
        error('write OTP Customer Words FAIL')
    end
    
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
function USBC.getOTPProgramFlag( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    local result = ""
    if otp_need_program ~= nil then
        Log.LogInfo("otp_need_program=",otp_need_program)
        result = otp_need_program
        otp_need_program=""

    else
        result = "OTP_DONTNEED_PROGRAM"
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('getOTPProgramFlag_otp_program_flag:'..result..'_end')
    
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
function USBC.getCustomerDataSize( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    Log.LogInfo(">>getCustomerDataSize_otp_name="..otp_name..'--end')
    local respone=USBC.getOTPWords(tonumber(0x508),4,otp_name)
    Log.LogInfo('getCustomerDataSize '..respone)
    respone=string.gsub(string.upper(respone),"0X","")
    respone=tostring(string.gsub(string.upper(respone)," ",""))

    local result =""
    local b_result = true
    if respone=="00000000"then
        result = "PASS_0"
        b_result = true
    else
        result = "FAIL_Size_Not_0"
        b_result = false
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result==false  then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('>> customer_Data_size 1: '..result)
    
    Log.LogInfo('getCustomerDataSize_otp_customer_Data_size:'..result)
    if b_result == false then
        error('Customer DataSize not Zero, size:'..respone)
    end
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
function USBC.getKeySize( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    Log.LogInfo(">>getKeySize_otp_name="..otp_name..'--end')
    local respone = USBC.getOTPWords(tonumber(0x510),1,otp_name) --0x40

    local result=""
    if respone == "0X00" then
        result = tonumber(respone)
    else
        result = "OTP_Key_SIZE_NOT_0"
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('getKeySize_otp_program_keydata_Size:'..result..'_end')
    
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
function USBC.writeOTP( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    Log.LogInfo(">>writeOTP_otp_name="..otp_name..'--end')
    local param1 = param.AdditionalParameters.param1

    local b_result = false
    local result= "FALSE"

    if param1 == "otp_key_Data_flag" then
        --key data flag
        local keydata_flag=USBC.getOTPWords(tonumber(0x513),1,otp_name)--0x03
        local cmd = "ace --4cc OTPi --txdata \""..keydata_flag.."\" --rxdata 4"
        param.Commands = cmd
        local ret = sendCmdAndParse(param)
        if string.find(ret,"Error") then 
            b_result = false
        else
            b_result = true
            result= "TRUE"
        end
   
    elseif param1 == "otp_key_Data_value" then
        local keydata_value=""
        local Key_Data_Size=USBC.getOTPWords(tonumber(0x510),1,otp_name)
        if(string.upper(Key_Data_Size)=="0X20") then
            keydata_value=USBC.getOTPWords(tonumber(get_keydata_start()),32,otp_name)    --0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8           
            for i=1,32 do
                keydata_value=keydata_value..",0x00"            
            end
        else
            keydata_value=USBC.getOTPWords(tonumber(get_keydata_start()),64,otp_name) --0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8,0xea,0xbc,0xe0,0x4d,0xf1,0x4e,0x5d,0x81,0x22,0x4b,0x4f,0xc4,0x6a,0x25,0x4c,0x13,0x82,0x4e,0x8d,0x4c,0x2a,0xc7,0x1c,0xc8,0x5b,0x87,0xd1,0xa3,0x34,0x2d,0xc2,0x6a
        end
        keydata_value=string.gsub(string.upper(keydata_value),","," ")
        keydata_value=string.gsub(keydata_value,"0X","0x")
    
        --key data value 0x85 0x1a 0x04 0x06 0xed 0x4f 0x7f 0xa4 0x1c 0x39 0x4b 0x75 0x87 0xab 0x3c 0x74 0x85 0x22 0x27 0x47 0x38 0x55 0x37 0x97 0x50 0x24 0x93 0x97 0x5a 0xef 0xa6 0x6d 0x3b 0xad 0xea 0x44 0xc5 0x9f 0xd0 0x52 0x44 0x32 0xbf 0x4c 0x14 0x3a 0x16 0x29 0xa0 0x66 0xc3 0x92 0xca 0x2e 0xc8 0x06 0xcb 0x39 0x39 0xb0 0x92 0xb8 0xb7 0x61    63
        param.Commands = "ace --4cc OTPd --txdata \""..keydata_value.."\" --rxdata 64"
        local ret = sendCmdAndParse(param)
        if string.find(ret,"Error") then
            b_result = false
        else
            b_result = true
            result= "TRUE"
        end

   elseif param1 == "key_Data_crc" then
        -- local Keydata_crc=global.getWord6()
        local Keydata_crc=USBC.getOTPWords(tonumber(0x518),4,otp_name)--0xC4 0xB0 0x76 0x1E
        Keydata_crc=string.gsub(string.upper(Keydata_crc),","," ")
        Keydata_crc=string.gsub(Keydata_crc,"0X","0x")
        --key data CRC  0xEC 0x06 0x28 0xFB
        param.Commands = "ace --4cc OTPw --txdata \"0x04 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 "..Keydata_crc.."\" --rxdata 64"
        local ret = sendCmdAndParse(param)
        if string.find(ret,"Error") then
            b_result = false
         else
            b_result = true
            result= "TRUE"
        end
    else
        b_result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result== false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Log.LogInfo('writeOTP_result:'..result..'_end')

    if b_result == false then
        error(param1 ..'Error')
    end
    
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
function USBC.readAndCheckOTP( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    -- local cmd = param.Commands
    -- local pattern = param.AdditionalParameters.pattern
    

    local ret_crc = sendCmdAndParse(param)
    -- Log.LogInfo(ret_crc)
    local b_result = false

    if ret_crc ~= nil then

        b_result = true
    else
        ret_crc = "nil"
    end

    if param.AdditionalParameters.attribute ~= nil then

        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ret_crc) )
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result== false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    
    if b_result == false then
        error('readAndCheckOTP Error')
    end
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
function USBC.setOTPPowerBack( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    fixture.ace_provisioning_power_off(tonumber(Device.identifier:sub(-1)))
    param.Commands = "ace --pick usbc --4cc SRDY --txdata \"0x00\" --rxdata 0"
    local ret = sendCmdAndParse(param)
    -- Log.LogInfo(ret)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    
    return "done"
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000099_1.0
-- USBC.eraseFW( paraTab )
-- Function to erase ace fw
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : Roy Fang
-- Modification Date             : 10/22/2021    
-- Current_Version               : 1.1
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : DFU
-- Input Arguments               : table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function USBC.eraseFW( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Log.LogInfo('[Run Action]: ' .. tostring(paraTab.TestName) .. '-' .. tostring(paraTab.TestActions)..'-'..tostring(paraTab.InputValues)..' Retries: '..tostring(paraTab.Retries))

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 20000
    local read_chipid = fixture.fixture_command("ace_programmer_id","",timeout,slot_num)
    local chipid = string.match(string.upper(read_chipid),"ID:(%w+,%w+,%w+)")
    local spi_chipname = string.match(read_chipid,"chip_name:(%w+)")
    Log.LogInfo('ACE_ChipName '..chipid)
    if(chipid=="0X13,0XEF,0X4014") then
        ACE_ChipName = "w25q128"

    elseif(chipid=="0X14,0XC2,0X2814")then
        ACE_ChipName = "mx25v16"

    elseif(chipid=="0X13,0XC8,0X6014")then
        ACE_ChipName = "gd25xxx"   --at25xxx   
    else
        ACE_ChipName="w25q128"
    end

    local erase_cmd = "ace_programmer_erase"
    local response = fixture.fixture_command(erase_cmd,ACE_ChipName,timeout,slot_num)
    Log.LogInfo(erase_cmd.." "..response)
    local result = false
    if string.find(response,"erasing target successfully") then
        result = true
    end
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

    if paraTab.AdditionalParameters.attribute then
        DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, spi_chipname ) )
    end

    if b_result == false then
        error('ace_programmer_erase Error')
    end

    return ACE_ChipName

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000100_1.0
-- USBC.programFW( paraTab )
-- Function to program ace fw
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : Roy Fang
-- Modification Date             : 10/22/2021     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : DFU
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function USBC.programFW( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Log.LogInfo('[Run Action]: ' .. tostring(paraTab.TestName) .. '-' .. tostring(paraTab.TestActions)..'-'..tostring(paraTab.InputValues)..' Retries: '..tostring(paraTab.Retries))

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    Log.LogInfo('programFW ACE_ChipName '..ACE_ChipName)

    local timeout = 20000
    local cmd = "ace_programmer_only"
    Log.LogInfo(cmd.." "..ACE_ChipName)

    local response = fixture.fixture_command(cmd,ACE_ChipName,timeout,slot_num)
    Log.LogInfo(cmd.." "..response)
    local result = false
    if string.find(response,"program ok") then
        result = true
    end
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

    if result == false then
        error('ace_programmer_only Error')
    end


end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000101_1.0
-- USBC.checkUUTACEFW( paraTab )
-- Function to check uut fw for md5 and sha1
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : Roy Fang
-- Modification Date             : 10/22/2021     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function USBC.checkUUTACEFW( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    
    Log.LogInfo('[Run Action]: ' .. tostring(paraTab.TestName) .. '-' .. tostring(paraTab.TestActions)..'-'..tostring(paraTab.InputValues)..' Retries: '..tostring(paraTab.Retries))

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    local Local_FW="/tmp/FixtureLog_CH"..tostring(slot_num).."/ACE_FW.readback"
    RunShellCommand.run("rm "..Local_FW)

    local timeout = 20000
    local addr = "0x00000000"
    local ACE_FW_Name = "/mix/addon/dut_firmware/ch"..tostring(slot_num).."/ACE_FW.readback"
    local cmd = "ace_program_readverify" 
    local ret = fixture.fixture_command(cmd,ACE_ChipName,timeout,slot_num)
    Log.LogInfo(ret)

    fixture.get_and_write_file(ACE_FW_Name,Local_FW,slot_num,timeout)
    local MD5_COMPUTED_XV = string.match(RunShellCommand.run("/sbin/md5 "..Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(RunShellCommand.run("/usr/bin/openssl sha1 "..Local_FW).output, "SHA1.-=%s(%w+)")

    local result = false
    if MD5_HARD==MD5_COMPUTED_XV and SHA1_HARD==SHA1_COMPUTED_XV then
        result = true
    end
    Log.LogInfo('MD5_COMPUTED_XV:'..MD5_COMPUTED_XV..' SHA1_COMPUTED_XV:'..SHA1_COMPUTED_XV)

    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

    if result == false then
        error('checkUUTACEFW Error')
    end

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Microtest_000062_1.0
-- USBC.checkLocalACEFW(paraTab)
-- Function to compare ACE fw md5 and hash code from Mac mini
-- Created By                    : Jayson Ye
-- Initial Creation Date         : 11/01/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Microtest
-- Primary Usage                 : DFU
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function USBC.checkLocalACEFW(paraTab)
    local testname = paraTab.Technology
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local local_fw_path ="/Users/gdlocal/Library/Atlas2/supportFiles/customer/ACE_FW/bin"
    local local_fw_fullpath=tostring(local_fw_path.."/"..ACE_BIN_FILE_NAME)
    Log.LogInfo('$$$$ local_fw_fullpath: '..local_fw_fullpath)
    local MD5_COMPUTED_MM = string.match(comFunc.runShellCmd("/sbin/md5 "..local_fw_fullpath).output, "MD5.-=%s(%w+)")
    Log.LogInfo('$$$$ MD5_COMPUTED_MM: '..MD5_COMPUTED_MM)
    local SHA1_COMPUTED_MM = string.match(comFunc.runShellCmd("/usr/bin/openssl sha1 "..local_fw_fullpath).output, "SHA1.-=%s(%w+)")
    Log.LogInfo('$$$$ openssl_COMPUTED_MM: '..SHA1_COMPUTED_MM)
    local result = false
    if MD5_HARD==MD5_COMPUTED_MM and SHA1_HARD==SHA1_COMPUTED_MM then
        result = true
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Microtest_000063_1.0
-- USBC.checkXavierACEFW(paraTab)
-- Function to compare ACE fw md5 and hash code from Xavier
-- Created By                    : Jayson Ye
-- Initial Creation Date         : 11/01/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Microtest
-- Primary Usage                 : DFU
-- Input Arguments               : table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function USBC.checkXavierACEFW(paraTab)
    local testname = paraTab.Technology
    local subtestname = paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local slot_num = tonumber(Device.identifier:sub(-1))
    local Save_path="/tmp/FixtureLog_CH"..tostring(slot_num)
    local Local_FW = Save_path.."/"..ACE_BIN_FILE_NAME
    comFunc.runShellCmd("mkdir "..Save_path)
    comFunc.runShellCmd("rm "..Local_FW)
    Log.LogInfo(">runShellCmd>===")

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 5000
    local ACE_FW_Name = "/mix/addon/dut_firmware/ch"..tostring(slot_num).."/"..ACE_BIN_FILE_NAME
    local ret = fixture.get_and_write_file(ACE_FW_Name,Local_FW,slot_num,timeout)
    local MD5_COMPUTED_XV = string.match(comFunc.runShellCmd("/sbin/md5 "..Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(comFunc.runShellCmd("/usr/bin/openssl sha1 "..Local_FW).output, "SHA1.-=%s(%w+)")
   
    local result = false
    if MD5_HARD==MD5_COMPUTED_XV and SHA1_HARD==SHA1_COMPUTED_XV then
        result = true
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
end

return USBC


