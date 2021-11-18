local Process = {}
local Log = require("Matchbox/logging")
local dutCmd = require("Tech/DUTCmd")
local Record = require 'Matchbox/record'
local powersupply = require("Tech/PowerSupply")
local comFunc = require("Matchbox/CommonFunc")
local flow_log = require("Tech/WriteLog")

myOverrideTable ={}
myOverrideTable.getSN = function()
    local dut = Device.getPlugin("dut")
    local mlbSerialNumber = dut.mlbSerialNumber(3)
    Log.LogInfo("mlbSerialNumber>>>" .. comFunc.dump(mlbSerialNumber))
    return mlbSerialNumber
end

function Process.startCB(param)
    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then dutPluginName = "dut" end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(dutPluginName)..' not found.') end
    local category = param.AdditionalParameters.category
    Log.LogInfo('Starting process control')
    if category ~= nil and category ~= '' then
        ProcessControl.start(dut, category)
    else
        ProcessControl.start(dut, myOverrideTable)
    end
end

function Process.finishCB(param)

    -- do not finish CB if not started.
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Log.LogInfo('Process control finished or not started; skip finishCB.')
        return
    end

    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then dutPluginName = "dut" end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(param.Input)..' not found.') end

    -- read Poison flag from Input
    local Poison = param.Input
    if Poison == 'TRUE' then
        Log.LogInfo('Poison requested; poisoning CB.')
        ProcessControl.poison(dut, myOverrideTable)
    end
    Log.LogInfo('Finishing process control')
    ProcessControl.finish(dut, myOverrideTable)

end

function Process.dut_read( paraTab )
    local dut = Device.getPlugin("dut")
    local default_delimiter = "] :-)"

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    local startTime = os.time()
    local timeout = paraTab.Timeout
    if timeout == nil then
        timeout = 5
    end

    dut.setDelimiter("")

    local cmd = paraTab.Commands
    if cmd ~= nil then
        dut.write(cmd)
    end

    local content = ""

    local lastRetTime = os.time()
    repeat
        
        local status, ret = xpcall(dut.read, debug.traceback, 0.5)
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret

        end

    until(os.difftime(os.time(), lastRetTime) >= timeout)
  
    dut.setDelimiter(default_delimiter)
    return content
end

function Process.setRTC(paraTab)
    local dut = Device.getPlugin("dut")
    if dut.isOpened() ~= 1 then
        --Log.LogInfo("$$$$ dut.open")
        dut.open(2)
    end
    dut.setDelimiter("] :-)")
    local timeout_sub = 5
    if paraTab.AdditionalParameters.timeout ~= nil then
        timeout_sub = tonumber(paraTab.AdditionalParameters.timeout)
    end
    if paraTab.AdditionalParameters.mark~= nil then
        xpcall(Process.dut_read, debug.traceback, {Commands="\r\n",Timeout=timeout_sub})
    end
    local result, rtc = xpcall(dut.setRTC,debug.traceback)
    Log.LogInfo("RTC>>>>",rtc)
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)    
    end
end


function Process.readcb( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    local cmd = "cbread 0x01"
    local ret = dutCmd.dut_writeRead({Commands=cmd,AdditionalParameters={record="NO"}})

    local b_result = false
    if string.find(ret,"Passed") then
        b_result = true
    end
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
end


function Process.forceDfuDischarge( paraTab )

    
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    Log.LogInfo("***forceDfuDischarge******")
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 5000
    
    fixture.relay_switch("PPBATT_VCC_DISCHARGE","CONNECT",slot_num)
    fixture.relay_switch("PPVCC_MAIN_DISCHARGE","CONNECT",slot_num)
    fixture.relay_switch("PPV_BST_AUDIO_DISCHARGE","CONNECT",slot_num)
    flow_log.writeFlowLog("PPBATT_VCC_DISCHARGE CONNECT")
    flow_log.writeFlowLog("PPVCC_MAIN_DISCHARGE CONNECT")
    flow_log.writeFlowLog("PPV_BST_AUDIO_DISCHARGE CONNECT")

    os.execute("sleep 1")

    fixture.relay_switch("PPBATT_VCC_DISCHARGE","DISCONNECT",slot_num)
    fixture.relay_switch("PPVCC_MAIN_DISCHARGE","DISCONNECT",slot_num)
    fixture.relay_switch("PPV_BST_AUDIO_DISCHARGE","DISCONNECT",slot_num)
    flow_log.writeFlowLog("PPBATT_VCC_DISCHARGE DISCONNECT")
    flow_log.writeFlowLog("PPVCC_MAIN_DISCHARGE DISCONNECT")
    flow_log.writeFlowLog("PPV_BST_AUDIO_DISCHARGE DISCONNECT")

    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,"true")
