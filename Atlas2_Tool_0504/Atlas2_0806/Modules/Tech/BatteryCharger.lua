local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local powersupply = require("Tech/PowerSupply")
local dutCmd = require("Tech/DUTCmd")
local dmm = require("Tech/Dmm")
local relay = require("Tech/Relay")


-- for cbat table
local cbat_curr_table = {
    {100, 500, 1000, 2100, 2400, 3000, 3000, 3000, 3}, 
    {100, 500, 1000, 1500, 2000, 3000, 3000, 3000, 3}, 
    {100, 500, 1000, 1500, 2000, 3000, 3000, 3000, 3}, 
    {100, 500, 1000, 1500, 2000, 2500, 2500, 2500, 3}
}

local cbatt_list_value= {}
local cbat_read_value= ""

-- Unique Function ID : Suncode_000010_1.0
-- dec2bin(v_dec)

-- Function to decimal to binary.

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: one Real number
-- Output Arguments : Real Number

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


-- Unique Function ID : Suncode_000011_1.0
-- hex2bin(value,bit_start,bit_end)

-- Function to hexadecimal to binary. capture from bit_start to bit_end

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: three Real numbers
-- Output Arguments : Real Number

local function hex2bin(value,bit_start,bit_end) --[1]value [2]bit_start [3]bit_end
    value = tonumber(value)
    value = dec2bin(value)
    value = string.format("%08d",value)
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

-- Unique Function ID : Suncode_000014_1.0
-- curr_tb_to_str(tb)  

-- Function to convert a table to string value, use one space to join

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version. directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a string

local function curr_tb_to_str(tb)
    local str = ""
    for i=1,#tb do
        str = str..string.format("0x%08X",math.floor(tb[i]*65536)).." "
    end
    str = string.match(str,"(.+)%s*")
    return str
end


-- Unique Function ID : Suncode_000015_1.0
-- cbat_decode(tb)  

-- Function to convert string to table.

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: directly copy from J5XX fct
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a string
-- Output Arguments : a table

local function cbat_decode(str)
    local cbatt_list = {}

    if not(str) then
        return cbatt_list
    end
    local current_list = comFunc.splitString(str, " ")

    for i=1, 4 do
        local tmp = {}
        for j=1, 17 do
            if j < 17 then
                local c = current_list[ (i-1)*17 + j ]
                table.insert(tmp, c)
            else
                local c = current_list[ (i-1)*17 + j ]
                table.insert(tmp, c)
            end
        end
        table.insert(cbatt_list, tmp)
    end
    return cbatt_list
end


-- Unique Function ID : Suncode_000016_1.0
-- func.blank( param )  

-- Function to send dut command "\r\n"

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A


