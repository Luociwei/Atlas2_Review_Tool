local func = {}
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'
local dutCmd = require("Tech/DUTCmd")
local flow_log = require("Tech/WriteLog")

function func.diags(param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local defalut_val = param.Input
    local cmd = param.Commands
    if defalut_val ~= nil then
        cmd = cmd.." "..defalut_val
    end
    dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={record="NO"}})
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
end

function func.current_delta( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local inputDict = param.InputDict
    local value = -9999
    local param1 = param.AdditionalParameters.param1
    if param1 == "Batt_current_Delta" then

        local Batt_current_On =-995
        if inputDict.Batt_current_On ~= nil then
            Batt_current_On = inputDict.Batt_current_On
        end

        local Baseline_current =-995
        if inputDict.Baseline_current ~= nil then
            Baseline_current = inputDict.Baseline_current
        end
        value =  tonumber(Batt_current_On)-tonumber(Baseline_current)
        
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

function func.shutdown(param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    local startTime = os.time()
    
    local cmd = param.Commands

    dut.setDelimiter("")
    dut.write(cmd)
    
    local timeout = 2
    local content = ""
    local lastRetTime = os.time()
    local result = false
    repeat
        
        local status, ret = xpcall(dut.read, debug.traceback, 0.1, '')
        
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret
        end

    until(os.difftime(os.time(), lastRetTime) >= timeout)
    flow_log.writeFlowLog(content)

    dut.setDelimiter(default_delimiter)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"true")
end


return func


