local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local common = require("Tech/Common")
local Record = require 'Matchbox/record'


function func.get_station( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local station_type = "LA"
    local failureMsg = ""
    Record.createBinaryRecord(true, testname, subtestname, subsubtestname,failureMsg)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

function func.get_site( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local station_type = "LA_LH"
    local failureMsg = ""
    Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


function func.get_bd( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    
    local input =  paraTab.Input
    local ret = ""
    if input == "0x12" then
        ret = "MLB_B"
    elseif input == "0x10"  then
        ret = "MLB_A"
    else
        ret = "Unknown"
    end

    local result = true

    if paraTab.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
    end

    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Log.LogInfo("$$$$ get bd: "..ret)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return ret

end


function func.check_Syscfg_SN( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local interactiveView = Device.getPlugin("InteractiveView")
    local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    

    Log.LogInfo("$$$$$ getSNFromInteractiveView" .. data)
    local mlbsn = ""
    local b_result = false
    if status and #data == 17 then
        mlbsn = data
        local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
        local ret = RunShellCommand.run("python /Users/gdlocal/Library/Atlas2/supportFiles/main.pyc "..tostring(mlbsn)).output
        --local ret = shell.execute("python /Users/gdlocal/Library/Atlas2/supportFiles/main.pyc "..tostring(mlbsn))
        if string.find(ret,"PASS") then
            b_result = true
        end

    end

    Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return mlbsn

end

function func.mlbsnCheck( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local mlbsn = paraTab.Input

    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    local cmd = paraTab.Commands
    local ret = ""
    
    dock_port.readString(slot_num,port) -- clear buffer

    local ret = dock_port.writeRead(cmd.."\r","] :-)",5000,slot_num,port)

    ret = string.gsub(ret,"\r","")
    ret = string.gsub(ret,"\n","")

    if paraTab.AdditionalParameters.pattern ~=nil then
        local pattern = paraTab.AdditionalParameters.pattern
        ret = string.match(ret,pattern)
    end

    
    if ret~=nil and ret~="" then

        if paraTab.AdditionalParameters.attribute ~= nil and ret then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ret) )
        end
    
    end

    local result = false

    if ret == mlbsn then
        result = true
    end
    
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end 


return func