end

function Process.dfu_set( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Log.LogInfo("***dfu_set***")
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    fixture.set_dfu_mode(slot_num)

    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,"ture")
end

function Process.contract_info( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local cmd = paraTab.Commands
    flow_log.writeFlowLog(cmd)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = 5000
    local response = fixture.fixture_command(cmd,timeout,slot_num)
    local ret = string.match(response,"Min%s+Voltage%s+or%s+Power%s+(%w+)%s+mV")
    flow_log.writeFlowLog(ret)

    local limitTab = paraTab.limit
    local limit = nil
    if limitTab then
        limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(ret),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
end


function Process.dock_detect( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    dock_port.setDetectString("Dock Channel Connected",slot_num,port)
    local st = dock_port.waitForString(3000,slot_num,port)

    local result = false
    if tonumber(st) ~= 0 then
        for i=1,5 do
            fixture.relay_switch("VDM_CC1","DISCONNECT",slot_num)
            flow_log.writeFlowLog("VDM_CC1 DISCONNECT")
            os.execute("sleep 0.5")
            fixture.relay_switch("VDM_CC1","TO_ACE_CC1",slot_num)
            flow_log.writeFlowLog("VDM_CC1 TO_ACE_CC1")
            os.execute("sleep 0.5")

            local st = dock_port.waitForString(3000,slot_num,port)
            if st==0 then
                result = true
                break 
            end
        end
    else
        result = true
    end
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,result)
    if result == false then
        error(testname.."-"..subtestname.."-"..subsubtestname.."-fail")
    end
end

function Process.detect( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337

    local cmd = paraTab.Commands

    dock_port.setDetectString("Entering recovery mode",slot_num,port)
    local st = dock_port.waitForString(50000,slot_num,port)

    local result = false
    if tonumber(st) ~= 0 then

            dock_port.writeString("\r",slot_num,port)
            dock_port.writeString("\r",slot_num,port)
            dock_port.setDetectString("] :-)",slot_num,port)
            dock_port.waitForString(3000,slot_num,port)
            local ret = dock_port.readString(slot_num,port)
            if string.find(ret,"%] %:%-%)") then
                result = true  
            end
       
    else

        dock_port.setDetectString("] :-)",slot_num,port)
        dock_port.writeString(cmd.."\r",slot_num,port)
        local st = dock_port.waitForString(15000,slot_num,port)
        if tonumber(st) == 0 then
            result = true

        else
            dock_port.writeString("\r",slot_num,port)
            dock_port.writeString("\r",slot_num,port)
            dock_port.waitForString(5000,slot_num,port)
            local ret = dock_port.readString(slot_num,port)
            if string.find(ret,"%] %:%-%)") then
                result = true  
            end

        end

    end
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,result)

    if result == false then
        error(testname.."-"..subtestname.."-"..subsubtestname.."-fail")
    end

end

function Process.diags_parse( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337
    local cmd = paraTab.Commands
    local ret = dock_port.writeRead(cmd.."\r","] :-)",5000,slot_num,port)
    flow_log.writeFlowLog(ret)
    local ver = string.match(ret,"Version%s+%-%s*(.-)%s+Subcomponents%:%s*APFS")

    if paraTab.AdditionalParameters.attribute ~= nil and ver then
        DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, ver) )
    end

    local result = false
    if ver then
        result = true
    end
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,result)
end

function Process.blank( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local dock_port = Device.getPlugin("DockChannel")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local port = 31337
    local cmd = paraTab.Commands

    dock_port.writeString("\r",slot_num,port)
    dock_port.writeString("\r",slot_num,port)
 
    local result = true
    if paraTab.AdditionalParameters.record ==nil or paraTab.AdditionalParameters.record == "YES" or result == false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

return Process
