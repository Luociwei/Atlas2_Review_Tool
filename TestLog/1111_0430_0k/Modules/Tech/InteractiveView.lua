-------------------------------------------------------------------
----***************************************************************
----InteractiveView Commands
----Created at: 10/21/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------

local ActionFunc = {}
local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")

-- Read back SN from previous InteractiveView
-- @param paraTab: parameters from tech csv line(table)
-- @return: SN

function ActionFunc.readSN(paraTab)
    local sendCommand__inner = function ()
        local InteractiveView = Device.getPlugin("InteractiveView")
        
        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local dataReturn = ""
        Log.LogInfo("Running readSN for: " ..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
        
        dataReturn = InteractiveView.getData(Device.systemIndex)
         
        Log.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end
        
        DataReporting.primaryIdentity(dataReturn)

        Log.LogInfo("Got resp:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end
    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("readSN failed: " .. tostring(ret))
    end
    -- Check if matches expect string
    local expect = paraTab.AdditionalParameters["expect"]
    if expect ~= nil and string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
        status = false
        Log.LogError("expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
    end
    
    local report = DataReporting.createBinaryRecord(status, paraTab.Technology, paraTab.TestName..paraTab.testNameSuffix, paraTab.AdditionalParameters["subsubtestname"])
    DataReporting.submit(report)    
    return ret
end


function ActionFunc.showScan(paraTab)
      local sendCommand__inner = function ()
        local InteractiveView = Device.getPlugin("InteractiveView")
        
        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)

        local dataReturn = ""
        Log.LogInfo("Running showScan: " .. viewIdentifier .. ". "..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))

        local viewConfig = {
                              ["length"] = paraTab.AdditionalParameters["length"],  
                              ["title"] = paraTab.AdditionalParameters["title"],
                              ["input"] = comFunc.parseParameter(string.gsub(paraTab.AdditionalParameters["input"] or "", "'", "\""))
                           }
        
        dataReturn = InteractiveView.showView(Device.systemIndex, viewConfig)
        
        Log.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end

        Log.LogInfo("Got resp:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("scanConfig failed: " .. tostring(ret))
    end
    
    -- Check if matches expect string
    local expect = paraTab.AdditionalParameters["expect"]
    if ret == nil or expect ~= nil and string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
        status = false
        Log.LogError("Invalid input or expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
    end
    
    local report = DataReporting.createBinaryRecord(status, paraTab.Technology, paraTab.TestName..paraTab.testNameSuffix, paraTab.AdditionalParameters["subsubtestname"])
    DataReporting.submit(report)
    

    return ret
end


function ActionFunc.showSwitch(paraTab)
      local sendCommand__inner = function ()
        local InteractiveView = Device.getPlugin("InteractiveView")
        
        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)

        local dataReturn = ""
        Log.LogInfo("Running showSwitch: " .. viewIdentifier .. ". "..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))

        local viewConfig = {
                              ["length"] = paraTab.AdditionalParameters["length"],  
                              ["title"] = paraTab.AdditionalParameters["title"], 
                              ["switch"] = comFunc.parseParameter(string.gsub(paraTab.AdditionalParameters["switch"] or "", "'", "\""))
                           }
        
        dataReturn = InteractiveView.showView(Device.systemIndex, viewConfig)
        
        Log.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end

        Log.LogInfo("Got resp:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("scanConfig failed: " .. tostring(ret))
    end
    
    -- Check if matches expect string
    local expect = paraTab.AdditionalParameters["expect"]
    if expect ~= nil and string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
        status = false
        Log.LogError("expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
    end
    
    local report = DataReporting.createBinaryRecord(status, paraTab.Technology, paraTab.TestName..paraTab.testNameSuffix, paraTab.AdditionalParameters["subsubtestname"])
    DataReporting.submit(report)
    return ret
end

-- Show Prompt with buttons for user to click matching button
-- @param paraTab: parameters from tech csv line(table)
-- @return: TRUE/FALSE (determined by button clicked by user)

function ActionFunc.showPassFailPrompt(paraTab)
   
    local sendCommand__inner = function ()
        local InteractiveView = Device.getPlugin("InteractiveView")
        
        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)

        local dataReturn = ""
        Log.LogInfo("Running showPassFailPrompt: " .. tostring(viewIdentifier) .. ". "..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
        
        local viewConfig = {
                             ["title"] = paraTab.AdditionalParameters["title"], 
                             ["message"] = paraTab.AdditionalParameters["message"], 
                             ["button"] = comFunc.parseParameter(string.gsub(paraTab.AdditionalParameters["button"] or "", "'", "\""))
                           }
       
        dataReturn = InteractiveView.showView(Device.systemIndex, viewConfig)
        
        Log.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end
        
        Log.LogInfo("Got resp:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("passFailPrompt failed: " .. tostring(ret))
    end
    
    if ret == nil or ret == false then
        status = false
        Log.LogError("User clicked FAIL. Return code: " .. tostring(ret))
    end
    
    local report = DataReporting.createBinaryRecord(status, paraTab.Technology, paraTab.TestName..paraTab.testNameSuffix, paraTab.AdditionalParameters["subsubtestname"])
    DataReporting.submit(report)
    return ret
end

-- Show Alert for user attention
-- @param paraTab: parameters from tech csv line(table)
-- @return: TRUE.

function ActionFunc.showAlert(paraTab)
    local sendCommand__inner = function ()
        local InteractiveView = Device.getPlugin("InteractiveView")
        
        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)
 
        local dataReturn = ""
        Log.LogInfo("Running showAlert: " .. tostring(viewIdentifier) .. ". "..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ", cmd: '" .. tostring(cmd) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]))
        
        local viewConfig = {
                             ["title"] = paraTab.AdditionalParameters["title"],
                             ["message"] = paraTab.AdditionalParameters["message"],
                             ["button"] = { "OK" } 
                           }
        
        dataReturn = InteractiveView.showView(Device.systemIndex, viewConfig)
        
        Log.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end
        
        Log.LogInfo("Got resp:"..paraTab.Technology .. ", " .. paraTab.TestName .. ", " .. tostring(paraTab.AdditionalParameters["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("alert failed: " .. tostring(ret))
    end
    
    if ret == nil or ret == false then
        status = false
        Log.LogError("User clicked FAIL. Return code: " .. tostring(ret))
    end
    
    local report = DataReporting.createBinaryRecord(status, paraTab.Technology, paraTab.TestName..paraTab.testNameSuffix, paraTab.AdditionalParameters["subsubtestname"])
    DataReporting.submit(report)
    return ret
end

function ActionFunc.sleep(paraTab)
    os.execute("sleep " .. tostring(paraTab.AdditionalParameters["delay"]))
     local report = DataReporting.createBinaryRecord(status, paraTab.Technology, paraTab.TestName..paraTab.testNameSuffix, paraTab.AdditionalParameters["subsubtestname"])
    DataReporting.submit(report)
end

return ActionFunc
