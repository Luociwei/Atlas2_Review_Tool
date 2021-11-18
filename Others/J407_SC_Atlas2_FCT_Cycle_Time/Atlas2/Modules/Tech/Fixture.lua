local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dmm = require("Tech/Dmm")
local flow_log = require("Tech/WriteLog")

local MD5_HARD = "d80328ee556344c91277642ec36d4479" 
local SHA1_HARD = "12656accd0f78dd23edf1c835f1d119c1497b355"
local fw_version = "J407-USBC-2.116.0.1-A1-19-P0-AP-S.bin"

function func.sendLedCommand(param)
    local testname = param.Technology
    local subtestname = param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local eowyn = Device.getPlugin("Eowyn")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local command = param.Commands
    if command == "led_progress_on" then
        eowyn.led_inprogress_on(slot_num)

    elseif command == "led_red_on" then
        eowyn.led_red_on(slot_num)
        
    elseif command == "led_green_on" then
        eowyn.led_green_on(slot_num)
    end

    flow_log.writeFlowLog(command)
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,"True")
end

function func.getSlotID(param)
    
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local fixture = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20


    local fixture_serial_number = fixture.get_serial_number(slot_num)

    DataReporting.fixtureID(fixture_serial_number, tostring(slot_num))
    --Log.LogInfo('$$$$ fixture_serial_number: '..fixture_serial_number..' headID: '..slot_num)
    flow_log.writeFlowLog(fixture_serial_number)

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(slot_num),testname, subtestname, subsubtestname,limit)

    flow_log.writeFlowLimitAndResult(param,slot_num)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return fixture_serial_number
end

function func.getVendorID(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local vendor_id = fixture.get_vendor_id()

    local limit = nil
    local limitTab = param.limit
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(vendor_id),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,vendor_id)
    return vendor_id
end

function func.getStationName(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local station_name = "LA"
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,station_name)
    return station_name
end


function func.acefw_vs_Mac(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)

    
    local local_fw_path ="/Users/gdlocal/Library/Atlas2/supportFiles/customer/ACE_FW/bin"
    local local_fw_fullpath=tostring(local_fw_path.."/"..fw_version)
    Log.LogInfo('$$$$ local_fw_fullpath: '..local_fw_fullpath)
    flow_log.writeFlowLog(local_fw_fullpath)
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")

    local MD5_COMPUTED_MM = string.match(RunShellCommand.run("/sbin/md5 "..local_fw_fullpath).output, "MD5.-=%s(%w+)")
    Log.LogInfo('$$$$ MD5_COMPUTED_MM: '..MD5_COMPUTED_MM)
    flow_log.writeFlowLog(MD5_COMPUTED_MM)
    local SHA1_COMPUTED_MM = string.match(RunShellCommand.run("/usr/bin/openssl sha1 "..local_fw_fullpath).output, "SHA1.-=%s(%w+)")
    Log.LogInfo('$$$$ openssl_COMPUTED_MM: '..SHA1_COMPUTED_MM)
    flow_log.writeFlowLog(SHA1_COMPUTED_MM)
    local result = false
    if MD5_HARD==MD5_COMPUTED_MM and SHA1_HARD==SHA1_COMPUTED_MM then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(param,result)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

function func.acefw_vs_Xavier(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local slot_num = tonumber(Device.identifier:sub(-1))

    local Save_path="/vault/Atlas/FixtureLog/CH"..tostring(slot_num)
    local Local_FW = Save_path.."/"..fw_version
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    RunShellCommand.run("mkdir "..Save_path)
    RunShellCommand.run("rm "..Local_FW)
    Log.LogInfo(">RunShellCommand.run>===")

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 5000
    local ret = fixture.getAndWriteFile("/mix/addon/dut_firmware/ch1/"..fw_version,Local_FW,slot_num,timeout)
    flow_log.writeFlowLog(ret)
    local MD5_COMPUTED_XV = string.match(RunShellCommand.run("/sbin/md5 "..Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(RunShellCommand.run("/usr/bin/openssl sha1 "..Local_FW).output, "SHA1.-=%s(%w+)")
   
    local result = false
    if MD5_HARD==MD5_COMPUTED_XV and SHA1_HARD==SHA1_COMPUTED_XV then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
end


function func.resetXavier(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ret = fixture.reset(slot_num)
    
    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end

    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,tostring(ret))
end



function func.uutCheck(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local result = fixture.dut_detect(slot_num)
    
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,tostring(result))
end

function func.snCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)

    local StationInfo = Atlas.loadPlugin("StationInfo").station_id()
    local station_number = comFunc.splitBySeveralDelimiter(StationInfo, '_')[3]
    flow_log.writeFlowLog("station_number : "..tostring(station_number))

    if tonumber(station_number) < 10 then
        station_number = "00"..station_number
    elseif tonumber(station_number) >= 10 and tonumber(station_number) < 100 then
        station_number = "0"..station_number
    end

    local station_type = "LA"
    local slot_num = tonumber(Device.identifier:sub(-1))
    local data_str = station_type.."_FCT_#"..station_number.."_UUT"..tostring(slot_num)

    local ret = param.Input
    
    flow_log.writeFlowLog(tostring(ret))
    local result = false
    if ret == data_str then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
end


function func.moduleSNCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local cmd = param.Commands
    local ret = fixture.fixture_command(cmd,5000,slot_num)

    flow_log.writeFlowLog(cmd.." "..tostring(ret))
    if param.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ret) )
    end

    local b_result = false
    if #ret >0 then
        b_result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or b_result == false then
        Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,b_result)
end


function func.fwCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ver = fixture.get_fw_version(slot_num)

    if param.AdditionalParameters.attribute ~= nil and ver then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ver) )
    end

    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,true)
end

function func.ipCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ret = fixture.fixture_command("get_xavier_ip",5000,slot_num)

    flow_log.writeFlowLog(ret)
    local ip = "169.254.1.3" .. tostring(1+slot_num)
    if param.AdditionalParameters.attribute ~= nil and ip then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ip) )
    end
    
    local result = false
    if ret == ip then
        result = true
    end
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(param,result)
end


function func.sendCmd( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local command = param.Commands

    local ret = fixture.fixture_command(command,10000,slot_num)
    flow_log.writeFlowLog(command.." "..ret)
    local result = true
    if string.find(ret, "ERR") then
        result = false
    end
    
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" or result==false then
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    end

end

function func.read_voltage( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local value = tonumber(dmm.dmm(netname,param))

    if param.AdditionalParameters.gain ~= nil then
        value = tonumber(value) *tonumber(param.AdditionalParameters.gain)
    end


    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    local inputValue = param.Input
    if inputValue and inputValue == "TRUE" then
        return "TRUE","voltage out of limit"
    end
    
    return value
    
end


function func.sendVDMCmd( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local cmd = param.Commands
    

end


return func


