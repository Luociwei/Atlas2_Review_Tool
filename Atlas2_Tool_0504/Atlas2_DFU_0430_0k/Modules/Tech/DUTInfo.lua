local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local common = require("Tech/Common")
local shell = require("Tech/Shell")
local Record = require 'Matchbox/record'

-- Backup
function func.writeICTCB( paraTab )
    sn = tostring(paraTab.Input)
    Log.LogInfo("$$$$ sn"..sn)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    if sn == nil or #sn ~= 17 then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"no input sn")
        return
    end
    
    local dut = Device.getPlugin("dut")
    local failureMsg = ""
    local result = true
    offset = 0x0a
    local sfc_url = common.getSFCURLFromGHJson()
    if sfc_url and #sfc_url > 0 then
        -- sfc_url = string.gsub(sfc_url,'?','')
        if sfc_url:sub(-1) == '?' then
            sfc_url = string.sub(sfc_url,0,-2)
        end
        local ict_result = false
        local query_command = 'curl "' .. sfc_url .. '?sn=' .. sn .. '&c=QUERY_RECORD&ts=ICT&p=result"'
        Log.LogInfo("$$$$ query_command " .. query_command)
        local handle = io.popen(query_command)
        local query_result = handle:read("*a")
        Log.LogInfo("$$$$ query_result " .. query_result)

        if query_result and #query_result > 0 then
            local pattern = 'result=(\\S+)'
            local Regex = Device.getPlugin("Regex")
            local matchs = Regex.groups(query_result, pattern, 1)
                if matchs and #matchs > 0 and #matchs[1] > 0 then
                    local ret = matchs[1][1]
                    Log.LogInfo("$$$$ ict_result " .. ret)
                    if ret == 'PASS' then
                        ict_result = true
                    end
                    if ict_result then
                        local nonce = dut.getNonce(offset)
                        local password = Security.signChallenge(tostring(offset), nonce)
                        if password then
                            dut.writeCB(offset, 0, password, 'MT')
                        else
                            result = false
                            failureMsg = 'get password failed'
                        end
                        -- resp = dut.readCBStatus(offset)
                        -- result = resp == 0
                        -- DataReporting.submit( DataReporting.createBinaryRecord( result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname) )
                    else
                        -- 1 incomplete 
                        -- 2 fail
                        -- 3 untested
                        dut.writeCB(offset, 2, nil, 'MT')
                    end
                else
                    result = false
                    failureMsg = 'ICT result match failed'
                end
        else
            result = false
            failureMsg = 'query result failed'
        end
    else
        result = false
        failureMsg = 'get sfc_url failed'
    end


    -- local sfc = Device.getPlugin("SFC")
    -- local sfc_result = sfc.getAttributes( sn, "ICT", {"result"})
    -- Log.LogInfo("$$$$ sfc_result")
    -- Log.LogInfo(comFunc.dump(sfc_result))
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname, failureMsg)
    -- if not result then
    --     error("test failure")
    -- end

    return result


    -- local result, data = xpcall(dut.send,debug.traceback,"getnonce --hex",3)
    -- local nonce = ""
    -- local pattern = "Nonce: (\\S+)"
    -- local matchs = Regex.groups(data, pattern, 1)
    -- if #matchs > 0 and #matchs[1] > 0 then
    --     nonce = matchs[1][1]
    -- else
    --     DataReporting.submit(DataReporting.createBinaryRecord( false, paraTab.Technology, paraTab.TestName, "Get_Nonce_FAIL") )
    -- end



    -- local nonce = dut.getNonce(offset)
    -- local password = Security.signChallenge(tostring(0x0A), nonce)
    -- dut.writeCB(offset, 0, password, 'MT')
    -- resp = dut.readCBStatus(offset)
    -- result = resp == 0
    -- DataReporting.submit( DataReporting.createBinaryRecord( result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname) )


    -- Log.LogInfo('password: ' .. password)
    -- password = matchs[1][1]
    -- if #password > 39 then
    --     dut.writeCB(offset, 0, password, 'MT')
    --     resp = dut.readCBStatus(offset)
    --     Log.LogInfo("$$$$ readCBStatus resp " .. tostring(resp))
    --     result = resp == 0
    --     DataReporting.submit( DataReporting.createBinaryRecord( result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname) )
    -- else
    --     DataReporting.submit(DataReporting.createBinaryRecord( false, paraTab.Technology, paraTab.TestName, "Password_Format_ERROR") )
    -- end


    -- -- nonce = dut.getNonce(offset)
    -- -- dut.writeCB(offset, 0, nonce, 'MT')
    -- Log.LogInfo("$$$$ nonce")
    -- Log.LogInfo(comFunc.dump(nonce))
    -- pattern = "password:(\\S+)"
    -- local password = ''
    -- data = shell.execute("/Users/gdlocal/Library/Atlas2/supportFiles/get_station_hash " .. tostring(offset) .. " " .. tostring(nonce))
    -- Log.LogInfo("$$$$ get_nonce data :" .. data)
    -- local matchs = Regex.groups(data, pattern, 1)
    -- if #matchs > 0 and #matchs[1] > 0 then
    --     password = matchs[1][1]
    --     if #password > 39 then
    --         dut.writeCB(offset, 0, password, 'MT')
    --         resp = dut.readCBStatus(offset)
    --         Log.LogInfo("$$$$ readCBStatus resp " .. tostring(resp))
    --         result = resp == 0
    --         DataReporting.submit( DataReporting.createBinaryRecord( result, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname) )
    --     else
    --         DataReporting.submit(DataReporting.createBinaryRecord( false, paraTab.Technology, paraTab.TestName, "Password_Format_ERROR") )
    --     end

    -- else
    --     DataReporting.submit(DataReporting.createBinaryRecord( false, paraTab.Technology, paraTab.TestName, "Get_Password_FAIL") )
    -- end
