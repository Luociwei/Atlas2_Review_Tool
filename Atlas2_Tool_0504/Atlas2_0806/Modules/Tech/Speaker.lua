local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local powersupply = require("Tech/PowerSupply")
local flow_log = require("Tech/WriteLog")

local batt_mon = nil
local thld = nil

local function BitAnd(num1,num2)
    local tmp1 = num1
    local tmp2 = num2
    local str = ""
    repeat
        local s1 = tmp1 % 2
        local s2 = tmp2 % 2
        if s1 == s2 then
            if s1 == 1 then
                str = "1"..str
            else
                str = "0"..str
            end
        else
            str = "0"..str
        end
        tmp1 = math.modf(tmp1/2)
        tmp2 = math.modf(tmp2/2)
    until(tmp1 == 0 and tmp2 == 0)
    return tonumber(str,2)
end

local function dec2bin(v_dec)
    local bin_str = ""
    if v_dec==0 then return 0 end
    while v_dec > 0 do
        local rr = math.modf(v_dec%2)
        bin_str = rr .. bin_str
        v_dec = (v_dec-rr)/2
    end
    return bin_str
end

local function hex2bin(value,bit_start,bit_end) --[1]value [2]bit_start [3]bit_end
    value = tonumber(value)
    Log.LogInfo('$*** hex2bin 0: '..tostring(value))
    value = dec2bin(value)
    Log.LogInfo('$*** hex2bin 1: '..tostring(value))
    --value = string.format("%08d",value)
    if bit_start then
        bit_start = string.len(value) - bit_start
        if not(bit_end) then
            bit_end = bit_start
            return string.sub(value,bit_end,bit_start)
        end
        bit_end = string.len(value) - bit_end
        return string.sub(value,bit_end,bit_start)
    end
    return value
end

local function list_cmd_send(cmd)

    local status=""
    local commands = cmd..";"
    local response = ""
    for command in string.gmatch(commands,"(.-);") do

        local temp_buffer = dutCmd.dut_writeRead({Commands=command,AdditionalParameters={return_val="raw",record="NO"}})
        response = response..temp_buffer
        if string.find(cmd,"wait")then
            -- do nothing
        else

            if string.find(string.upper(temp_buffer),"OK")==nil then
                if string.find(string.upper(temp_buffer),"PASSED")==nil then
                    if string.find(string.upper(temp_buffer),"PASS")==nil then
                        status="ERROR"
                    end
                end
            end

        end

    end
    flow_log.writeFlowLog(response)
    return status
end


function func.boost_maintenance( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    
    local index  = tostring(param.AdditionalParameters.param1)
    local offset = tonumber(param.AdditionalParameters.param2)

    local cmd = param.Commands
    local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={record="NO"}})
    flow_log.writeFlowLog(ret)
    local pattern = param.AdditionalParameters.pattern

    ret = string.match(ret,pattern)

    local value = BitAnd(tonumber(ret),tonumber(0x200))
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

function func.parse_maintenance( param )

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local _last_diags_response = param.Input

    local pattern = param.AdditionalParameters.pattern
    local ret = string.match(_last_diags_response,pattern)

    local value = BitAnd(tonumber(ret),tonumber(0x200))

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



