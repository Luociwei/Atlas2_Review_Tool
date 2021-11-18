local Dmm = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

-- local vpp = -99999
-- local duty_cycle = -9999
-- local freq = -9999
-- local thd = -9999
--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000015_1.0
-- Dmm.readFrequence( param )
-- Function to read frequence
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table from Tech csv
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function Dmm.readFrequence(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local netname = param.AdditionalParameters.netname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local value = 0
    local door_v = 300
    if param.AdditionalParameters.door ~= nil then
        door_v = tonumber(param.AdditionalParameters.door)
    end

    if netname == "vpp" then
        value = tonumber(fixture.read_frequency_vpp(netname, door_v, slot_num))

    elseif netname == "duty_cycle" then
        value = tonumber(tonumber(fixture.read_frequency_duty(netname, door_v, slot_num)))

    else
        local measure_time = param.AdditionalParameters.measure_time or 1000
        local gear = param.AdditionalParameters.gear or ""
        value = tonumber(fixture.read_frequency(netname, door_v, tonumber(measure_time), gear, slot_num))
    end
    flow_log.writeFlowLog(fixture.get_fixture_log(slot_num))
    value = string.format("%.3f", value)

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    end
    flow_log.writeFlowLimitAndResult(param, value)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    return tonumber(value)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000016_1.0
-- Dmm.readVoltage( param )
-- Function to call func.dmm, read voltage value
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table from Tech csv
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function Dmm.readVoltage(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local mode = param.AdditionalParameters.mode or ""
    flow_log.writeFlowLog("[dmm_measure] : " .. netname .. "   [mode] : " .. tostring(mode))
    local value = fixture.read_voltage(netname, mode, slot_num)
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    if mode ~= nil and mode == "Hibernation" and value < 60 then
        fixture.relay_switch("BATT_MODE_CTL", "SMALL", slot_num)
        flow_log.writeFlowLog("[relay_switch] : BATT_MODE_CTL --> SMALL")
        os.execute("sleep 1")
        netname = "BATT_CURRENT_SMALL"
        value = fixture.read_voltage(netname, mode, slot_num)
        flow_log.writeFlowLog("[dmm_measure] : " .. netname .. "   [mode] : " .. tostring(mode))
        fixture.relay_switch("BATT_MODE_CTL", "BIG", slot_num)
        flow_log.writeFlowLog("[relay_switch] : BATT_MODE_CTL --> BIG")
    elseif mode ~= nil and mode == "Retry" then
        for i = 1, 5 do
            if limit ~= nil and (value < tonumber(limit.lowerLimit) or value > tonumber(limit.upperLimit)) then
                os.execute("sleep 0.2")
                value = fixture.read_voltage(netname, mode, slot_num)
                flow_log.writeFlowLog("[dmm_measure] : " .. netname .. "   [value] : " .. tostring(value))
            else
                break
            end
        end
    end

    local gain = param.AdditionalParameters.gain or 1
    value = tonumber(value) * tonumber(gain)

    if param.AdditionalParameters.abs ~= nil then
        value = math.abs(value)
    end

    local result = Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    if result == false and param.AdditionalParameters.fa_sof == "YES" then
        error('Dmm.readVoltage is Out of limit error')
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLog('gain: ' .. tostring(gain))
    flow_log.writeFlowLimitAndResult(param, value)
    return value

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000017_1.0
-- Dmm.connectVBUSFeedback( param )
-- Function to measure Vbus_fb and  PPVBUS_USB_EMI voltage, 
-- if Vbus_fb - PPVBUS_USB_EMI< 3mV, then switch realy PPVBUS_FB to CONNECT, otherwise fail
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table from Tech csv
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Dmm.connectVBUSFeedback(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local Vbus_meas = fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num)
    if param.AdditionalParameters.gain ~= nil then
        Vbus_meas = tonumber(Vbus_meas) * tonumber(param.AdditionalParameters.gain)
    end

    local Vbus_fb = param.AdditionalParameters.reference
    local diff = tonumber(Vbus_fb) - tonumber(Vbus_meas)

    if diff < 0 then
        diff = tonumber(Vbus_meas) - tonumber(Vbus_fb)
    end

    local result = false

    if diff <= 3000 then
        --3V
        fixture.relay_switch("PPVBUS_FB", "CONNECT", slot_num)
        result = true
    end

    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000020_1.0
-- Dmm.checkVBUS( param )
-- Function to measure VBUS_Orignal and  PPVBUS_USB_EMI voltage without Vbus_Feedback,
-- calculate diff= VBUS_Orignal-tonumber(Vbus_meas)/1000 and Vbus_Set=VBUS_Orignal+diff
-- if Vbus_Set>=20000mV/Vbus_Set>=6000mV, it will be fail,if the Vbus_meas is >=VBUS_Orignal-100mV and Vbus_meas is <=VBUS_Orignal+100mV,the functon will do nothing ,otherwise set vbus power to Vbus_Set, then measure PPVBUS_USB_EMI value, get PPVBUS_USB_EMI voltage
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 25/10/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Dmm.checkVBUSWithoutFB(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local VBUS_Orignal = tonumber(param.AdditionalParameters.reference)
    local result = true
    os.execute("sleep 0.05")
    local Vbus_meas = nil
    local Vbus_Set = VBUS_Orignal
    for i = 1, 40 do
        Vbus_meas = fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num)
        if param.AdditionalParameters.gain ~= nil then
            Vbus_meas = tonumber(Vbus_meas) * tonumber(param.AdditionalParameters.gain)
        end
        local diff = VBUS_Orignal - Vbus_meas
        if diff > 50 then
            diff = 50
        elseif diff < -50 then
            diff = -50
        end
        Vbus_Set = Vbus_Set + diff
        print(string.format("VBUS_Orignal: %s, Vbus_meas: %s, Vbus_Set: %s", VBUS_Orignal, Vbus_meas, Vbus_Set))
        flow_log.writeFlowLog(string.format("VBUS_Orignal: %s, Vbus_meas: %s, Vbus_Set: %s", VBUS_Orignal, Vbus_meas, Vbus_Set))
        if VBUS_Orignal == 5000 then

            if Vbus_Set >= 6000 or Vbus_Set<=-6000 then  -- 6V
                result = false
                break
            else
                fixture.set_usb_voltage(tonumber(Vbus_Set), "", slot_num)
                os.execute("sleep 0.05")
                Vbus_meas = fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num)
                if param.AdditionalParameters.gain ~= nil then
                    Vbus_meas = tonumber(Vbus_meas) * tonumber(param.AdditionalParameters.gain)
                end
                print(string.format("VBUS_Orignal: %s, Vbus_Set: %s, Vbus_meas: %s", VBUS_Orignal, Vbus_Set, Vbus_meas))
                flow_log.writeFlowLog(string.format("VBUS_Orignal: %s, Vbus_Set: %s, Vbus_meas: %s", VBUS_Orignal, Vbus_Set, Vbus_meas))
                if Vbus_meas <= 5010 and Vbus_meas >= 4995 then
                    break
                end
            end
        else
            if Vbus_Set>=20000 then --20V
                result = false
                break
            else
                fixture.set_usb_voltage(tonumber(Vbus_Set), "", slot_num)
                os.execute("sleep 0.05")
                Vbus_meas = fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num)
                if param.AdditionalParameters.gain ~= nil then
                    Vbus_meas = tonumber(Vbus_meas) * tonumber(param.AdditionalParameters.gain)
                end
                if VBUS_Orignal == 9000 and Vbus_Set > 9200 then
                    Vbus_Set = 9000
                    fixture.set_usb_voltage(Vbus_Set, "", slot_num)

                end
                print(string.format("VBUS_Orignal: %s, Vbus_Set: %s, Vbus_meas: %s", VBUS_Orignal, Vbus_Set, Vbus_meas))
                flow_log.writeFlowLog(string.format("VBUS_Orignal: %s, Vbus_Set: %s, Vbus_meas: %s", VBUS_Orignal, Vbus_Set, Vbus_meas))
                if Vbus_meas <= VBUS_Orignal + 10 and Vbus_meas >= VBUS_Orignal - 5 then
                    break
                end
            end
        end
    end

    local value = Vbus_meas

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local ret = Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    if (ret == false or result == false) and param.AdditionalParameters.fa_sof == "YES" then
        error('Dmm.checkVBUSWithoutFB is error')
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000018_1.0
-- Dmm.checkVBUS( param )
-- Function to measure VBUS_Orignal and  PPVBUS_USB_EMI voltage,
-- calculate diff= VBUS_Orignal-tonumber(Vbus_meas)/1000 and Vbus_Set=VBUS_Orignal+diff
-- if Vbus_Set>=20 mV, it will be fail, otherwise set vbus power to Vbus_Set, then measure PPVBUS_USB_EMI value, get PPVBUS_USB_EMI voltage
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Dmm.checkVBUS(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    os.execute("sleep 0.05")
    local Vbus_meas = fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num)
    if param.AdditionalParameters.gain ~= nil then
        Vbus_meas = tonumber(Vbus_meas) * tonumber(param.AdditionalParameters.gain)
    end

    local VBUS_Orignal = tonumber(param.AdditionalParameters.reference)

    local diff = VBUS_Orignal - tonumber(Vbus_meas)

    local result = true
    local Vbus_Set = VBUS_Orignal + diff
    if tonumber(VBUS_Orignal) == 5000 then

        if Vbus_Set >= 6000 or Vbus_Set<=-6000 then  -- 6000mV
            result = false
        else
            fixture.set_usb_voltage(tonumber(Vbus_Set), "", slot_num)
            os.execute("sleep 0.05")

            Vbus_meas = fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num)
            if param.AdditionalParameters.gain ~= nil then
                Vbus_meas = tonumber(Vbus_meas) * tonumber(param.AdditionalParameters.gain)
            end

        end
    else
        if Vbus_Set>=20000 then    --20V
            result = false
        else
            fixture.set_usb_voltage(tonumber(Vbus_Set), "", slot_num)
            os.execute("sleep 0.05")

            Vbus_meas = fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num)
            if param.AdditionalParameters.gain ~= nil then
                Vbus_meas = tonumber(Vbus_meas) * tonumber(param.AdditionalParameters.gain)
            end

        end
    end

    local value = Vbus_meas

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
-- Unique Function ID            :  Suncode_F000019_1.0
-- Dmm.readGPIOState( param )
-- Function to check GPIO status is high or low
-- voltage < high_level*0.3 is low
-- voltage >=high_level*0.7 and voltage <=high_level*1.2 is high
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function Dmm.readGPIOState(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local value = fixture.read_voltage(netname, "", slot_num)

    if param.AdditionalParameters.gain ~= nil then
        value = tonumber(value) * tonumber(param.AdditionalParameters.gain)
    end

    local voltage = tonumber(value)
    local high_level = tonumber(param.AdditionalParameters.reference)

    if voltage < high_level * 0.3 then
        value = 0
    elseif voltage >= high_level * 0.7 and voltage <= high_level * 1.2 then
        value = 1
    else
        value = -1
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end

    local result = Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

return Dmm


