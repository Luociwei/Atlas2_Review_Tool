local Process = {}
local Log = require("Matchbox/logging")

function Process.popupExample(paraTab,globals,locals,conditions)
	local Popup = Device.getPlugin("Popup")
	local buttonClicked = Popup.displayTextConfig("Start display test", "OK")
    local report = DataReporting.createBinaryRecord(true, "Display Test","Start","OK")
    DataReporting.submit(report)

    buttonClicked = Popup.displayTextConfig("Is there any display problem?", "Yes", "No")
    local result
    if buttonClicked == 1 then
    	result = false
    elseif buttonClicked == 2 then
    	result = true
    end
    report = DataReporting.createBinaryRecord(result, "Display Test")
    DataReporting.submit(report)

    local textInput = Popup.barcodeScanTextConfig("Input SerialNumber", "OK")
    report = DataReporting.createBinaryRecord(true, "Display Test","SerialNumber",textInput)
    DataReporting.submit(report)
end

function Process.regexExample(paraTab,globals,locals,conditions)

    local Regex = Device.getPlugin("Regex")
    local comFunc = require("Matchbox/CommonFunc")
    local inputString = "Power=1.1W:Voltage=11.11V\nPower=2.2W:Voltage=22.22V"
    local pattern = "Power=([\\d.]+)W:Voltage=([\\d.]+)V"
    local matchesResult = Regex.matches(inputString,pattern,1)
    Log.LogInfo("matches results:")
    Log.LogInfo(comFunc.dump(matchesResult))
    if type(matchesResult) == "table" and #matchesResult > 0 then
        local report = DataReporting.createBinaryRecord(true,paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,matchesResult[1])
        DataReporting.submit(report)
    end
    local groupsResult = Regex.groups(inputString,pattern,1)
    Log.LogInfo("groups results:")
    Log.LogInfo(comFunc.dump(groupsResult))
    if type(groupsResult) == "table" and #groupsResult[1] > 0 then
        report = DataReporting.createParametricRecord(tonumber(groupsResult[1][2]),paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix)
        DataReporting.submit(report)
    end

    
end


function Process.smokey_parse(paraTab,globals,locals,conditions)

    local Regex = Device.getPlugin("Regex")
    local comFunc = require("Matchbox/CommonFunc")
    local timeout = paraTab.timeout
    local command = paraTab.Commands
    Log.LogInfo(comFunc.dump(paraTab))
    -- local inputString = "Power=1.1W:Voltage=11.11V\nPower=2.2W:Voltage=22.22V"
    local dut = Device.getPlugin("dut")
    local cmdReturn = dut.send(command)
    local pattern = "results: (.+) = ([\\d.]+).*\\[min, max\\] = \\[.*\\]\\s*(pass|fail)"
    local matchesResult = Regex.matches(cmdReturn,pattern,1)
    Log.LogInfo("matches results:")
    Log.LogInfo(comFunc.dump(matchesResult))
    if type(matchesResult) == "table" and #matchesResult > 0 then
        --local report = DataReporting.createBinaryRecord(true,paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,matchesResult[1])
        for _, match in ipairs(matchesResult) do
            local groupsResult = Regex.groups(match,pattern,1)
            Log.LogInfo("groups results:")
            Log.LogInfo(comFunc.dump(groupsResult))
            if type(groupsResult) == "table" and #groupsResult > 0 then
                report = DataReporting.createParametricRecord(tonumber(groupsResult[1][2]),paraTab.Technology,paraTab.TestName..paraTab.testNameSuffix,groupsResult[1][1])
                DataReporting.submit(report)
            end
        end
    end
end

return Process