function func.run_cmd( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands

    local last_result=""
    local ret_all = ""

    local commands = cmd..";"
    for command in string.gmatch(commands,"(.-);") do

        local temp_buffer = dutCmd.dut_writeRead({Commands=command,AdditionalParameters={return_val="raw",record="NO"}})
        if string.find(cmd,"wait")then
            -- do nothing
        else

            if string.find(string.upper(temp_buffer),"OK")==nil then

                if string.find(string.upper(temp_buffer),"PASSED")==nil then

                    if string.find(string.upper(temp_buffer),"PASS")==nil then

                        last_result="--FAIL--"

                    end

                end
            end
        end
        ret_all = ret_all..temp_buffer

    end
    flow_log.writeFlowLog(ret_all)
    local result = false
    if last_result=="" then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
    return ret_all

end


function func.amp_meas_bbtl( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local _last_diags_response = param.Input

    local keyName = param.AdditionalParameters.param1
    local pattern = param.AdditionalParameters.pattern
    local v = string.match(_last_diags_response,pattern)

    local value = v
    if string.find(keyName,"v_rms_l") then
        value = 15.4*tonumber(v)/(2^15-1)     

    elseif string.find(keyName,"v_rms") then
        value = 15.4*tonumber(v)/(2^15-1)   

    elseif string.find(keyName,"i_rms_l") then
        value= 3*tonumber(v)/(2^15-1)*1000

    elseif string.find(keyName,"i_rms") then
        value =  3*tonumber(v)/(2^15-1)*1000
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



function func.amp_meas_pp( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local keyName = param.AdditionalParameters.param1
    local _last_diags_response = param.Input

    local pattern_dp = param.AdditionalParameters.pattern_dp
    local pattern_dn = param.AdditionalParameters.pattern_dn

    local value = 0
    if string.find(keyName,"vmon_pp") then 
        local vmon_dp = string.match(_last_diags_response,pattern_dp)
        local vmon_dn = string.match(_last_diags_response,pattern_dn)
        local DP_value = -1
        local DN_value = -1

        if tonumber(vmon_dp) then
            DP_value = tonumber(vmon_dp)
        end

        if tonumber(vmon_dn) then
            DN_value = tonumber(vmon_dn)
        end

    
        value = 15.4*(10^(DP_value/20)+10^(DN_value/20))

    elseif string.find(keyName,"imon_pp") then
        local imon_dp = string.match(_last_diags_response,pattern_dp)
        local imon_dn = string.match(_last_diags_response,pattern_dn)
        local DP_value = -1
        local DN_value = -1

        if tonumber(imon_dp) then
            DP_value = tonumber(imon_dp)
        end

        if tonumber(imon_dn) then
            DN_value = tonumber(imon_dn)
        end

        value = 3*(10^(DP_value/20)+10^(DN_value/20))*1000

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


function func.cal_rdc_l( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict
    local keyName = param.AdditionalParameters.param1
    local value = 0

    if keyName == "v_rms_l_cal" then
        value =  inputDict.v_rms_l 

    elseif keyName == "i_rms_l_cal" then   
        value =  inputDict.i_rms_l 

    elseif keyName == "dcr_cal" then
        local v_rms_l_cal = inputDict.v_rms_l
        local i_rms_l_cal = inputDict.i_rms_l

        value = tonumber(v_rms_l_cal)/tonumber(i_rms_l_cal)   
        value = value*1000  -- need check  
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


function func.vpbr_init( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd_return_result=""
    local init = param.AdditionalParameters.param1
    if init == "vpbr_init" then
        local cmd = param.Commands
        cmd_return_result=list_cmd_send(cmd)
        powersupply.set_power({AdditionalParameters={powertype="batt",start="3.5",stop="3.38",step="0.2"}})
        os.execute("sleep 0.005")

    elseif init == "vpbr_init_1" then
        local cmd = param.Commands
        cmd_return_result=list_cmd_send(cmd)
    elseif init == "vpbr_init_2" then
        local cmd = param.Commands
        cmd_return_result=list_cmd_send(cmd)
    elseif init == "stop" then
        local cmd = param.Commands
        cmd_return_result=list_cmd_send(cmd)
        powersupply.set_power({AdditionalParameters={powertype="batt",start="3.5",stop="4.3",step="0.2"}})

    elseif init == "reset" then
        local cmd = param.Commands
        cmd_return_result=list_cmd_send(cmd)    
    elseif init == "unmask" then
        local cmd = param.Commands
        cmd_return_result=list_cmd_send(cmd) 

    elseif init == "GPIO_SPKAMP_TO_SOC_IRQ_L" then
        local cmd = param.Commands
        local pattern = param.AdditionalParameters.pattern
        cmd_return_result = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={pattern=pattern,record="NO"}})

    end

    local result = true
    if(cmd_return_result=="ERROR")then
        result = false
    end

    if param.AdditionalParameters.parametric ~=nil then
        local limitTab = param.limit
        local limit = nil
        if limitTab then
            limit = limitTab[param.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)

    else
        if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
end



function func.vpbr_test_loop( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1

    local ret =nil
    local response = nil
    local irq_status = nil
    local reg_flag = nil

    local pin = "39"
    local result = false

    if param1 == "loop" then
        for i=72,80,1 do

            irq_status = dutCmd.dut_writeRead({Commands="socgpio --port 0 --pin "..pin.." --get",AdditionalParameters={pattern="SoC%s*GPIO%[0,%d*%]%s*=%s*(%d*)",record="NO"}})
            Log.LogInfo('$*** >vpbr_test_loop 1: '..tostring(irq_status))
            irq_status = tonumber(irq_status)

            reg_flag = dutCmd.dut_writeRead({Commands="audioreg -b boost-master -r -a 0x2818",AdditionalParameters={pattern="0x2818%s*=%s*(0x%x*)",escape="yes",record="NO"}})
            reg_flag = hex2bin(reg_flag,12,nil)
            Log.LogInfo('$*** >vpbr_test_loop 2: '..tostring(reg_flag))
            if reg_flag == nil then
                reg_flag = -1
            end

            response = dutCmd.dut_writeRead({Commands="audioparam -b boost-master -g",AdditionalParameters={return_val="raw",record="NO"}})
            --Log.LogInfo('$*** >vpbr_test_loop 3: '..tostring(response))
            batt_mon = string.match(response,"vbatt%-mon%s*=%s*(%d+.%d+)")

            if not (batt_mon)then 
                batt_mon=-1 
            end
            
            thld = string.match(response,"br%-l3%-thld%s*=%s*(%d+.%d+)")
            if not (thld)then 
                thld=-1 
            end

            if irq_status==0 and reg_flag==1 then
                result = true
                break
            else
                if i ==81 then
                    ret = "ALC_VTH out of range"
                    result = false
                else
                    ret = "0x"..string.lower(string.format("%02X",tonumber(i))).."50604"
                    local command = "audioreg -b boost-master -w -a 0x4804 -d "..ret
                    dutCmd.dut_writeRead({Commands=command,AdditionalParameters={return_val="raw",record="NO"}})
                    result = true

                end
           end
    
        end

    elseif param1 == "batt_mon" then
        ret = batt_mon
        batt_mon = nil

    elseif param1 == "thld" then
        ret = thld
        thld = nil
    end

    Log.LogInfo("-->>>vpbr_test_loop: "..tostring(ret))
    if param.AdditionalParameters.attribute ~= nil and result then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ret) )
    end

    if param.AdditionalParameters.parametric ~=nil then

        local limitTab = param.limit
        local limit = nil
        if limitTab then
            limit = limitTab[param.AdditionalParameters.subsubtestname]
        end
        Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
    else
        if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
            Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        end
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,ret)
end



function func.unmask_amp( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local index = param.AdditionalParameters.param1
    local unmask_amp_list = {
    "spk_fh_l_w",
    "spk_cn_l_w",
    }
    if index == "ALL" then
        for key,cmd in ipairs(unmask_amp_list) do
            local cmd = "audioreg -b "..cmd.." -w -a 0x2854 -d 0x1FFF7EFE"
            local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})
            flow_log.writeFlowLog(ret)
        end
    else
        local cmd = "audioreg -b "..index.." -w -a 0x2854 -d 0x1FFF7EFE"
        local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})
        flow_log.writeFlowLog(ret)
    end

    Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
end

function func.mute( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local index = param.AdditionalParameters.param1
    local cmd = "audioreg -b "..index.." -w -a 0x5C04 -d 0x1"
    local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})
    flow_log.writeFlowLog(ret)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
end

function func.clear( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = param.Commands
    local bit = param.AdditionalParameters.bit
    local pattern1 = param.AdditionalParameters.pattern
   
    local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",escape="yes",record="NO"}})
    flow_log.writeFlowLog(ret)
    ret = string.match(ret,pattern1)
    ret = hex2bin(ret,tonumber(bit),nil)

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,ret)
end


return func