end


function func.writeAndCompareSN( paraTab )
    sn = tostring(paraTab.Input)
    Log.LogInfo("$$$$ sn: "..sn)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    if sn == nil or #sn ~= 17 then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"no input sn")
        return
    end

    DataReporting.submit( DataReporting.createAttribute( "sn", sn ) )

    local dut = Device.getPlugin("dut")
    local result, resp = xpcall(dut.send,debug.traceback,"syscfg add MLB# " .. sn,3)
    if string.find(resp, "Finish!") ~= nil then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "WRITE_SN","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "WRITE_SN","cannot find 'Finish!' in response")
    end
    -- local sn  = dut.getSN()
    -- Log.LogInfo("$$$$ getSN:"..sn ..'****')
    local result, printVal = xpcall(dut.send,debug.traceback,"syscfg print MLB#",3)
    if result then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "READ_SN","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "READ_SN","command run failed")
    end

    if string.find(printVal, sn) then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "CHECK_SN","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "CHECK_SN","sn match failed")
    end
end

function func.writeAndCompareCFG( paraTab )
    sn = tostring(paraTab.Input)
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    if sn == nil or #sn ~= 17 then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName,subsubtestname,"no input sn")
        return
    end

    local dut = Device.getPlugin("dut")
    local sfc = Device.getPlugin("SFC")
    local cfg_info = sfc.getAttributes( sn, {"mlb_cfg"} )
    Log.LogInfo("$$$$ mlb_cfg")
    Log.LogInfo(comFunc.dump(cfg_info))

    local cfg = cfg_info["mlb_cfg"]
    if cfg ~= nil and cfg ~= "" then
        DataReporting.submit( DataReporting.createAttribute( "cfg", cfg ) )
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "QUERY_CFG","")

        -- local ret = dut.send("syscfg add CFG# " .. cfg)
        local result, ret = xpcall(dut.send,debug.traceback,"syscfg add CFG# " .. cfg,3)
        if string.find(ret, "Finish!") ~= nil then
            Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "SET_MLB_CFG","")
        else
            Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "SET_MLB_CFG","cannot find 'Finish!' in response")
        end
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "QUERY_CFG","get mlb_cfg failed")
        return 
    end

    -- local printVal = dut.send("syscfg print CFG#")
    local result, printVal = xpcall(dut.send,debug.traceback,"syscfg print CFG#",3)
    cfg_t = string.gsub(cfg, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
    if string.find(printVal, cfg_t) then
        Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, "Read_MLB_CFG","")
    else
        Record.createBinaryRecord(false, paraTab.Technology, paraTab.TestName, "Read_MLB_CFG","cfg match failed")
    end
end

function func.setTypeCondition( paraTab )
    local ret = paraTab.Input
    local mlb_b = comFunc.splitString(paraTab.AdditionalParameters.mlb_b, ';' )
    local mlb_type = "MLB_A"
    for _, expect in ipairs(mlb_b) do
        if string.find(ret, expect) ~= nil then
            mlb_type = "MLB_B"
            break
        end
    end
    Record.createBinaryRecord(true, paraTab.Technology, paraTab.TestName, paraTab.AdditionalParameters.subsubtestname)
    return mlb_type
end

function func.getMemorySize( paraTab )
    local Regex = Device.getPlugin("Regex")
    local logFile = Device.userDirectory .. "/uart.log"
    local ret = ""
    local inputValue = paraTab.Input
    if inputValue then
        Log.LogInfo("$$$$ getMemorySize from inputValue")
        ret = inputValue
    else
        Log.LogInfo("$$$$ getMemorySize from uart.log")
        ret = comFunc.fileRead(logFile)
    end
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    local failureMsg = ""
    local divisor = 1
    local result = true
    local memorySize = '0GB'

    if paraTab.AdditionalParameters.pattern then
        local Regex = Device.getPlugin("Regex")
        local pattern = paraTab.AdditionalParameters.pattern
        local matchs = Regex.groups(ret, pattern, 1)
        if matchs and #matchs > 0 and #matchs[1] > 0 then
            ret = matchs[1][1]
        else
            result = false
            failureMsg = 'match failed'
        end
    else
        result = false
        failureMsg = 'miss pattern'
    end

    if paraTab.AdditionalParameters.divisor then
        if tonumber(paraTab.AdditionalParameters.divisor) ~= 0 then
            divisor = tonumber(paraTab.AdditionalParameters.divisor)
        else
            result = false
            failureMsg = 'divisor error'
        end
    end

    if result then
        memorySize = string.format("%dGB",(tonumber(ret) / divisor))
        if paraTab.AdditionalParameters.attribute then
            DataReporting.submit( DataReporting.createAttribute( paraTab.AdditionalParameters.attribute, memorySize ) )
        end
    end
    Record.createBinaryRecord(result, paraTab.Technology, paraTab.TestName, subsubtestname,failureMsg)
    return memorySize
end

return func