function func.blank( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local dut = Device.getPlugin("dut")
    local timeout = 5
    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    dut.setDelimiter("] :-)")
    dut.write("\r")
    dut.read(timeout)
    os.execute("sleep 0.01")
    dut.write("\r")
    dut.read(timeout)

    local result = true
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end



-- Unique Function ID : Suncode_000019_1.0
-- func.dir_chg_test( param )

-- Function to raising up the battery voltage from 3.42 to 4.3 step 5mV each time reading ibatt 
-- if ibatt >2000mA(QF)/2200mA(QN) then record PPBATT_VCC

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA


function func.dir_chg_test( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local param1 = param.AdditionalParameters.param1
    local value = -9998

    local return_val = -999

    if param1=="test" then

        local start = tonumber(param.AdditionalParameters.start)
        local stop = tonumber(param.AdditionalParameters.stop)
        local step = tonumber(param.AdditionalParameters.step)

        if start > stop then
            step = tonumber("-"..tostring(step))
        end

        local f1 =0
        local f2 =0

        local VVVV = -999
        local IBATT = -999

        for i=start,(stop+step),step do

            if i>=stop then

                powersupply.set_power({AdditionalParameters={powertype="batt"},Commands=tostring(4.3)})
                os.execute("sleep 0.005")
                break
            else
                powersupply.set_power({AdditionalParameters={powertype="batt"},Commands=tostring(i)})
                os.execute("sleep 0.005")
            end

            IBATT = tonumber(dmm.dmm("BATT_CURRENT_BIG",param,"mA"))

            if math.abs(IBATT) >= 2000 then
                if f1 == 0 then
                    VBATT = tonumber(dmm.dmm("PPBATT_VCC",param,"mV"))
                    f1 = f1 +1
                else

                end
            end 

            dutCmd.dut_writeRead({Commands="i2c -z 2 -d 7 0x75 0x1920 1",AdditionalParameters={record="NO"}})

            local res = dutCmd.dut_writeRead({Commands="i2c -z 2 -d 7 0x75 0x1523 1",AdditionalParameters={pattern="Data:%s*(0x%x*)",bit="1",record="NO"}})--dut.diags_parse({param1="i2c -z 2 -d 7 0x75 0x1523 1"})

            if tonumber(res) == 0 then
                if f2 == 0 then
                    VVVV    = tonumber(dmm.dmm("PPBATT_VCC",param,"mV"))
                    f2 = f2 +1
                else

                end
            end

            if (f1>0) and (f2>0) then 
                break 
            end

        end
        return_val = VVVV
        value = VBATT

    elseif param1=="res" then

        --value = vt.getVar("VVVV")
        value = param.Input
    end


    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return return_val
    
end


-- Unique Function ID : Suncode_000020_1.0
-- func.chargecurrent( param )

-- Function to raising up VBAT from 4.3 to 4.38 if VBATT_curr>=0 
-- record the VBATT it’s stop charge voltage

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.chargecurrent( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local start = tonumber(param.AdditionalParameters.start)
    local stop = tonumber(param.AdditionalParameters.stop)
    local step = tonumber(param.AdditionalParameters.step)

    if start > stop then
        step = tonumber("-"..tostring(step))
    end

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local value = -9999
    local result_current = -1
    for i=start,stop,step do


        powersupply.set_power({AdditionalParameters={powertype="batt"},Commands=tostring(i)})
        os.execute("sleep 0.005")

        local curr = tonumber(dmm.dmm("BATT_CURRENT_BIG",param,"mA"))
        result_current = curr
        if curr >= 0 then
            result_current = curr
            value = dutCmd.dut_writeRead({Commands="pmuadc --sel potomac --read vbat",AdditionalParameters={pattern="([+-]?%d*%.%d*)%s*mV",record="NO"}})
            break
        end
    end

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return result_current
end

-- Unique Function ID : Suncode_000021_1.0
-- func.getchargecurrent( param )

-- Function to measure battery stop charge current

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.getchargecurrent( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local value = param.Input

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

-- Unique Function ID : Suncode_000022_1.0
-- func.reduce_batt( param )

-- Function to falling down Vbatt volt from 4.35 to 4.1 step by step if 0x1514bit0==1 record VBAT

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.reduce_batt( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local start = tonumber(param.AdditionalParameters.start)
    local stop = tonumber(param.AdditionalParameters.stop)
    local step = tonumber(param.AdditionalParameters.step)
    if start > stop then
        step = tonumber("-"..tostring(step))
    end

    local cmd = param.Commands
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local status_0x1514 = -1

    for i=start,stop,step do

        powersupply.set_power({AdditionalParameters={powertype="batt"},Commands=tostring(i)})
        os.execute("sleep 0.005")

        local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={pattern="Data:%s*(0x%x*)",record="NO"}})
        if i~=start then
            if tonumber(ret) then
                status_0x1514  = hex2bin(ret,0)  
            end

            if  tonumber(status_0x1514)==1 then
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
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)


end


-- Unique Function ID : Suncode_000023_1.0
-- func.contract_info( param )

-- Function to Check VDM CC negotiation setting 5V

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.contract_info( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local cmd = param.Commands

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 5000
    local response = fixture.rpc_write_read(cmd,timeout,slot_num)
    local ret = string.match(response,"Min%s+Voltage%s+or%s+Power%s+(%w+)%s+mV")

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end



-- Unique Function ID : Suncode_000025_1.0
-- func.save_usb_curr( param )

-- Function to measure VBUS current and save in VariableTable

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.save_usb_curr( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local param2 = param.AdditionalParameters.param2
    local curr,volt = string.match(param2,"ma%=(%d+%.*%d*)%*mv%=(%d+%.*%d*)")

    local netname = param.AdditionalParameters.netname
    
    local value = dmm.dmm(netname,param,"mA")
 
    --local vt = Device.getPlugin("VariableTable")
    local vtname = "ma"..tostring(math.floor(curr)).."mv"..tostring(math.floor(volt))

    local current_table = {}
    if param.InputDict.current_table ~= nil then
        current_table = param.InputDict.current_table

    end
    
    current_table[vtname] = value

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return value,current_table
    
end

-- Unique Function ID : Suncode_000026_1.0
-- func.charge_efficiency( param )

-- Function to calculate eff=((IBATT+system_current)*vsys_lo)/(IBUS*PROT)

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.charge_efficiency( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local inputDict = param.InputDict

    local BATT_CURRENT_BIG = 0
    if inputDict.BATT_CURRENT_BIG~=nil then
        BATT_CURRENT_BIG = math.abs(tonumber(inputDict.BATT_CURRENT_BIG))
        
    end

    local system_current = 0
    if inputDict.system_current~=nil then
        system_current = inputDict.system_current
    end

    local vsys_lo = 0
    if inputDict.vsys_lo~=nil then
        vsys_lo = inputDict.vsys_lo
    end

    local vbus_curr = 0
    if inputDict.vbus_curr~=nil then
        vbus_curr = inputDict.vbus_curr
    end

    local PPVBUS_PROT = 0
    if inputDict.PPVBUS_PROT~=nil then
        PPVBUS_PROT = inputDict.PPVBUS_PROT
    end

    local eff = ((tonumber(BATT_CURRENT_BIG)+tonumber(system_current))*tonumber(vsys_lo))/(tonumber(vbus_curr)*tonumber(PPVBUS_PROT))
    local value = eff * 100

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


-- Unique Function ID : Suncode_000027_1.0
-- func.charge_efficiency_add_eload( param )

-- Function to calculate eff=((IBATT+system_current+ eload_current)*vsys_lo)/(IBUS*PROT)

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.charge_efficiency_add_eload( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local inputDict = param.InputDict

    local BATT_CURRENT_BIG = 0
    if inputDict.BATT_CURRENT_BIG~=nil then
        BATT_CURRENT_BIG = math.abs(tonumber(inputDict.BATT_CURRENT_BIG))
        
    end

    local system_current = 0
    if inputDict.system_current~=nil then
        system_current = inputDict.system_current
    end

    local vsys_lo = 0
    if inputDict.vsys_lo~=nil then
        vsys_lo = inputDict.vsys_lo
    end

    local vbus_curr = 0
    if inputDict.vbus_curr~=nil then
        vbus_curr = inputDict.vbus_curr
    end

    local PPVBUS_PROT = 0
    if inputDict.PPVBUS_PROT~=nil then
        PPVBUS_PROT = inputDict.PPVBUS_PROT
    end

    local eload_val = 0

    if inputDict.eload_val~=nil then
        eload_val = inputDict.eload_val
    end


    --Log.LogInfo("---charge_eff2: "..subsubtestname)
    --Log.LogInfo("---charge_eff2: "..tostring(BATT_CURRENT_BIG).." "..tostring(system_current).." "..tostring(vsys_lo).." "..tostring(vbus_curr).." "..PPVBUS_PROT)

    local eff = ((tonumber(BATT_CURRENT_BIG)+tonumber(eload_val)+tonumber(system_current))*tonumber(vsys_lo))/(tonumber(vbus_curr)*tonumber(PPVBUS_PROT))
    local value = eff * 100

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

-- Unique Function ID : Suncode_000028_1.0
-- func.charge_dcr( param )

-- Function to calculate DCR:
-- (v_emi-v_prot)/vbus_curr

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.charge_dcr( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local param1 = param.AdditionalParameters.param1

    local inputDict = param.InputDict

    local value = 0
    if param1 == "EMI" then

        local PPVBUS_USB_EMI = -999
        if inputDict.PPVBUS_USB_EMI~=nil then
            PPVBUS_USB_EMI = inputDict.PPVBUS_USB_EMI
        end

        local PPVBUS_PROT = -999
        if inputDict.PPVBUS_PROT~=nil then
            PPVBUS_PROT = inputDict.PPVBUS_PROT
        end

        local vbus_curr = -999
        if inputDict.vbus_curr~=nil then
            vbus_curr = inputDict.vbus_curr
        end

        value = (tonumber(PPVBUS_USB_EMI)-tonumber(PPVBUS_PROT))/tonumber(vbus_curr)

    elseif sequence.param1 == "VBUS" then 

        --if charge_volt["PPVBUS_USB_EMI"] == nil then return -999 end
        --if charge_volt["PPVBUS_PROT"] == nil then return -998 end
        --ret = (charge_volt["PPVBUS_USB_EMI"]-charge_volt["PPVBUS_PROT"])/vbus_curr

        local PPVBUS_USB_EMI = -999
        if inputDict.PPVBUS_USB_EMI~=nil then
            PPVBUS_USB_EMI = inputDict.PPVBUS_USB_EMI
        end

        local PPVBUS_PROT = -999
        if inputDict.PPVBUS_PROT~=nil then
            PPVBUS_PROT = inputDict.PPVBUS_PROT
        end

        local vbus_curr = -999
        if inputDict.vbus_curr~=nil then
            vbus_curr = inputDict.vbus_curr
        end

        value = (tonumber(PPVBUS_USB_EMI)-tonumber(PPVBUS_PROT))/tonumber(vbus_curr)
    end


    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)

end

-- Unique Function ID : Suncode_000029_1.0
-- func.get_curr_data( param )

-- Function to convert record cbat  current table to string
--

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.get_curr_data( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local param1 = param.AdditionalParameters.param1

    local curr_tp = string.match(param1,"mv%=(%d+%.*%d*)")

    local ret = ""
    local tb = {}
    curr_tp = tonumber(curr_tp)/1000

    if curr_tp==5 then

        local inputDict = param.InputDict
        local current_table = inputDict.current_table
        local vtvalue = current_table["ma100mv5000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma500mv5000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv5000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma2100mv5000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma2400mv5000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma3000mv5000"]
        table.insert(tb,tonumber(vtvalue))
    
    elseif curr_tp==9 then

        local inputDict = param.InputDict
        local current_table = inputDict.current_table
        local vtvalue = current_table["ma100mv9000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma500mv9000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv9000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma1500mv9000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma2000mv9000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma3000mv9000"]
        table.insert(tb,tonumber(vtvalue))
        
    elseif curr_tp==12 then  

        local inputDict = param.InputDict
        local current_table = inputDict.current_table
        local vtvalue = current_table["ma100mv12000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma500mv12000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv12000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma1500mv12000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma2000mv12000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma3000mv12000"]
        table.insert(tb,tonumber(vtvalue))
        
    elseif curr_tp==15 then

        local inputDict = param.InputDict
        local current_table = inputDict.current_table

        local vtvalue = current_table["ma100mv15000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma500mv15000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma1000mv15000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma1500mv15000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma2000mv15000"]
        table.insert(tb,tonumber(vtvalue))
        local vtvalue = current_table["ma2500mv15000"]
        table.insert(tb,tonumber(vtvalue))
    end

    local ret = curr_tb_to_str(tb)

    if param.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ret) )
    end

    local result = false
    if #ret > 0 then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)

end

-- Unique Function ID : Suncode_000030_1.0
-- func.get_curr_data( param )

-- Function to falling down Vbus volt from 5.3 to 4.25 step by step
--

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.loop_set_vbus( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local start = tonumber(param.AdditionalParameters.start)
    local stop = tonumber(param.AdditionalParameters.stop)
    local step = tonumber(param.AdditionalParameters.step)

    if start > stop then
        step = tonumber("-"..tostring(step))
    end

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local result = true
    for i=start,stop,step do

        powersupply.set_power({AdditionalParameters={powertype="USB"},Commands=tostring(i)})

        local ret = tonumber(dmm.dmm("PPVBUS_PROT",param,"mV"))

        if ret<=4250 then 
            break 
        end
        if i==stop then 
            result = false
        end
    end

    local value = tonumber(dmm.dmm("PPVBUS_USB_EMI",param,"mV"))
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return value

end


-- Unique Function ID : Suncode_000031_1.0
-- func.efficiency( param )

-- Function to calculate efficiency = IBATT*vsys_lo/PPVBUS_PROT*Ibus
--

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : N/A

function func.efficiency( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local inputDict = param.InputDict
    local potomac_vsys = inputDict.potomac_vsys
    local PPVBUS_PROT = inputDict.PPVBUS_PROT
    local USB_TARGET_CURRENT = inputDict.USB_TARGET_CURRENT
    local BATT_CURRENT_BIG = inputDict.BATT_CURRENT_BIG


    local ret =(tonumber(BATT_CURRENT_BIG)*tonumber(potomac_vsys))/(tonumber(PPVBUS_PROT)*tonumber(USB_TARGET_CURRENT))
    local value = math.abs(ret)*100

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return value

end

-- Unique Function ID : Suncode_000032_1.0
-- func.vsys_hi_eff( param )

-- Function to calculate VCC_HIGH*Eload_Current/VCC_MAIN*(IBAT with Eload-IBAT_without_Eload)
--

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.vsys_hi_eff( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local inputDict = param.InputDict

    local BATT_CURRENT_BIG_noload = inputDict.BATT_CURRENT_BIG_noload
    local PPVCC_HIGH = inputDict.PPVCC_HIGH
    local PPVCC_MAIN = inputDict.PPVCC_MAIN
    local BATT_CURRENT_BIG_load = inputDict.BATT_CURRENT_BIG_load
    local ELOAD_CURRENT_SENSE1 = inputDict.ELOAD_CURRENT_SENSE1


    local ret = (tonumber(PPVCC_HIGH)*tonumber(ELOAD_CURRENT_SENSE1))/(tonumber(PPVCC_MAIN)*(tonumber(BATT_CURRENT_BIG_load)-tonumber(BATT_CURRENT_BIG_noload)))

    local value =math.abs(ret)*100
    
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return value

end

-- Unique Function ID : Suncode_000033_1.0
-- func.dmm_abs( param )

-- Function to measure Ibus current
--

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.dmm_abs( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local netname = param.AdditionalParameters.netname
    local gain = param.AdditionalParameters.gain
    local value = dmm.dmm(netname,param,nil)
    value = math.abs(value)
    --value = math.abs(tonumber(value)*tonumber(gain))
    
    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return value

end

-- Unique Function ID : Suncode_000034_1.0
-- func.dmm_error( param )

-- Function to calculate VBAT_ERROR = (PPBATT_VCC-PMU_VBAT)/PPBATT_VCC*100 
-- or IBAT_ERROR = ((BATT_CURRENT_BIG)-(PMU_IBAT_OUT))/(BATT_CURRENT_BIG)*100
--

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.dmm_error( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

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
    return value




end

-- Unique Function ID : Suncode_000035_1.0
-- func.cbat_write( param )

-- Function to get cbat current for 5V,9V,12V,15V, and send diags commands to DUT
--

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : a number

function func.cbat_write( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    dutCmd.dut_writeRead({Commands="syscfg init",AdditionalParameters={record="NO"}})
    dutCmd.dut_writeRead({Commands="cbinit",AdditionalParameters={record="NO"}})

    local cmd = "rtc --set "..os.date("%Y%m%d%H%M%S") -- you need set rtc before the syscfg add CBAT
    local det = nil
    local timeout = 8000

    --local vt = Device.getPlugin("VariableTable")

    local inputDict = param.InputDict
    local current_table = inputDict.current_table
    

    local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={return_val="raw",record="NO"}})

    local cbat_cmd = "syscfg add CBAT 0x00000004 0x00000044 0x00001388 0x00002328 0x00002EE0 0x00003A98 "
    for k,v in pairs(cbat_curr_table) do

        local vtname = "mv5000"
        if k==2 then vtname = "mv9000" end
        if k==3 then vtname = "mv12000" end
        if k==4 then vtname = "mv15000" end

        for i=1,6 do
            Log.LogInfo("****math.floor(v[i]*65536)======>"..math.floor(v[i]))

            local vt_name = "ma"..tostring(math.floor(v[i]))..vtname
            Log.LogInfo("***vt name***: "..vt_name)
            local vt_value = current_table[vt_name]
            Log.LogInfo("****vt_value======>"..tostring(vt_value))
            cbat_cmd = cbat_cmd..string.format("0x%08X",math.floor(v[i]*65536)).." "..string.format("0x%08X",math.floor(tonumber(vt_value)*65536)).." "
        end

        local vt_name = "ma"..tostring(math.floor(v[6]))..vtname
        local vt_value = current_table[vt_name]
        cbat_cmd = cbat_cmd..string.format("0x%08X",math.floor(v[7]*65536)).." "..string.format("0x%08X",math.floor(tonumber(vt_value)*65536)).." "
        cbat_cmd = cbat_cmd..string.format("0x%08X",math.floor(v[8]*65536)).." "..string.format("0x%08X",math.floor(tonumber(vt_value)*65536)).." "
        cbat_cmd = cbat_cmd..string.format("0x%08X",3).." "
    end


    cbat_cmd = string.match(cbat_cmd, "(.+)%s*")
    local cbat_compare = string.match(cbat_cmd,"0x00000004 0x00000044 0x00001388 0x00002328 0x00002EE0 0x00003A98%s*(.*)%s*")
    Log.LogInfo("cbat_cmd-->"..cbat_cmd)
    Log.LogInfo("cbat_compare-->"..cbat_compare)

    local ret = dutCmd.dut_writeRead({Commands=cbat_cmd,AdditionalParameters={return_val="raw",record="NO"}})

    local result = false
    if string.find(ret,"Finish") then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return cbat_compare

end


-- Unique Function ID : Suncode_000036_1.0
-- func.cbat_read( param )

-- Function to send commands to read DUT cabt value and compare

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA

function func.cbat_read( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    cbat_read_value =""   --global value
    cbatt_list_value = {} --global value

    local ret = dutCmd.dut_writeRead({Commands="syscfg print CBAT",AdditionalParameters={return_val="raw",record="NO"}})
    cbat_read_value = ret
    local cbat_read = string.match(ret,"CBAT%s*0x00000004 0x00000044 0x00001388 0x00002328 0x00002EE0 0x00003A98%s*(.*)%s*")

    local result = false

    if cbat_read ~= nil then
    
        local cbatt_list = cbat_decode(cbat_read)
        local cbat_compare = param.Input

        Log.LogInfo("==>>cbat_read: "..cbat_read)
        Log.LogInfo("==>>cbatt_list: "..#cbatt_list)
        Log.LogInfo("==>>ret: "..ret)
        Log.LogInfo("===>>cbat_compare:"..cbat_compare)

        cbatt_list_value = cbatt_list

        
        if string.find(ret,cbat_compare) then 

            for i=1, 4 do
                for j=1, 6 do
                    local norminal = tonumber(cbatt_list[i][2*j-1]) / 65536
                    local read_back = tonumber(cbatt_list[i][2*j]) / 65536
                    local cbat_error = read_back/norminal
                    if cbat_error < 0.9 or cbat_error > 1.1 then
                        result = false
                        break
                    end
                end
            end

            result = true

        else
            result = false
        end   
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

-- Unique Function ID : Suncode_000037_1.0
-- func.get_cbat_ver( param )

-- Function to judge 5V.9V,12V,15V cbat data 

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA

function func.get_cbat_ver( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local ver_5V = cbatt_list_value[1][17]
    local ver_9V = cbatt_list_value[2][17]
    local ver_12V = cbatt_list_value[3][17]
    local ver_15V = cbatt_list_value[4][17]

    local ret = nil
    local result = false
    if tonumber(ver_5V) == tonumber(ver_9V) and tonumber(ver_5V) == tonumber(ver_12V) and tonumber(ver_5V) == tonumber(ver_15V) then
        ret =  ver_5V
        result = true
    end


    if param.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ret) )
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)

end


-- Unique Function ID : Suncode_000038_1.0
-- func.fixed_string_check( param )

-- Function to convert cbat table value to string, and compare if is equal to local constant value 

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA

function func.fixed_string_check( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local cbat_compare_str = ""
    local cbat_curr_table_str = ""
    for i=1, 4 do
        for j=1, 8 do
            if j< 8 then
                cbat_compare_str = cbat_compare_str..cbatt_list_value[i][2*j-1].." "
            else
                cbat_compare_str = cbat_compare_str..cbatt_list_value[i][2*j-1]
            end
        end
        cbat_compare_str = cbat_compare_str.." 0x00000003".." "        
    end
    Log.LogInfo("cbat_compare_str ============= ", cbat_compare_str)
    for k,v in pairs(cbat_curr_table) do
        for i=1,6 do
            cbat_curr_table_str = cbat_curr_table_str..string.format("0x%08X",math.floor(v[i]*65536)).." "
        end

        cbat_curr_table_str = cbat_curr_table_str..string.format("0x%08X",math.floor(v[7]*65536)).." "
        cbat_curr_table_str = cbat_curr_table_str..string.format("0x%08X",math.floor(v[8]*65536)).." "
        cbat_curr_table_str = cbat_curr_table_str..string.format("0x%08X",3).." "
    end

    Log.LogInfo("cbat_curr_table_str ============= ", cbat_curr_table_str)

    local result = false
    if cbat_compare_str == cbat_curr_table_str then
        result = true
    else
        result = false
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


-- Unique Function ID : Suncode_000039_1.0
-- func.fixed_length_check( param )

-- Function to check the cbat length

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: a table
-- Output Arguments : NA

function func.fixed_length_check( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local fixed_length_number = 0
    local cbat_response = string.match(cbat_read_value,"CBAT%s*(.*)%s*")
    cbat_response,fixed_length_number = string.gsub(cbat_response, "0x", "")
    local fixed_length = fixed_length_number*4

    local result = false

    if fixed_length == 296 then 
        result =  true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


return func


