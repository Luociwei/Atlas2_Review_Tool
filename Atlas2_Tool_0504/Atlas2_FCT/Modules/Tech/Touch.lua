local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'


function func.current_delta( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName .. paraTab.testNameSuffix
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local inputDict = paraTab.InputDict

    local value = -999
    if paraTab.AdditionalParameters.delta ~=nil then
        local delta_name = paraTab.AdditionalParameters.delta
        if delta_name == "PFM_current_Delta" then
            value = tonumber(inputDict.PFM_current_No_load) - tonumber(inputDict.Baseline_current)

        elseif delta_name == "PWM_current_Delta" then
            value = tonumber(inputDict.PWM_current_No_load) - tonumber(inputDict.Baseline_current)
            
        elseif delta_name == "Dombra_Delta" then
            value = tonumber(inputDict.PWM_current_No_load) - tonumber(inputDict.PFM_current_No_load)
        end

    end

    local limitTab = paraTab.limit
    local limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return value

end

return func


