local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dmm = require("Tech/Dmm")



function func.sendLedCommand(param)
    local testname = param.Technology
    local subtestname = param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
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

    Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)

end

function func.getSlotID(param)
    
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local slot_num = tonumber(Device.identifier:sub(-1))
    local pluginFunc = Device.getPlugin("FixturePlugin")
    local timeout = param.AdditionalParameters["Timeout"] or 20
    local fixture_serial_number = pluginFunc.get_serial_number()

    DataReporting.fixtureID(fixture_serial_number, tostring(slot_num))
    Log.LogInfo('$$$$ fixture_serial_number: '..fixture_serial_number..' headID: '..slot_num)

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(slot_num),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

function func.getVendorID(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local vendor_id = 1
    local limit = nil
    local limitTab = param.limit
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    local result = Record.createParametricRecord(tonumber(vendor_id),testname, subtestname, subsubtestname,limit)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return vendor_id
end

function func.getStationName(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local station_name = "QL"
    Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    return station_name
end


local MD5_HARD = "d80328ee556344c91277642ec36d4479" -- 2.116.0.1
local SHA1_HARD = "12656accd0f78dd23edf1c835f1d119c1497b355" --2.116.0.1

function func.acefw_vs_Mac(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local fw_version = "J407-USBC-2.77.0.2-A1-14-P0-AP-S.bin"
    local local_fw_path ="/Users/gdlocal/Library/Atlas2/supportFiles/customer/ACE_FW/bin"
    local local_fw_fullpath=tostring(local_fw_path.."/"..fw_version)
    Log.LogInfo('$$$$ local_fw_fullpath: '..local_fw_fullpath)

    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")

    local MD5_COMPUTED_MM = string.match(RunShellCommand.run("/sbin/md5 "..local_fw_fullpath).output, "MD5.-=%s(%w+)")
    Log.LogInfo('$$$$ MD5_COMPUTED_MM: '..MD5_COMPUTED_MM)

    local SHA1_COMPUTED_MM = string.match(RunShellCommand.run("/usr/bin/openssl sha1 "..local_fw_fullpath).output, "SHA1.-=%s(%w+)")
    
    if MD5_HARD==MD5_COMPUTED_MM and SHA1_HARD==SHA1_COMPUTED_MM then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    else
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

function func.acefw_vs_Xavier(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local fw_version = "J407-USBC-2.77.0.2-A1-14-P0-AP-S.bin"
    local slot_num = tonumber(Device.identifier:sub(-1))
    local IP = string.format("169.254.1.%d", 31+slot_num)
    os.execute("ping -c 2 "..IP)

    local Save_path="/vault/Atlas/FixtureLog/CH"..tostring(slot_num)
    local Local_FW = Save_path.."/"..fw_version
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")

    Log.LogInfo(RunShellCommand.run("mkdir "..Save_path).output)
    Log.LogInfo(RunShellCommand.run("rm "..Local_FW).output)
    Log.LogInfo(">RunShellCommand.run>===")
    local download_file = tostring("/Users/gdlocal/Library/Atlas2/supportFiles/customer/fwdl_script/get_xavier_ACE_FW.exp "..IP.." "..fw_version.." "..Save_path)

    Log.LogInfo(RunShellCommand.run(download_file).output)

    local MD5_COMPUTED_XV = string.match(RunShellCommand.run("/sbin/md5 "..Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(RunShellCommand.run("/usr/bin/openssl sha1 "..Local_FW).output, "SHA1.-=%s(%w+)")
   
    if MD5_HARD==MD5_COMPUTED_XV and SHA1_HARD==SHA1_COMPUTED_XV then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    else
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)

end


function func.reset(device,slot_num,timeout)
    local fixture = device

    fixture.relay_switch("BL_LED_GAIN_SET","X1",slot_num)
    fixture.relay_switch("BL_LED_GAIN_SET","LOCK",slot_num)
    fixture.relay_switch("USB_TARGET_CURR_GAIN_SET","X1",slot_num)
    fixture.relay_switch("USB_TARGET_CURR_GAIN_SET","LOCK",slot_num)
    fixture.reset(slot_num)

end

function func.resetXavier(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = 2000
    
    func.reset(fixture,slot_num,timeout)

    if param.AdditionalParameters.record == nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)

    end
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)

end



function func.uutCheck(param)

    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local netname = param.AdditionalParameters.netname
    local value = tonumber(dmm.dmm(netname,param,"mV"))
    Log.LogInfo('$ uutCheck: '..tostring(value))
    local result = false
    if tonumber(value) < 100 then
        result = true
    else 
        os.execute("sleep 1")
        value = tonumber(dmm.dmm(netname,param,"mV"))

        if tonumber(value) < 100 then
            result = true
        end
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

function func.snCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local buf = comFunc.fileRead("/vault/data_collection/test_station_config/gh_station_info.json")
    local product = tostring(buf):match("\"PRODUCT\"%s*:%s*\"(.-)\"")
    local station_number = tostring(buf):match("\"STATION_NUMBER\"%s*:%s*\"(.-)\"")

    if tonumber(station_number) < 10 then
        station_number = "00"..station_number
    elseif tonumber(station_number) >= 10 and tonumber(station_number) < 100 then
        station_number = "0"..station_number
    end

    local station_type = "LA"
    local slot_num = tonumber(Device.identifier:sub(-1))
    local data_str = station_type.."_FCT_#"..station_number.."_UUT"..tostring(slot_num)

    local fixture = Device.getPlugin("FixturePlugin")

    local ret = fixture.rpc_write_read("eeprom.read(testbase,cat32,0x0A70,16)",5000,slot_num)
    local result = false
    if string.find(ret,data_str) then
        result = true
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


function func.moduleSNCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local cmd = param.Commands
    local ret = fixture.rpc_write_read(cmd,5000,slot_num)
    ret = string.gsub(ret," ","")
    ret = string.gsub(ret,"\r","")
    ret = string.gsub(ret,"\n","")
    Log.LogInfo(">moduleSNCheck : ".. tostring(ret))
    if param.AdditionalParameters.attribute ~= nil and ret then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ret) )
    end

    local b_result = false
    if #ret >0 then
        b_result = true
    end

    Record.createBinaryRecord(b_result, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


function func.fwCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ret = fixture.rpc_write_read("version.version()",5000,slot_num)

    local ver1 = string.match(ret,"\"Addon_"..".-".."SC\"%s*=%s*(.-)%s*;")
    local ver2 = string.match(ret,"\"MIX_FW_PACKAGE\"%s*=%s*(.-)%s*;")
    local ver3 = string.match(ret,"\"PL_"..".-".."_FCT_SC\"%s*=%s*(.-)%s*;")
    local ver = ver2..'.'..ver1.."."..ver3

    if param.AdditionalParameters.attribute ~= nil and ver then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ver) )
    end

    local result = false
    if ver == "13.12.5" then
        result = true
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end

function func.ipCheck(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local ret = fixture.rpc_write_read("io.get_ip()",5000,slot_num)

    local ip = "169.254.1.3" .. tostring(1+slot_num)
    if param.AdditionalParameters.attribute ~= nil and ip then
        DataReporting.submit( DataReporting.createAttribute( param.AdditionalParameters.attribute, ip) )
    end
    
    local result = false
    if ret == ip then
        result = true
    end
    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


function func.sendCmd( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local command = param.Commands
    local cmd = string.gsub(tostring(command),"*",",")

    local ret = fixture.rpc_write_read(cmd,10000,slot_num)
    
    local result = true
    if string.find(ret, "ERR") then
        result = false
    end

    Record.createBinaryRecord(result, testname, subtestname, subsubtestname)

end

function func.read_voltage( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname

    local slot_num = tonumber(Device.identifier:sub(-1))
    local netname = param.AdditionalParameters.netname
    local value = tonumber(dmm.dmm(netname,param,"mV"))

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

function func.frequence( param )
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName .. param.testNameSuffix
    local subsubtestname = param.AdditionalParameters.subsubtestname
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local netname = param.AdditionalParameters.netname
    local timeout = 5000

    local io_cmd = fixture.get_measure_table(netname,"IO",slot_num)
    fixture.rpc_write_read(io_cmd,timeout,slot_num)
    
    local f = {GAIN=1,OFFSET=0}

    local ai_gain =  fixture.get_measure_table(netname,"GAIN",slot_num)
    if ai_gain then f.GAIN = ai_gain end
    os.execute("sleep 0.01")

    local door_v = param.AdditionalParameters.door
    local cmd = "blade.frequency_measure(-fd,"..tostring(door_v)..",1000)"

    local response = fixture.rpc_write_read(cmd,timeout,slot_num)


    local value_freq = string.match(response,"%(([+-]?%d+.%d*)%s+Hz")
    local value_dc = string.match(response,"%,%s*([+-]?%d+.%d*)%s+%%")
    if value_freq == nil  then value_freq = 0 end
    if value_dc == nil then value_dc = 0 end

    local value = string.format("%.3f",value_freq)

    local limitTab = param.limit
    local limit = nil
    if limitTab then
        limit = limitTab[param.AdditionalParameters.subsubtestname]
    end
    Record.createParametricRecord(tonumber(value),testname, subtestname, subsubtestname,limit)
    return value
    
end



return func


