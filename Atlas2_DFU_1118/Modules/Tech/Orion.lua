local Orion = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local flow_log = require("Tech/WriteLog")

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000051_1.0
-- Orion.repeatCmd(cmd)
-- Function to send diags command, and check reponse has error or not, if diags reponse has error, will resend 
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : string
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function Orion.repeatCmd(cmd)
    local ret = ""
    for i = 1, 5, 1 do
        ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { record = "NO", tick = "no" } })
        if not (string.find(ret, "Error")) then
            break
        end
    end
    flow_log.writeFlowLog(ret)
    return ret
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000052_1.0
-- Orion.orionTest( param )
-- Function to read the current result from (i2c -d 2 0x13 0xA5 1 && i2c -d 2 0x13 0xA4 1)*1.173mV
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
function Orion.orionTest(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local index = tostring(param.AdditionalParameters.param1)
    local offset = tonumber(param.AdditionalParameters.param2)

    local value = -999
    if index == "ADC" then
        local _last_diags_response = Orion.repeatCmd("i2c -d 1 0x13 0xA5 1")
        local dut_response = string.match(_last_diags_response, "Data:%s*(0x%x*)")
        local adc_string = dutCmd.hexToBinary(dut_response, 0, 1)
        _last_diags_response = Orion.repeatCmd("i2c -d 1 0x13 0xA4 1")
        dut_response = string.match(_last_diags_response, "Data:%s*(0x%x*)")
        adc_string = adc_string .. string.format("%08d", dutCmd.hexToBinary(dut_response))
        local adc_num = tonumber(adc_string, 2)
        value = adc_num * offset

    elseif index == "DCR" then


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

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000053_1.0
-- Orion.sendOrionCmd( param )
-- Function to send orion command 
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
function Orion.sendOrionCmd(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local cmd = param.Commands
    local commands = cmd .. ";"

    for command in string.gmatch(commands, "(.-);") do
        Orion.repeatCmd(command)
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000054_1.0
-- Orion.bellatrixHWReset( param )
-- Function to send bellatrix hw reset command 
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
function Orion.bellatrixHWReset(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    os.execute('sleep 0.01')
    dutCmd.sendCmd({ Commands = "socgpio --pin 453 --output 0", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
    os.execute('sleep 0.05')
    dutCmd.sendCmd({ Commands = "socgpio --pin 453 --output 1", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
    os.execute('sleep 0.05')
    Orion.repeatCmd("i2c -v 1 0x13 0x00 0x80")
    os.execute('sleep 0.05')
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000055_1.0
-- Orion.calculateOrionDCR( param )
-- Function to calculate orion input mode DCR=(PPVBUS_ORION_CONN-PPVBUS_PROT)/USB_CURRENT_BIG
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
function Orion.calculateOrionDCR(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(inputDict))
    local param1 = param.AdditionalParameters.param1 or ""
    local value = 0
    if param1 == "input" then

        local PPVBUS_ORION_CONN = -999
        if inputDict.PPVBUS_ORION_CONN ~= nil then
            PPVBUS_ORION_CONN = inputDict.PPVBUS_ORION_CONN
        end

        local PPVBUS_PROT = -999
        if inputDict.PPVBUS_PROT ~= nil then
            PPVBUS_PROT = inputDict.PPVBUS_PROT
        end

        local USB_CURRENT_BIG = -999
        if inputDict.USB_CURRENT_BIG ~= nil then
            USB_CURRENT_BIG = inputDict.USB_CURRENT_BIG
        end

        value = (tonumber(PPVBUS_ORION_CONN) - tonumber(PPVBUS_PROT)) / tonumber(USB_CURRENT_BIG)

    elseif param1 == "output" then

        local inputDict = param.InputDict
        local PP5V2_BELLATRIX2_BOOST_VOUT = -999
        if inputDict.PP5V2_BELLATRIX2_BOOST_VOUT ~= nil then
            PP5V2_BELLATRIX2_BOOST_VOUT = inputDict.PP5V2_BELLATRIX2_BOOST_VOUT
        end

        local PPVBUS_ORION_CONN = -998
        if inputDict.PPVBUS_ORION_CONN ~= nil then
            PPVBUS_ORION_CONN = inputDict.PPVBUS_ORION_CONN
        end

        local ELOAD_CURRENT_SENSE1 = -997
        if inputDict.ELOAD_CURRENT_SENSE1 ~= nil then
            ELOAD_CURRENT_SENSE1 = inputDict.ELOAD_CURRENT_SENSE1
        end

        value = (tonumber(PP5V2_BELLATRIX2_BOOST_VOUT) - tonumber(PPVBUS_ORION_CONN)) / tonumber(ELOAD_CURRENT_SENSE1)

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
-- Unique Function ID            :  Suncode_F000056_1.0
-- Orion.readEloadCurrentCV( param )
-- Function to measure cv_load current
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
function Orion.readEloadCurrentCV(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local netname = param.AdditionalParameters.netname

    local vol = 3600
    if param.Commands then
        vol = tonumber(param.Commands)
    end

    local value = fixture.read_eload_cv_current(netname, vol, slot_num)

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
-- Unique Function ID            :  Suncode_F000057_1.0
-- Orion.bellatrixResetLoop( param )
-- Function to Internal bypass switch current limit 2000mA
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
function Orion.bellatrixResetLoop(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 5000

    local result = false

    for i = 1, 5 do
        dutCmd.sendCmdAndParse({ Commands = "i2c -v 1 0x13 0x00 0x91", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
        dutCmd.sendCmdAndParse({ Commands = "socgpio --pin 139 --output 0", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
        os.execute("sleep 0.01")
        dutCmd.sendCmdAndParse({ Commands = "socgpio --pin 453 --output 0", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
        os.execute("sleep 0.01")
        dutCmd.sendCmdAndParse({ Commands = "socgpio --pin 453 --output 1", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
        os.execute("sleep 0.01")
        Orion.repeatCmd("i2c -v 1 0x13 0x00 0x80")
        os.execute("sleep 0.5")
        dutCmd.sendCmdAndParse({ Commands = "socgpio --pin 139 --output 1", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
        local orion_pwr = tonumber(fixture.read_voltage("PPVBUS_ORION_CONN", "", slot_num))
        if tonumber(orion_pwr) > 4000 then
            result = true
            break
        end
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000058_1.0
-- Orion.eloadCurrentStep( param )
-- Function to increase eload step by step, when orion is OC, read eload current and orion OC current
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
function Orion.eloadCurrentStep(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1
    local value = -9999
    flow_log.writeFlowLog(comFunc.dump(param.InputDict))

    local BellaTrix_Status = ""
    local ORION_V = -1
    local Eload_Actual = -998

    if param1 == "Eload_Actual" then

        local inputDict = param.InputDict
        value = inputDict.Eload_Actual

    elseif param1 == "BellaTrix_Status" then
        local inputDict = param.InputDict
        value = inputDict.BellaTrix_Status

    elseif param1 == "ORION_V" then
        local inputDict = param.InputDict
        value = inputDict.ORION_V

    elseif param.AdditionalParameters.param2 ~= nil then

        local param2 = param.AdditionalParameters.param2

        local fixture = Device.getPlugin("FixturePlugin")
        local slot_num = tonumber(Device.identifier:sub(-1))
        local timeout = 5000

        local netname = param.AdditionalParameters.netname

        local target = tonumber(param1)
        local Eload_Current_Step = 0
        local Eload_Current = 0;

        local OC_flag = 0
        local steptable = comFunc.splitString(param2, "-")
        local start = tonumber(steptable[1]) * 1000
        local stop = tonumber(steptable[2]) * 1000
        local step = tonumber(steptable[3]) * 1000
        if start > stop then
            step = tonumber("-" .. tostring(steptable[3]))
        end

        local fixture = Device.getPlugin("FixturePlugin")
        local slot_num = tonumber(Device.identifier:sub(-1))

        local result = false
        for i = start, stop, step do

            fixture.eload_set(1, "cc", tonumber(i), slot_num)
            os.execute("sleep 0.01")
            Eload_Current = Eload_Current_Step
            Eload_Current_Step = fixture.read_eload_current(netname, slot_num)
            flow_log.writeFlowLog(Eload_Current_Step)
            local OC_flag = 0
            local Orion_Voltage = tonumber(fixture.read_voltage("PPVBUS_ORION_CONN", "", slot_num))

            if target then
                --Orion OC
                if Eload_Current_Step < target * 1000 or Orion_Voltage < 1000 then
                    --171110 IL5 as Alan

                    local _last_diags_response = Orion.repeatCmd("i2c -d 1 0x13 0x12 1");
                    BellaTrix_Status = string.match(_last_diags_response, "Data:%s*(0x%w+)")

                    ORION_V = tonumber(fixture.read_voltage("PPVBUS_ORION_CONN", "", slot_num)) * 1000
                    OC_flag = OC_flag + 1
                end
            else
                --Accessory OC
                local _last_diags_response = Orion.repeatCmd("pmurw -r 0x2E00")
                if string.match(_last_diags_response, "Read%s*1%s*bytes%:%s*(0x%w+)") == "0x01" then
                    OC_flag = OC_flag + 1
                end
            end

            if OC_flag > 0 then
                if i == start then
                    --vt.setVar("Eload_Actual", -9999999)
                    Eload_Actual = -9999999
                    value = i
                    result = true
                    break
                else

                    Eload_Actual = Eload_Current
                    Orion.repeatCmd("i2c -d 1 0x13 0x1A 1");
                    fixture.fixture_command("eload_set_1_cc_0", 10000, slot_num)
                    value = i - step
                    result = true
                    break
                end
            end

        end
        if result == false then

            Eload_Actual = 9999999
            value = stop * 1000
        end


    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)

    return ORION_V, Eload_Actual, BellaTrix_Status

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000059_1.0
-- Orion.calculateOrionefficiency( param )
-- Function to calculate efficiency=100*(OAB_ELOAD)*(VOUT_Boost) / (((Batt_Curr_Boost)-(Batt_Curr_INIT)) * (VIN_Boost))
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
function Orion.calculateOrionefficiency(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(param.InputDict))
    local OAB_ELOAD = -996
    if inputDict.OAB_ELOAD ~= nil then
        OAB_ELOAD = inputDict.OAB_ELOAD
    end

    local VOUT_Boost = -997
    if inputDict.VOUT_Boost ~= nil then
        VOUT_Boost = inputDict.VOUT_Boost
    end

    local Batt_Curr_Boost = -998
    if inputDict.Batt_Curr_Boost ~= nil then
        Batt_Curr_Boost = inputDict.Batt_Curr_Boost
    end

    Batt_Curr_INIT = -999
    if inputDict.Batt_Curr_INIT ~= nil then
        Batt_Curr_INIT = inputDict.Batt_Curr_INIT
    end

    VIN_Boost = -995
    if inputDict.VIN_Boost ~= nil then
        VIN_Boost = inputDict.VIN_Boost
    end

    local value = 100 * tonumber(OAB_ELOAD) * tonumber(VOUT_Boost) / ((tonumber(Batt_Curr_Boost) - tonumber(Batt_Curr_INIT)) * tonumber(VIN_Boost))

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000060_1.0
-- Orion.sendOrionHighSpeed( param )
-- Function to set orion 1M speed, then send ABCD, get reponse has "Test PASSed".
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
function Orion.sendOrionHighSpeed(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local dut = nil
    if dutPluginName then
        dut = Device.getPlugin(dutPluginName)
    else
        dut = Device.getPlugin("dut")
    end

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local b_result = false
    local command = param.Commands

    local _last_diags_response = ""
    if string.find(command, "uartpassthrough") then
        dut.write(command)
        b_result = true

    elseif string.find(command, "ABCD") then

        local default_delimiter = "] :-)"
        dut.setDelimiter("")
        _last_diags_response = dutCmd.dutRead({ Timeout = 1, isNotTop = true })
        fixture.fixture_command("uart_set.write(ABCD)", 5000, slot_num)
        _last_diags_response = _last_diags_response .. dutCmd.dutRead({ Timeout = 1, isNotTop = true })
        if not string.find(_last_diags_response, "Test PASSed") then
            for i = 1, 15 do

                fixture.fixture_command("uart_set.write(ABCD)", 5000, slot_num)
                _last_diags_response = _last_diags_response .. dutCmd.dutRead({ Timeout = 1, isNotTop = true })

                if string.find(_last_diags_response, "Test PASSed") then
                    break
                end
            end

        end

        fixture.fixture_command("uart_set.write(EXIT)", 5000, slot_num)
        _last_diags_response = _last_diags_response .. dutCmd.dutRead({ Timeout = 1, isNotTop = true })
        if string.find(_last_diags_response, "ABCD") then
            b_result = true

        else
            b_result = false

        end
        dut.setDelimiter(default_delimiter)

    end
    flow_log.writeFlowLog(_last_diags_response)
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
    return _last_diags_response

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000061_1.0
-- Orion.checkOrionHighSpeed( param )
-- Function to parse response in 1M band rate
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
function Orion.checkOrionHighSpeed(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local _last_diags_response = param.Input
    local pattern = param.AdditionalParameters.pattern

    local b_result = false
    if string.find(_last_diags_response, pattern) then
        b_result = true
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, b_result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000062_1.0
-- Orion.switchHighSpeedToLowSpeed( param )
-- Function to send command to change 1M band rate to 115200 band rate
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
function Orion.switchHighSpeedToLowSpeed(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local command = param.Commands
    fixture.fixture_command("uart_set.write(\r\n)", 5000, slot_num)
    os.execute("sleep 0.1")
    fixture.fixture_command("uart_set.write(" .. command .. "\r\n)", 5000, slot_num)
    os.execute("sleep 0.1")
    fixture.fixture_command("uart_set.write(\r\n)", 5000, slot_num)
    os.execute("sleep 0.1")
    flow_log.writeFlowLog(command)

    local dut = nil
    if dutPluginName then
        dut = Device.getPlugin(dutPluginName)
    else
        dut = Device.getPlugin("dut")
    end
    dut.write("\r\n")
    dutCmd.dutRead({ Timeout = 1, isNotTop = true })
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, "true")
end

return Orion
