local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local flow_log = require("Tech/WriteLog")

local otp_need_program =false
local ret_crc = ""
local otp_name = ""

local usb_flag=nil
local ret_result =nil
local re_Link_state =nil
local ret_Speed = nil
local ret_Link_ERRS = nil
local Link_ERRS = nil
local ReDriver_Number = nil


function func.getopt_words(start_bit, bit_length,file_name)  --Word0: Previous CRC "4c4b 603f"
    local OTP_PATH = "/Users/gdlocal/Library/Atlas2/supportFiles/customer/OTP_FW/"
    local result=""
    local path = OTP_PATH..file_name
    local readBinFile = Device.getPlugin("DockChannel")

    if not tonumber(start_bit) and not tonumber(bit_length) then return func.getBinFile() end
    if not tonumber(start_bit) then start_bit=0 end
    if not tonumber(bit_length) then bit_length=4 end
    result=readBinFile.getBinFileHex(path,tonumber(start_bit),tonumber(bit_length))
    return string.upper(result)

end


function func.fwdl_rease( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 10000
    local read_chipid = fixture.fixture_command("ace_programmer_id",timeout,slot_num)
    local chipid = string.match(string.upper(read_chipid),"ID:(%w+,%w+,%w+)")

    local ACE_ChipName = "w25q128"
    if(chipid=="0X13,0XEF,0X4014") then
        ACE_ChipName = "w25q128"

    elseif(chipid=="0X14,0XC2,0X2814")then
        ACE_ChipName = "mx25v16"

    elseif(chipid=="0X13,0XC8,0X6014")then
        ACE_ChipName = "gd25xxx"   --at25xxx   
    else
        ACE_ChipName="w25q128"
    end

    local cmd2 = "ace_programmer_erase_"..ACE_ChipName
    local response = fixture.fixture_command(cmd2,timeout,slot_num)
    flow_log.writeFlowLog(cmd2.." "..response)
    local result = false
    if string.find(response,"erasing target successfully") then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
    return ACE_ChipName

end

function func.fwdl_program( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 20000
    local cmd = "ace_programmer_only"
    local response = fixture.fixture_command(cmd,timeout,slot_num)
    flow_log.writeFlowLog(cmd.." "..response)
    local result = false
    if string.find(response,"program ok") then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
end


function func.check_acefw_vs_uut( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    
    local result = true
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
end


function func.read_gpio(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname or ""

    local ret = fixture.read_gpio_voltage(netname,slot_num)
    
    flow_log.writeFlowLog(ret)
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,ret)
end


function func.diagsParse( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local dut = Device.getPlugin("dut")
    local slot_num = tonumber(Device.identifier:sub(-1))
    
    if dut.isOpened() ~= 1 then
        --Log.LogInfo("$$$$ dut.open")
        dut.open(2)
    end


    local timeout = param.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 30
    end

    if param.AdditionalParameters.delimiter then
        dut.setDelimiter(param.AdditionalParameters.delimiter)
    else
        dut.setDelimiter("] :-)")
    end

    local cmd = param.Commands

    dut.write(cmd)
    local ret = dut.read(timeout)
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.pattern~= nil then

        local pattern = param.AdditionalParameters.pattern
        ret = string.match(ret,pattern)
    end

    if param.AdditionalParameters.pattern1~= nil then
        local pattern1 = param.AdditionalParameters.pattern1
        ret = string.gsub(ret,"\r","")
        ret = string.gsub(ret,"\n","")
        --Log.LogInfo('$*** func.diagsParse result: '..ret)
        ret = string.match(ret,pattern1)
    end

    if ret~=nil and ret~="" then
        if param.AdditionalParameters.attribute ~= nil and ret then
            DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ret) )
        end
    end

    local result = true
    local return_val = ret

    if param.AdditionalParameters.mode ~=nil then
        local mode = param.AdditionalParameters.mode

        if mode == "otp_check_crc_flag" then
            if ret == "41 50 50 20" or ret == "44 46 55 66" or ret =="42 4F 4F 54" then
                return_val = "Verify Ace2 operating state"
            else
                return_val = "-1"
                result = false
            end 
        else

            if tostring(ret) == "0" then
                return_val =  "dev_fuse_mode"
            elseif tostring(ret) == "1" then
                return_val =  "prod_fuse_mode"
            end

        end

    end

    if param.AdditionalParameters.parametric ~=nil then
        local limitTab = param.limit
        local limit = nil
        if limitTab then
            limit = limitTab[param.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
        flow_log.writeFlowLimitAndResult(param,ret)
    else
        if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
        flow_log.writeFlowLimitAndResult(param,result)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)

    return return_val

end




function func.powerSet( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL","OFF",slot_num)
    fixture.set_usb_voltage(0,"",slot_num)

    fixture.relay_switch("VDM_CC1","DISCONNECT",slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR","TO_PPVBUS_PROT",slot_num)
    os.execute("sleep 0.005")

    fixture.relay_switch("VBUS_OUTPUT_CTL","ON",slot_num)
    local ret = fixture.set_usb_voltage(14000,"0-14000-3000",slot_num)

    flow_log.writeFlowLog(ret)

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    os.execute("sleep 0.005")
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
end

function func.powerSetBack( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL","OFF",slot_num)
    fixture.relay_switch("VDM_CC1","DISCONNECT",slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR","TO_PP_EXT",slot_num)
    fixture.relay_switch("VDM_VBUS_TO_PPVBUS_USB_EMI","CONNECT",slot_num)
    fixture.relay_switch("VBUS_OUTPUT_CTL","ON",slot_num)
    fixture.relay_switch("VDM_CC1","TO_ACE_CC1",slot_num)
    

    local dut = Device.getPlugin("dut")
    local cmd = "ace --pick usbc --4cc SRDY --txdata \"0x00\" --rxdata 0"
    dut.write(cmd)
    local ret = dut.read(10)
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
end



function func.get_production_mode( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern

    local production_mode = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={pattern=pattern,record="NO"}})
    flow_log.writeFlowLog(production_mode)
    otp_name=""
    
    local result = ""
    local b_result = true
    if production_mode == "0" then
        otp_name="ACE2_J407_OTP_NONprod.bin"
        result = "dev_fuse_mode"
    elseif production_mode == "1" then
        otp_name="ACE2_J517_OTP_Prod.bin"
        result = "prod_fuse_mode"
    else
        otp_name=""
        result = "UnSet"
        b_result = false
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result==false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
    return result

end


function func.otp_write_set( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL","OFF",slot_num)

    fixture.set_usb_voltage(0,"",slot_num)
    fixture.relay_switch("VDM_CC1","DISCONNECT",slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR","TO_PPVBUS_PROT",slot_num)
    os.execute("sleep 0.01")

    fixture.relay_switch("VBUS_OUTPUT_CTL","ON",slot_num)
    fixture.set_usb_voltage(14000,"0-14000-3000",slot_num)
    os.execute("sleep 0.005")
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
end

function func.verify_operating_mode( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern

    local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={pattern=pattern,record="NO"}})
    flow_log.writeFlowLog(ret)
    local result = "Verify_False"
    local b_result = false
    if ret == "41 50 50 20" or ret == "44 46 55 66" or ret =="42 4F 4F 54" then
        result = "Verify_Ace2_operating_state"
        b_result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
    return result

end


function func.otp_crc_check( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    --Log.LogInfo(">>OTP_File_name=",otp_name)

    otp_need_program = false
    local pattern = "RxData%s*%(4.%).-%:.-0x0000%s*%:%s*(0x%w+%s+0x%w+%s+0x%w+%s+0x%w+)"
    local ret_crc = dutCmd.dut_writeRead({Commands="ace --4cc OTPr --txdata \"0x80\" --rxdata 4",AdditionalParameters={pattern=pattern,record="NO"}})

    local Final_CRC=func.getopt_words(tonumber(0x514),4,otp_name)
    Final_CRC=string.gsub(string.upper(Final_CRC),","," ")
    local PREVIOUS_CRC=func.getopt_words(tonumber(0x500),4,otp_name)
    PREVIOUS_CRC=string.gsub(string.upper(PREVIOUS_CRC),","," ")

    local result = ""
    local b_result = true
    if(otp_name=="ACE2_J407_OTP_NONprod.bin")then
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

    elseif(otp_name=="ACE2_J517_OTP_Prod.bin")then --Only follow prod-fuse,need charge the opt_name to prod-fuse bin file
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
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
    return result

end



function func.otp_program_customer_words( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local write_words=func.getopt_words(0,8,otp_name) ----0xaa,0x02,0x9f,0x66,0xb6,0x98,0x00,0x00
    write_words=string.gsub(string.upper(write_words),","," ")
    write_words=string.gsub(write_words,"0X","0x")

    local cmd = "ace --4cc OTPw --txdata \"0x01 "..write_words.."\" --rxdata 64"

    local ret_crc = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})
    flow_log.writeFlowLog(ret_crc)
    local b_result = true
    if string.find(ret,"Error") then
        otp_need_program=""
        b_result = false
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
end


function func.get_otp_program_flag( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
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
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
    return result

end


function func.customer_data_size( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local respone=func.getopt_words(tonumber(0x508),4,otp_name)
    flow_log.writeFlowLog(response)
    respone=string.gsub(string.upper(respone),"0X","")
    respone=tostring(string.gsub(string.upper(respone),",",""))

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
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
    return result
end



function func.key_size( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local respone = func.getopt_words(tonumber(0x510),1,otp_name) --0x40

    local result=""
    if respone == "0X00" then
        result = tonumber(respone)
    else
        result = "OTP_Key_SIZE_NOT_0"
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
    return result

end




function func.otp_write( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1

    local b_result = false
    local result= "FALSE"

    if param1 == "otp_key_Data_flag" then
        --key data flag
        local keydata_flag=func.getopt_words(tonumber(0x513),1,otp_name)--0x03
        local cmd = "ace --4cc OTPi --txdata \""..keydata_flag.."\" --rxdata 4"
        local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})
        flow_log.writeFlowLog(ret)
        if string.find(ret,"Error") then 
            b_result = false
        else
            b_result = true
            result= "TRUE"
        end
   
    elseif param1 == "key_Data_value" then
        local keydata_value=""
        local Key_Data_Size=func.getopt_words(tonumber(0x510),1,otp_name)
        if(string.upper(Key_Data_Size)=="0X20") then
            keydata_value=func.getopt_words(tonumber(get_keydata_start()),32,otp_name)    --0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8           
            for i=1,32 do
                keydata_value=keydata_value..",0x00"            
            end
        else
            keydata_value=func.getopt_words(tonumber(get_keydata_start()),64,otp_name) --0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8,0xea,0xbc,0xe0,0x4d,0xf1,0x4e,0x5d,0x81,0x22,0x4b,0x4f,0xc4,0x6a,0x25,0x4c,0x13,0x82,0x4e,0x8d,0x4c,0x2a,0xc7,0x1c,0xc8,0x5b,0x87,0xd1,0xa3,0x34,0x2d,0xc2,0x6a
        end
        keydata_value=string.gsub(string.upper(keydata_value),","," ")
        keydata_value=string.gsub(keydata_value,"0X","0x")
    
        --key data value 0x85 0x1a 0x04 0x06 0xed 0x4f 0x7f 0xa4 0x1c 0x39 0x4b 0x75 0x87 0xab 0x3c 0x74 0x85 0x22 0x27 0x47 0x38 0x55 0x37 0x97 0x50 0x24 0x93 0x97 0x5a 0xef 0xa6 0x6d 0x3b 0xad 0xea 0x44 0xc5 0x9f 0xd0 0x52 0x44 0x32 0xbf 0x4c 0x14 0x3a 0x16 0x29 0xa0 0x66 0xc3 0x92 0xca 0x2e 0xc8 0x06 0xcb 0x39 0x39 0xb0 0x92 0xb8 0xb7 0x61    63
        local cmd = "ace --4cc OTPd --txdata \""..keydata_value.."\" --rxdata 64"
        local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})
        flow_log.writeFlowLog(ret)
        if string.find(ret,"Error") then
            b_result = false
        else
            b_result = true
            result= "TRUE"
        end

   elseif param1 == "key_Data_crc" then
        -- local Keydata_crc=global.getWord6()
        local Keydata_crc=func.getopt_words(tonumber(0x518),4,otp_name)--0xC4 0xB0 0x76 0x1E
        Keydata_crc=string.gsub(string.upper(Keydata_crc),","," ")
        Keydata_crc=string.gsub(Keydata_crc,"0X","0x")
        --key data CRC  0xEC 0x06 0x28 0xFB
        local cmd = "ace --4cc OTPw --txdata \"0x04 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 "..Keydata_crc.."\" --rxdata 64"
        local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})
        flow_log.writeFlowLog(ret)
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
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
    return result
end


function func.otpcheck_read( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern
    

    local ret_crc = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={pattern=pattern,record="NO"}})
    flow_log.writeFlowLog(ret_crc)
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
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
    return ret_crc
    
end



function func.otp_write_setback( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.relay_switch("VBUS_OUTPUT_CTL","OFF",slot_num)
    fixture.relay_switch("VDM_CC1","DISCONNECT",slot_num)
    fixture.relay_switch("PPVBUS_USB_PWR","TO_PP_EXT",slot_num)
    fixture.relay_switch("VDM_VBUS_TO_PPVBUS_USB_EMI","CONNECT",slot_num)

    fixture.set_usb_voltage(5000,"",slot_num)
    fixture.relay_switch("VBUS_OUTPUT_CTL","ON",slot_num)
    os.execute("sleep 0.005")

    fixture.relay_switch("VDM_CC1","TO_ACE_CC1",slot_num)
    os.execute("sleep 0.5")

    local ret = dutCmd.dut_writeRead({Commands="ace --pick usbc --4cc SRDY --txdata \"0x00\" --rxdata 0",AdditionalParameters={return_val="raw",record="NO"}})
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
    return "done"
    
end


function func.run_cmd( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local ret = ""

    local commands = cmd..";"
    for command in string.gmatch(commands,"(.-);") do
        ret = ret..dutCmd.dut_writeRead({Commands=command,AdditionalParameters={return_val="raw",record="NO"}})
    end
    flow_log.writeFlowLog(ret)
    local result = false
    if #ret>0 then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
    return ret

end

function func.parse( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local match_pattern = param.AdditionalParameters.pattern
    local match_pattern_limit=param.AdditionalParameters.pattern_limit

    local Set_limit= param.AdditionalParameters.param2
    local _last_diags_response = param.Input

    local report_limit=string.match(_last_diags_response,match_pattern_limit)
    report_limit=string.gsub(report_limit,",","_")

    local value = -999
    local result = false
    if(report_limit~=Set_limit) then
        result = false
    else
        value = string.match(_last_diags_response,match_pattern)
        result = true
    end
    if value==nil then 
        value = -998
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,value)
end


function func.ramdisk_mount_file( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local file_name = param.AdditionalParameters.param1
    local slot_num = tonumber(Device.identifier:sub(-1))
    
    local host_root_path = param.AdditionalParameters.host_root_path
    local copy_list = param.AdditionalParameters.copy_list
    local toolPath =  param.AdditionalParameters.toolPath
    dutCmd.dut_writeRead({Commands='',AdditionalParameters={return_val="raw",record="NO",timeout=1}})
    local usbfs = Device.getPlugin("USBFS")
    local efi_dut = Device.getPlugin("dut")
    efi_dut.setDelimiter("] :-) ")
    usbfs.setHostToolPath(toolPath)
    usbfs.setDefaultTimeout(20)
    os.execute("sleep 1.5")
    local status, ret = xpcall(usbfs.copyToDevice, debug.traceback,efi_dut, host_root_path, copy_list)
    Log.LogInfo("$$$$ copyFileByUSBFS status " .. tostring(status) .. " ret " .. tostring(ret).."---end")
    flow_log.writeFlowLog(ret)
    local cmd3 = "dir nandfs:\\AppleInternal\\usbfs_folder"

    local _last_diags_response = dutCmd.dut_writeRead({Commands=cmd3,AdditionalParameters={return_val="raw",record="NO",mark="1",timeout=1}})
    flow_log.writeFlowLog(_last_diags_response)
    local b_result = false
    if string.find(_last_diags_response,tostring(file_name)) then

        local cmd1 = "rm -rf nandfs:\\AppleInternal\\usbfs_folder"
        local ret =dutCmd.dut_writeRead({Commands=cmd1,AdditionalParameters={return_val="raw",record="NO"}})
        b_result = true
        flow_log.writeFlowLog(ret)
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result== false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
end


function func.usb3_test_only( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 2000

    local param1 = param.AdditionalParameters.param1

    local value = -999

    if param1=="ACE_CC1" or param1=="ACE_CC2" then

        dutCmd.dut_writeRead({Commands="device -k usbphy -e select 0",AdditionalParameters={return_val="raw",record="NO"}})
        dutCmd.dut_writeRead({Commands="device -k UsbPhy -e disable usb",AdditionalParameters={return_val="raw",record="NO"}})

        os.execute("sleep 0.1")
        re_Link_state =nil
        ret_Speed = nil
        ret_Link_ERRS = nil
        Link_ERRS = nil
        ReDriver_Number = nil
        dutCmd.dut_writeRead({Commands="device -k usbphy -e select 0",AdditionalParameters={return_val="raw",record="NO"}})

        local _last_diags_response = dutCmd.dut_writeRead({Commands="device -k UsbPhy -e enable usb",AdditionalParameters={return_val="raw",record="NO"}})
        flow_log.writeFlowLog(_last_diags_response)
        if string.find(_last_diags_response,"Enabled Phy!") then 
            UsbInit = "Passed" 
        end

        if param1 == "ACE_CC1" then

        elseif param1 == "ACE_CC2" then

        end

        fixture.relay_switch("USB3_TO_5V","CONNECT",slot_num)
        os.execute("sleep 0.1")

        for i=1,7,1 do 

            local _last_diags_response = dutCmd.dut_writeRead({Commands="device -k UsbPhy -p",AdditionalParameters={return_val="raw",record="NO"}})

            ret_result = tostring(string.match(_last_diags_response,"status%:%s*%p(%a+)%p"))
            ret_Link_state = tostring(string.match(_last_diags_response,"state%:%s*%p(%a%d)%p"))
            ret_Link_ERRS = tostring(string.match(_last_diags_response,"link%s*errors%:%s*%p(%d+)%p"))
            ret_Speed = tostring(string.match(_last_diags_response,"speed%:%s*%p(%a+)%p"))
            ret_Link_ERRS = tonumber(ret_Link_ERRS) 

            if ret_result == "Connected" and ret_Link_state=="U0" and ret_Speed=="SS" and ret_Link_ERRS<=50 then
                ReDriver_Number=i
                dutCmd.dut_writeRead({Commands="device -k UsbPhy -e disable usb",AdditionalParameters={return_val="raw",record="NO"}})
                break               
            else

                ret_Link_ERRS = 99999

                dutCmd.dut_writeRead({Commands="device -k UsbPhy -e disable usb",AdditionalParameters={return_val="raw",record="NO"}})
                os.execute("sleep 0.1")

                if i<7 then

                    fixture.relay_switch("USB3_TO_5V","DISCONNECT",slot_num)
                    os.execute("sleep 0.1")
                    dutCmd.dut_writeRead({Commands="device -k usbphy -e select 0",AdditionalParameters={return_val="raw",record="NO"}})
                    dutCmd.dut_writeRead({Commands="device -k UsbPhy -e enable usb",AdditionalParameters={return_val="raw",record="NO"}})
                    fixture.relay_switch("USB3_TO_5V","CONNECT",slot_num)
                    os.execute("sleep 0.1")

                end
            end

            ReDriver_Number=i

        end

        if ret_result == "Connected" then
            value = 1
        else
            value = -1
        end
    end
     
    if param1=="Speed" then

        if ret_Speed == "SS" then

            value = 1
        else
            value = -1
        end
    end   

    if param1=="Link_state" then
        if ret_Link_state == "U0" then
            value = 1
        else
            value = -1
        end
    end

    if param1=="Link_error" then

        Link_ERRS= tonumber(ret_Link_ERRS)
        if Link_ERRS <=50 then
            value = 1
        else
            value = -1
        end
    end

    if param1=="ReDriver" then
        value = ReDriver_Number
    end


    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
        
        local lower = limit.lowerLimit
        local upper = limit.upperLimit

    end
    local recordResult = Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    if recordResult == false or recordResult == 0 then 
        error(testname.."-"..subtestname.."-"..subsubtestname.."usb3_test_only-fail")
        Log.LogInfo('sc--usb3_test_only-fail')
    else
        Log.LogInfo('sc--usb3_test_only-pass')
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,value)
end



function func.calculate( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1
    local inputDict = param.InputDict
    local value = -9999

    if param1 == "delta" then

        local VB_OUT_noEload = inputDict.VB_OUT_noEload
        local VB_OUT = inputDict.PP5V2_ACE_BOOST_OUT
        value = tonumber(VB_OUT_noEload)-tonumber(VB_OUT)

    elseif param1 == "efficiency" then

        local VBUS_Eload_Current = tonumber(inputDict.VBUS_Eload_Current)
        local VB_OUT = tonumber(inputDict.PP5V2_ACE_BOOST_OUT)
        local IBATT_VB_ON = tonumber(inputDict.IBATT_VB_ON)
        local IBATT_VB_OFF = tonumber(inputDict.IBATT_VB_OFF)
        local VB_IN = tonumber(inputDict.PPVCC_MAIN_VIN)

        value=100*(VBUS_Eload_Current*VB_OUT/((IBATT_VB_ON-IBATT_VB_OFF)*VB_IN))

    end



    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,value)
end



local vbus_result=nil
local cc1_result=nil
local cc2_result=nil

function func.readvbus( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local index = param.AdditionalParameters.param1

    local value = -999
    if index == "clear" then
        local a=nil
        local b=nil
        local c=nil
        local d=nil
        local e=nil
        local f=nil
        local vbus=nil
        local cc1=nil
        local cc2=nil

        vbus_result=nil
        cc1_result=nil
        cc2_result=nil
        
        
        dutCmd.dut_writeRead({Commands="ace --pick usbc",AdditionalParameters={return_val="raw",record="NO"}})
        local dut_response = dutCmd.dut_writeRead({Commands="ace -r 0x6a",AdditionalParameters={return_val="raw",record="NO"}})
        flow_log.writeFlowLog(dut_response)
        --Log.LogInfo('$*** readvbus: '..tostring(dut_response))
        
        a,b = string.match(dut_response,"0000000%:%s*%w+%s*%w+%s*%w+%s*%w+%s*(%w+)%s*(%w+)")
        c,d = string.match(dut_response,"0000010%:%s*%w+%s*%w+%s*%w+%s*%w+%s*%w+%s%w+%s*(%w+)%s*(%w+)%s*")
        e,f = string.match(dut_response,"0000010%:%s*%w+%s*%w+%s*%w+%s*%w+%s*%w+%s%w+%s*(%w+)%s*(%w+)%s*")

        --Log.LogInfo('$*** readvbus 2: '..tostring(a).." "..tostring(b).." "..tostring(c).." "..tostring(d).." "..tostring(e).." "..tostring(f))
        a = tostring(a)
        b = tostring(b)
        c = tostring(c)
        d = tostring(d)
        e = tostring(e)
        f = tostring(f)

        vbus="0x"..b..a
        --Log.LogInfo('$*** readvbus 3: '..tostring(vbus))
        vbus=tonumber(vbus)
        --Log.LogInfo('$*** readvbus 4: '..tostring(vbus))
        if vbus ~= nil then 
            vbus_result=vbus*30/1024    
            cc1="0x"..d..c
            cc1=tonumber(cc1)
            cc1_result=cc1*6/1024   
            cc2="0x"..f..e
            cc2=tonumber(cc2)
            cc2_result=cc2*6/1024

            value = 1
        else
            value = -999
        end

    end

    if index =="vbus" then
        value = vbus_result
    end

    if index =="cc1" then
        value = cc1_result
    end

    if index =="cc2" then
        value = cc2_result
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,value)
end



function func.dmm_error( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1
    local inputDict = param.InputDict

    local value = -9999

    if param1 == "VBAT_ERROR" then

        local PPBATT_VCC = tonumber(inputDict.PPBATT_VCC)
        local PMU_VBAT = tonumber(inputDict.PMU_VBAT)
        value = (PPBATT_VCC-PMU_VBAT)/PPBATT_VCC*100
        value = string.format("%.3f",value)

    elseif param1 == "IBAT_ERROR" then

        local BATT_CURRENT_BIG = tonumber(inputDict.BATT_CURRENT_BIG)
        local PMU_IBAT_OUT = tonumber(inputDict.PMU_IBAT_OUT)

        value = (tonumber(BATT_CURRENT_BIG)-tonumber(PMU_IBAT_OUT))/tonumber(BATT_CURRENT_BIG)*100
        value = string.format("%.3f",value)

    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,value)
    return value

end


return func


