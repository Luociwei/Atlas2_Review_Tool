local BatteryCharger = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local flow_log = require("Tech/WriteLog")

-- for cbat table
local cbat_curr_table = {
    { 100, 500, 1000, 2100, 2400, 3000, 3000, 3000, 3 },
    { 100, 500, 1000, 1500, 2000, 3000, 3000, 3000, 3 },
    { 100, 500, 1000, 1500, 2000, 3000, 3000, 3000, 3 },
    { 100, 500, 1000, 1500, 2000, 2500, 2500, 2500, 3 }
}

local cbatt_list_value = {}
local cbat_read_value = ""


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000001_1.0
-- BatteryCharger.convertCurrTableToString(tb)
-- Function to convert a table data to string value, spaces are used between characters
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 01/07/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table
-- Output Arguments              : a string
-----------------------------------------------------------------------------------]]
function BatteryCharger.convertCurrTableToString(tb)
    local str = ""
    for i = 1, #tb do
        str = str .. string.format("0x%08X", math.floor(tb[i] * 65536)) .. " "
    end
    str = string.match(str, "(.+)%s*")
    return str
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000002_1.0
-- BatteryCharger.convertCurrStringToTable(str)
-- Function to convert string to table
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a string
-- Output Arguments              : a table
-----------------------------------------------------------------------------------]]
function BatteryCharger.convertCurrStringToTable(str)
    local cbatt_list = {}
    if not (str) then
        return cbatt_list
    end
    local current_list = comFunc.splitString(str, " ")

    for i = 1, 4 do
        local tmp = {}
        for j = 1, 17 do
            if j < 17 then
                local c = current_list[(i - 1) * 17 + j]
                table.insert(tmp, c)
            else
                local c = current_list[(i - 1) * 17 + j]
                table.insert(tmp, c)
            end
        end
        table.insert(cbatt_list, tmp)
    end
    return cbatt_list
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000003_1.0
-- BatteryCharger.chargeTest( param )
-- Function to raising up the battery voltage from 3.42 to 4.3 step 5mV each time reading ibatt 
-- if ibatt >2000mA(QF)/2200mA(QN) then record PPBATT_VCC
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : table (param of tech csv)
-- Output Arguments              : number
-----------------------------------------------------------------------------------]]
function BatteryCharger.chargeTest(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)

    local param1 = param.AdditionalParameters.param1 or ""
    local value = -9998

    local return_val = -999

    if param1 == "test" then

        local fixture = Device.getPlugin("FixturePlugin")
        local slot_num = tonumber(Device.identifier:sub(-1))

        local start = tonumber(param.AdditionalParameters.start)
        local stop = tonumber(param.AdditionalParameters.stop)
        local step = tonumber(param.AdditionalParameters.step)

        if start > stop then
            step = tonumber("-" .. tostring(step))
        end
        local f1 = 0
        local f2 = 0

        local VVVV = -999
        local IBATT = -999

        for i = start, (stop + step), step do

            if i >= stop then
                fixture.set_battery_voltage(4300, "", slot_num)
                os.execute("sleep 0.02")
                break

            else
                fixture.set_battery_voltage(tonumber(i), "", slot_num)
                os.execute("sleep 0.02")

            end

            IBATT = tonumber(fixture.read_voltage("BATT_CURRENT_BIG", "", slot_num))

            if math.abs(IBATT) >= 2000 then
                if f1 == 0 then
                    VBATT = tonumber(fixture.read_voltage("PPBATT_VCC", "", slot_num))
                    f1 = f1 + 1
                else

                end
            end

            dutCmd.sendCmdAndParse({ Commands = "i2c -z 2 -d 7 0x75 0x1920 1", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
            local res = dutCmd.sendCmdAndParse({ Commands = "i2c -z 2 -d 7 0x75 0x1523 1", AdditionalParameters = { pattern = "Data:%s*(0x%x*)", bit = "1", record = "NO", tick = "no" }, isNotTop = true })

            if tonumber(res) == 0 then
                if f2 == 0 then
                    VVVV = tonumber(fixture.read_voltage("PPBATT_VCC", "", slot_num))
                    f2 = f2 + 1
                else

                end
            end

            if (f1 > 0) and (f2 > 0) then
                break
            end

        end
        return_val = VVVV
        value = VBATT

    elseif param1 == "chargecurrent" then
        local start = tonumber(param.AdditionalParameters.start)
        local stop = tonumber(param.AdditionalParameters.stop)
        local step = tonumber(param.AdditionalParameters.step)

        local netname = param.AdditionalParameters.netname

        if start > stop then
            step = tonumber("-" .. tostring(step))
        end

        local fixture = Device.getPlugin("FixturePlugin")
        local slot_num = tonumber(Device.identifier:sub(-1))
        local cmd = param.Commands
        local pattern = param.AdditionalParameters.pattern

        for i = start, stop, step do

            fixture.set_battery_voltage(tonumber(i), "", slot_num)
            os.execute("sleep 0.005")

            local curr = fixture.read_voltage(netname, "", slot_num)
            return_val = curr
            if curr >= 0 then
                return_val = curr
                value = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { pattern = pattern, record = "NO", tick = "no" }, isNotTop = true })
                break
            end
        end

    elseif param1 == "res" then
        value = param.Input

    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    return return_val

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000004_1.0
-- BatteryCharger.reduceBattVoltage( param )
-- Function to falling down Vbatt volt from 4.35 to 4.1 step by step if 0x1514bit0==1 record VBAT
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : a number
-----------------------------------------------------------------------------------]]
function BatteryCharger.reduceBattVoltage(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)

    local start = tonumber(param.AdditionalParameters.start)
    local stop = tonumber(param.AdditionalParameters.stop)
    local step = tonumber(param.AdditionalParameters.step)
    if start > stop then
        step = tonumber("-" .. tostring(step))
    end

    local cmd = param.Commands
    local pattern = param.AdditionalParameters.pattern
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local status_0x1514 = -1

    for i = start, stop, step do

        fixture.set_battery_voltage(tonumber(i), "", slot_num)
        os.execute("sleep 0.005")

        local ret = dutCmd.sendCmdAndParse({ Commands = cmd, AdditionalParameters = { pattern = pattern, record = "NO", tick = "no" }, isNotTop = true })
        if i ~= start then
            if tonumber(ret) then
                status_0x1514 = dutCmd.hexToBinary(ret, 0, nil, nil)
            end

            if tonumber(status_0x1514) == 1 then
                break
            end
        end

    end

    local value = status_0x1514
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
-- Unique Function ID            :  Suncode_F000005_1.0
-- BatteryCharger.recordUSBCurr( param )
-- Function to measure VBUS current and save in VariableTable
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : a number
-----------------------------------------------------------------------------------]]
function BatteryCharger.recordUSBCurr(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local param2 = param.AdditionalParameters.param2
    local curr, volt = string.match(param2, "ma%=(%d+%.*%d*)%*mv%=(%d+%.*%d*)")
    local netname = param.AdditionalParameters.netname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local value = fixture.read_voltage(netname, tostring(volt) .. ";" .. tostring(param.AdditionalParameters.gain), slot_num)

    -- if param.AdditionalParameters.gain ~= nil then
    --     value = tonumber(value) * tonumber(param.AdditionalParameters.gain)
    -- end

    local vtname = "ma" .. tostring(math.floor(curr)) .. "mv" .. tostring(math.floor(volt))

    local current_table = {}
    if param.InputDict.current_table ~= nil then
        current_table = param.InputDict.current_table
        flow_log.writeFlowLog(comFunc.dump(param.InputDict))

    end

    current_table[vtname] = value

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value), testname, subtestname, subsubtestname, limit)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, value)
    return value, current_table

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000006_1.0
-- BatteryCharger.calculateChargeEfficiency( param )
-- Function to calculate eff=((IBATT+system_current)*vsys_lo)/(IBUS*PROT)
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : a number
-----------------------------------------------------------------------------------]]
function BatteryCharger.calculateChargeEfficiency(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)

    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(inputDict))
    local value = 0

    local param1 = param.AdditionalParameters.param1 or ""

    if param1 == "eff" then
        local potomac_vsys = inputDict.potomac_vsys
        local PPVBUS_PROT = inputDict.PPVBUS_PROT
        local USB_TARGET_CURRENT = inputDict.USB_TARGET_CURRENT
        local BATT_CURRENT_BIG = inputDict.BATT_CURRENT_BIG

        local ret = (tonumber(BATT_CURRENT_BIG) * tonumber(potomac_vsys)) / (tonumber(PPVBUS_PROT) * tonumber(USB_TARGET_CURRENT))
        value = math.abs(ret) * 100

    elseif param1 == "eff2" then

        local BATT_CURRENT_BIG_noload = inputDict.BATT_CURRENT_BIG_noload
        local PPVCC_HIGH = inputDict.PPVCC_HIGH
        local PPVCC_MAIN = inputDict.PPVCC_MAIN
        local BATT_CURRENT_BIG_load = inputDict.BATT_CURRENT_BIG_load
        local ELOAD_CURRENT_SENSE1 = inputDict.ELOAD_CURRENT_SENSE1
        local ret = (tonumber(PPVCC_HIGH) * tonumber(ELOAD_CURRENT_SENSE1)) / (tonumber(PPVCC_MAIN) * (tonumber(BATT_CURRENT_BIG_load) - tonumber(BATT_CURRENT_BIG_noload)))
        value = math.abs(ret) * 100

    else

        local BATT_CURRENT_BIG = 0
        if inputDict.BATT_CURRENT_BIG ~= nil then
            BATT_CURRENT_BIG = math.abs(tonumber(inputDict.BATT_CURRENT_BIG))

        end

        local system_current = 0
        if inputDict.system_current ~= nil then
            system_current = inputDict.system_current
        end

        local vsys_lo = 0
        if inputDict.vsys_lo ~= nil then
            vsys_lo = inputDict.vsys_lo
        end

        local vbus_curr = 0
        if inputDict.vbus_curr ~= nil then
            vbus_curr = inputDict.vbus_curr
        end

        local PPVBUS_PROT = 0
        if inputDict.PPVBUS_PROT ~= nil then
            PPVBUS_PROT = inputDict.PPVBUS_PROT
        end

        local eload_val = 0
        if inputDict.eload_val ~= nil then
            eload_val = inputDict.eload_val
        end

        local eff = ((tonumber(BATT_CURRENT_BIG) + tonumber(eload_val) + tonumber(system_current)) * tonumber(vsys_lo)) / (tonumber(vbus_curr) * tonumber(PPVBUS_PROT))
        value = eff * 100

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
-- Unique Function ID            :  Suncode_F000007_1.0
-- BatteryCharger.calculateChargeDCR( param )
-- Function to calculate DCR:
-- (v_emi-v_prot)/vbus_curr
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
function BatteryCharger.calculateChargeDCR(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local param1 = param.AdditionalParameters.param1

    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(inputDict))
    local value = 0
    if param1 == "EMI" then

        local PPVBUS_USB_EMI = -999
        if inputDict.PPVBUS_USB_EMI ~= nil then
            PPVBUS_USB_EMI = inputDict.PPVBUS_USB_EMI
        end

        local PPVBUS_PROT = -999
        if inputDict.PPVBUS_PROT ~= nil then
            PPVBUS_PROT = inputDict.PPVBUS_PROT
        end

        local vbus_curr = -999
        if inputDict.vbus_curr ~= nil then
            vbus_curr = inputDict.vbus_curr
        end

        value = (tonumber(PPVBUS_USB_EMI) - tonumber(PPVBUS_PROT)) / tonumber(vbus_curr)

    elseif sequence.param1 == "VBUS" then

        --if charge_volt["PPVBUS_USB_EMI"] == nil then return -999 end
        --if charge_volt["PPVBUS_PROT"] == nil then return -998 end
        --ret = (charge_volt["PPVBUS_USB_EMI"]-charge_volt["PPVBUS_PROT"])/vbus_curr

        local PPVBUS_USB_EMI = -999
        if inputDict.PPVBUS_USB_EMI ~= nil then
            PPVBUS_USB_EMI = inputDict.PPVBUS_USB_EMI
        end

        local PPVBUS_PROT = -999
        if inputDict.PPVBUS_PROT ~= nil then
            PPVBUS_PROT = inputDict.PPVBUS_PROT
        end

        local vbus_curr = -999
        if inputDict.vbus_curr ~= nil then
            vbus_curr = inputDict.vbus_curr
        end

        value = (tonumber(PPVBUS_USB_EMI) - tonumber(PPVBUS_PROT)) / tonumber(vbus_curr)
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
-- Unique Function ID            :  Suncode_F000008_1.0
-- BatteryCharger.getCurrData( param )
-- Function to convert record cbat  current table to string
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
function BatteryCharger.getCurrData(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    local param1 = param.AdditionalParameters.param1

    local curr_tp = string.match(param1, "mv%=(%d+%.*%d*)")

    local ret = ""
    local tb = {}
    curr_tp = tonumber(curr_tp) / 1000
    flow_log.writeFlowLog(comFunc.dump(param.InputDict))
    if curr_tp == 5 then

        local inputDict = param.InputDict
        local current_table = inputDict.current_table
        local vtvalue = current_table["ma100mv5000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma500mv5000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv5000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma2100mv5000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma2400mv5000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma3000mv5000"]
        table.insert(tb, tonumber(vtvalue))

    elseif curr_tp == 9 then

        local inputDict = param.InputDict
        local current_table = inputDict.current_table
        local vtvalue = current_table["ma100mv9000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma500mv9000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv9000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma1500mv9000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma2000mv9000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma3000mv9000"]
        table.insert(tb, tonumber(vtvalue))

    elseif curr_tp == 12 then

        local inputDict = param.InputDict
        local current_table = inputDict.current_table
        local vtvalue = current_table["ma100mv12000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma500mv12000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv12000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma1500mv12000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma2000mv12000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma3000mv12000"]
        table.insert(tb, tonumber(vtvalue))

    elseif curr_tp == 15 then

        local inputDict = param.InputDict
        local current_table = inputDict.current_table

        local vtvalue = current_table["ma100mv15000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma500mv15000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv15000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma1500mv15000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma2000mv15000"]
        table.insert(tb, tonumber(vtvalue))
        local vtvalue = current_table["ma2500mv15000"]
        table.insert(tb, tonumber(vtvalue))
    end

    local ret = BatteryCharger.convertCurrTableToString(tb)

    if param.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ret))
    end

    local result = false
    if #ret > 0 then
        result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000009_1.0
