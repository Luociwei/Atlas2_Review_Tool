
local ActionFunc = {}
local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")

function ActionFunc.startReport(dut)
    StationInfo = Atlas.loadPlugin("StationInfo")
    local sn = dut.mlbSerialNumber()
    DataReporting.primaryIdentity(sn)

    DataReporting.fixtureID(string.match(StationInfo.station_id(), "_(%d+)_"), Device.identifier)
    
end

-- dispatch test cases 
function ActionFunc.DiagsVerTest(params)
    local uart = "uart:///dev/cu.koba-000996"
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    CommBuilder.setLogFilePath(Device.userDirectory.."/rawuart.log", Device.userDirectory.."/rawuart_temp.log")
    local dut = CommBuilder.createEFIPlugin(uart)
    
    if dut.isOpened() ~= true then
        dut.open(2)
        dut.syncCmdResp()
    end
    
    -- ActionFunc.startReport(dut)
    
    local recordDOE = 0

    local count = 1
    local maxCount = 1000
    repeat
        dut.send("ver")
        if recordDOE ~= 0 then
            local subsubtest = tostring(params.AdditionalParameters["subsubtestname"]) .. "-" .. tostring(count)
            print(Device.identifier ..": Start to add record: " .. subsubtest)
            local record = DataReporting.createParametricRecord(5, params.Technology, params.TestName, subsubtest)
            record.applyLimit(0,0,5,10)
            DataReporting.submit(record)  -- 4s
            print(Device.identifier ..": End to add record: " .. subsubtest) --9s
        end
        count = count + 1
    until count > maxCount
    return 1
end

return ActionFunc
