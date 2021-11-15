local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")

-- Unique Function ID : Suncode_00002_1.0
-- func.sum_current(param)

-- Function to calculate current from LED IO1 to LED IO 10.
--  value = (LED_IO1_CURRENT)+(LED_IO2_CURRENT)+
--          (LED_IO3_CURRENT)+(LED_IO4_CURRENT)+(LED_IO5_CURRENT)+(LED_IO6_CURRENT)+
--          (LED_IO7_CURRENT)+(LED_IO8_CURRENT)+(LED_IO9_CURRENT)+(LED_IO10_CURRENT)

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: param table
-- Output Arguments : Real Number

function func.sum_current( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict

    local LED_IO1_CURRENT =-995
    if inputDict.LED_IO1_CURRENT ~= nil then
        LED_IO1_CURRENT = inputDict.LED_IO1_CURRENT
    end

    local LED_IO2_CURRENT =-995
    if inputDict.LED_IO2_CURRENT ~= nil then
        LED_IO2_CURRENT = inputDict.LED_IO2_CURRENT
    end

    local LED_IO3_CURRENT =-995
    if inputDict.LED_IO3_CURRENT ~= nil then
        LED_IO3_CURRENT = inputDict.LED_IO3_CURRENT
    end

    local LED_IO4_CURRENT =-995
    if inputDict.LED_IO4_CURRENT ~= nil then
        LED_IO4_CURRENT = inputDict.LED_IO4_CURRENT
    end

    local LED_IO5_CURRENT =-995
    if inputDict.LED_IO5_CURRENT ~= nil then
        LED_IO5_CURRENT = inputDict.LED_IO5_CURRENT
    end

    local LED_IO6_CURRENT =-995
    if inputDict.LED_IO6_CURRENT ~= nil then
        LED_IO6_CURRENT = inputDict.LED_IO6_CURRENT
    end

    local LED_IO7_CURRENT =-995
    if inputDict.LED_IO7_CURRENT ~= nil then
        LED_IO7_CURRENT = inputDict.LED_IO7_CURRENT
    end

    local LED_IO8_CURRENT =-995
    if inputDict.LED_IO8_CURRENT ~= nil then
        LED_IO8_CURRENT = inputDict.LED_IO8_CURRENT
    end

    local LED_IO9_CURRENT =-995
    if inputDict.LED_IO9_CURRENT ~= nil then
        LED_IO9_CURRENT = inputDict.LED_IO9_CURRENT
    end

    local LED_IO10_CURRENT =-995
    if inputDict.LED_IO10_CURRENT ~= nil then
        LED_IO10_CURRENT = inputDict.LED_IO10_CURRENT
    end

    local value = tonumber(LED_IO1_CURRENT)+tonumber(LED_IO2_CURRENT)+tonumber(LED_IO3_CURRENT)+tonumber(LED_IO4_CURRENT)+tonumber(LED_IO5_CURRENT)+tonumber(LED_IO6_CURRENT)+tonumber(LED_IO7_CURRENT)+tonumber(LED_IO8_CURRENT)+tonumber(LED_IO9_CURRENT)+tonumber(LED_IO10_CURRENT)

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


-- Unique Function ID : Suncode_00003_1.0
-- func.efficiency( param )

-- Function to calculate backlight efficiency
--  value = (BATT_CURRENT_BIG_ON) - (BATT_CURRENT_BIG_OFF_4V3)
--  value = (((PPLED_BACK_REG)*(Total_Current))/((PPVCC_MAIN_ON)*(Delta_Current_4V3)))*100
--  value = (((PPLED_BACK_REG)*(Total_Current))/((PPVCC_MAIN_ON)*(Delta_Current_3V2)))*100

-- Created by: Ryan Gao
-- Initial Creation Date : 20/06/2021
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version: 1.0
-- Changes from Previous version: Initial Version
-- Vendor_Name : Suncode
-- Primary Usage: FCT
-- Input Arguments: param table
-- Output Arguments : Real Number

function func.efficiency( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict

    local value = -9999
    if param.AdditionalParameters.index ~=nil then
        local index_name = param.AdditionalParameters.index
        if index_name == "Delta_Current_4V3" then

            local BATT_CURRENT_BIG_ON =-995
            if inputDict.BATT_CURRENT_BIG_ON ~= nil then
                BATT_CURRENT_BIG_ON = inputDict.BATT_CURRENT_BIG_ON
            end
            local BATT_CURRENT_BIG_OFF_4V3 =-995
            if inputDict.BATT_CURRENT_BIG_OFF_4V3 ~= nil then
                BATT_CURRENT_BIG_OFF_4V3 = inputDict.BATT_CURRENT_BIG_OFF_4V3
            end
            value = tonumber(BATT_CURRENT_BIG_ON) - tonumber(BATT_CURRENT_BIG_OFF_4V3)

        elseif index_name == "Efficiency_4V3" then

            local PPLED_BACK_REG =-995
            if inputDict.PPLED_BACK_REG ~= nil then
                PPLED_BACK_REG = inputDict.PPLED_BACK_REG
            end
            local Total_Current =-995
            if inputDict.Total_Current ~= nil then
                Total_Current = inputDict.Total_Current
            end
            local PPVCC_MAIN_ON =-995
            if inputDict.PPVCC_MAIN_ON ~= nil then
                PPVCC_MAIN_ON = inputDict.PPVCC_MAIN_ON
            end
            local Delta_Current_4V3 =-995
            if inputDict.Delta_Current_4V3 ~= nil then
                Delta_Current_4V3 = inputDict.Delta_Current_4V3
            end
            value = ((tonumber(PPLED_BACK_REG)*tonumber(Total_Current))/(tonumber(PPVCC_MAIN_ON)*tonumber(Delta_Current_4V3)))*100

        elseif index_name == "Delta_Current_3V2" then

            local BATT_CURRENT_BIG_ON =-995
            if inputDict.BATT_CURRENT_BIG_ON ~= nil then
                BATT_CURRENT_BIG_ON = inputDict.BATT_CURRENT_BIG_ON
            end
            local BATT_CURRENT_BIG_OFF_3V2 =-995
            if inputDict.BATT_CURRENT_BIG_OFF_3V2 ~= nil then
                BATT_CURRENT_BIG_OFF_3V2 = inputDict.BATT_CURRENT_BIG_OFF_3V2
            end
            value = tonumber(BATT_CURRENT_BIG_ON) - tonumber(BATT_CURRENT_BIG_OFF_3V2)

        elseif index_name == "Efficiency_3V2" then

            local PPLED_BACK_REG =-995
            if inputDict.PPLED_BACK_REG ~= nil then
                PPLED_BACK_REG = inputDict.PPLED_BACK_REG
            end
            local Total_Current =-995
            if inputDict.Total_Current ~= nil then
                Total_Current = inputDict.Total_Current
            end
            local PPVCC_MAIN_ON =-995
            if inputDict.PPVCC_MAIN_ON ~= nil then
                PPVCC_MAIN_ON = inputDict.PPVCC_MAIN_ON
            end
            local Delta_Current_3V2 =-995
            if inputDict.Delta_Current_3V2 ~= nil then
                Delta_Current_3V2 = inputDict.Delta_Current_3V2
            end
            value = ((tonumber(PPLED_BACK_REG)*tonumber(Total_Current))/(tonumber(PPVCC_MAIN_ON)*tonumber(Delta_Current_3V2)))*100

        end
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