-- BatteryCharger.setVbusByStep( param )
-- Function to falling down Vbus volt from 5.3 to 4.25 step by step
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
function BatteryCharger.setVbusByStep(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    flow_log.writeFlowLogStart(param)
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)

    local start = tonumber(param.AdditionalParameters.start)
    local stop = tonumber(param.AdditionalParameters.stop)
    local step = tonumber(param.AdditionalParameters.step)

    if start > stop then
        step = tonumber("-" .. tostring(step))
    end

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local result = true
    for i = start, stop, step do

        fixture.set_usb_voltage(tonumber(i), "", slot_num)
        local ret = tonumber(fixture.read_voltage("PPVBUS_PROT", "", slot_num))

        if ret <= 4250 then
            break
        end
        if i == stop then
            result = false
        end
    end

    local value = tonumber(fixture.read_voltage("PPVBUS_USB_EMI", "", slot_num))

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
-- Unique Function ID            :  Suncode_F000010_1.0
-- BatteryCharger.writeCBAT( param )
-- Function to get cbat current for 5V,9V,12V,15V, and send diags commands to DUT
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 07/08/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : string
-----------------------------------------------------------------------------------]]
function BatteryCharger.writeCBAT(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    dutCmd.sendCmd({ Commands = "syscfg init", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })
    dutCmd.sendCmd({ Commands = "cbinit", AdditionalParameters = { record = "NO", tick = "no" }, isNotTop = true })

    local cmd = "rtc --set " .. os.date("%Y%m%d%H%M%S") -- you need set rtc before the syscfg add CBAT
    local det = nil
    local timeout = 8000

    --local vt = Device.getPlugin("VariableTable")

    local inputDict = param.InputDict
    flow_log.writeFlowLog(comFunc.dump(inputDict))
    local current_table = inputDict.current_table

    local ret = dutCmd.sendCmd({ Commands = cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })

    local cbat_cmd = "syscfg add CBAT 0x00000004 0x00000044 0x00001388 0x00002328 0x00002EE0 0x00003A98 "
    for k, v in pairs(cbat_curr_table) do

        local vtname = "mv5000"
        if k == 2 then
            vtname = "mv9000"
        end
        if k == 3 then
            vtname = "mv12000"
        end
        if k == 4 then
            vtname = "mv15000"
        end

        for i = 1, 6 do
            Log.LogInfo("****math.floor(v[i]*65536)======>" .. math.floor(v[i]))

            local vt_name = "ma" .. tostring(math.floor(v[i])) .. vtname
            Log.LogInfo("***vt name***: " .. vt_name)
            local vt_value = current_table[vt_name]
            Log.LogInfo("****vt_value======>" .. tostring(vt_value))
            cbat_cmd = cbat_cmd .. string.format("0x%08X", math.floor(v[i] * 65536)) .. " " .. string.format("0x%08X", math.floor(tonumber(vt_value) * 65536)) .. " "
        end

        local vt_name = "ma" .. tostring(math.floor(v[6])) .. vtname
        local vt_value = current_table[vt_name]
        cbat_cmd = cbat_cmd .. string.format("0x%08X", math.floor(v[7] * 65536)) .. " " .. string.format("0x%08X", math.floor(tonumber(vt_value) * 65536)) .. " "
        cbat_cmd = cbat_cmd .. string.format("0x%08X", math.floor(v[8] * 65536)) .. " " .. string.format("0x%08X", math.floor(tonumber(vt_value) * 65536)) .. " "
        cbat_cmd = cbat_cmd .. string.format("0x%08X", 3) .. " "
    end

    cbat_cmd = string.match(cbat_cmd, "(.+)%s*")
    local cbat_compare = string.match(cbat_cmd, "0x00000004 0x00000044 0x00001388 0x00002328 0x00002EE0 0x00003A98%s*(.*)%s*")
    Log.LogInfo("cbat_cmd-->" .. cbat_cmd)
    Log.LogInfo("cbat_compare-->" .. cbat_compare)

    local ret = dutCmd.sendCmd({ Commands = cbat_cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })

    local result = false
    if string.find(ret, "Finish") then
        result = true
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
    return cbat_compare

end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000011_1.0
-- BatteryCharger.readCBAT( param )
-- Function to send commands to read DUT cabt value and compare
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
function BatteryCharger.readCBAT(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    cbat_read_value = ""   --global value
    cbatt_list_value = {} --global value

    local ret = dutCmd.sendCmd({ Commands = "syscfg print CBAT", AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" }, isNotTop = true })
    cbat_read_value = ret
    local cbat_read = string.match(ret, "CBAT%s*0x00000004 0x00000044 0x00001388 0x00002328 0x00002EE0 0x00003A98%s*(.*)%s*")

    local result = false

    if cbat_read ~= nil then

        local cbatt_list = BatteryCharger.convertCurrStringToTable(cbat_read)
        local cbat_compare = param.Input

        Log.LogInfo("==>>cbat_read: " .. cbat_read)
        Log.LogInfo("==>>cbatt_list: " .. #cbatt_list)
        Log.LogInfo("==>>ret: " .. ret)
        Log.LogInfo("===>>cbat_compare:" .. cbat_compare)

        cbatt_list_value = cbatt_list

        if string.find(ret, cbat_compare) then

            for i = 1, 4 do
                for j = 1, 6 do
                    local norminal = tonumber(cbatt_list[i][2 * j - 1]) / 65536
                    local read_back = tonumber(cbatt_list[i][2 * j]) / 65536
                    local cbat_error = read_back / norminal
                    if cbat_error < 0.9 or cbat_error > 1.1 then
                        result = false
                        break
                    end
                end
            end

            result = true
            ret = 1

        else
            result = false
            ret = -1

        end
    end

    local limitTab = param.limit
    local limit = nil
    local str_limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
        if limit ~= nil then
            if limit.units == "string" then
                str_limit = limit.upperLimit
                --flow_log.writeFlowLog("str_limit==" .. str_limit)
            end
        end
    end
    if str_limit ~= nil then
        if tostring(ret) ~= str_limit then
            result = false
            -- Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
            -- flow_log.writeFlowLimitAndResult(param, result)
        end
    end
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        -- Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
        Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
end

--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000012_1.0
-- BatteryCharger.checkCBAT( param )
-- Function to judge 5V.9V,12V,15V cbat data 
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
function BatteryCharger.checkCBAT(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLogStart(param)
    local param1 = param.AdditionalParameters.param1 or ""
    local result = false
    local ret = -1
    if param1 == "check_Version" then

        local ver_5V = cbatt_list_value[1][17]
        local ver_9V = cbatt_list_value[2][17]
        local ver_12V = cbatt_list_value[3][17]
        local ver_15V = cbatt_list_value[4][17]

        if tonumber(ver_5V) == tonumber(ver_9V) and tonumber(ver_5V) == tonumber(ver_12V) and tonumber(ver_5V) == tonumber(ver_15V) then
            ret = ver_5V
            result = true
        end
    elseif param1 == "check_content" then

        local cbat_compare_str = ""
        local cbat_curr_table_str = ""
        for i = 1, 4 do
            for j = 1, 8 do
                if j < 8 then
                    cbat_compare_str = cbat_compare_str .. cbatt_list_value[i][2 * j - 1] .. " "
                else
                    cbat_compare_str = cbat_compare_str .. cbatt_list_value[i][2 * j - 1]
                end
            end
            cbat_compare_str = cbat_compare_str .. " 0x00000003" .. " "
        end
        Log.LogInfo("cbat_compare_str ============= ", cbat_compare_str)
        for k, v in pairs(cbat_curr_table) do
            for i = 1, 6 do
                cbat_curr_table_str = cbat_curr_table_str .. string.format("0x%08X", math.floor(v[i] * 65536)) .. " "
            end

            cbat_curr_table_str = cbat_curr_table_str .. string.format("0x%08X", math.floor(v[7] * 65536)) .. " "
            cbat_curr_table_str = cbat_curr_table_str .. string.format("0x%08X", math.floor(v[8] * 65536)) .. " "
            cbat_curr_table_str = cbat_curr_table_str .. string.format("0x%08X", 3) .. " "
        end

        Log.LogInfo("cbat_curr_table_str ============= ", cbat_curr_table_str)
        if cbat_compare_str == cbat_curr_table_str then
            ret = 1
            result = true
        end


    elseif param1 == "check_length" then

        local fixed_length_number = 0
        local cbat_response = string.match(cbat_read_value, "CBAT%s*(.*)%s*")
        cbat_response, fixed_length_number = string.gsub(cbat_response, "0x", "")
        local fixed_length = fixed_length_number * 4

        if fixed_length == 296 then
            ret = 1
            result = true
        end

    end

    if param.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit(DataReporting.createAttribute(param.AdditionalParameters.attribute, ret))
    end

    local limitTab = param.limit
    local limit = nil
    local str_limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
        if limit ~= nil then
            if limit.units == "string" then
                str_limit = limit.upperLimit
                --flow_log.writeFlowLog("str_limit==" .. str_limit)
            end
        end
    end
    if str_limit ~= nil then
        if tostring(ret) ~= str_limit then
            result = false
            -- Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
            -- flow_log.writeFlowLimitAndResult(param, result)
        end
    end

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createParametricRecord(tonumber(ret), testname, subtestname, subsubtestname, limit)
        -- Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)

end


--[[---------------------------------------------------------------------------------
-- Unique Function ID            :  Suncode_F000050_1.0
-- BatteryCharger.sendChargeCmd(param)
-- Function to send Charge Cmd
-- Created By                    : Ryan Gao
-- Initial Creation Date         : 11/01/2021
-- Modified By                   : N/A
-- Modification Date             : N/A     
-- Current_Version               : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name                   : Suncode
-- Primary Usage                 : FCT
-- Input Arguments               : a table
-- Output Arguments              : N/A
-----------------------------------------------------------------------------------]]
function BatteryCharger.sendChargeCmd(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname .. " " .. subtestname .. " " .. subsubtestname)

    flow_log.writeFlowLogStart(param)
    local return_str = "charge_pass"
    local result = true
    local cmd = param.Commands
    local ret = dutCmd.sendCmd({ Commands = cmd, AdditionalParameters = { return_val = "raw", record = "NO", tick = "no" } })

    if string.find(ret, "4CC timed out") or string.find(string.upper(ret), "ERROR") then
        result = false
        return_str = "charge_fail"
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
    flow_log.writeFlowLimitAndResult(param, result)
    return return_str
end

return BatteryCharger


