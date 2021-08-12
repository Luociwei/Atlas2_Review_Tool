local Plugins = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local json = require("Matchbox/json")
-- local resources = Group.getResources()


-- uncomment the line below to enable loop per detection.
-- Plugins.loops_per_detection = 1
Plugins.current_loop_count = 1
Plugins.loopMax = 1
Plugins.ret = {}

function Plugins.loadPlugins(deviceName , groupPlugins)
      -- deviceName = Device_slot#
  
    local socParser = Atlas.loadPlugin("SOCParser")
    local mdParser = Atlas.loadPlugin("MDParser")
    mdParser.init("/Users/gdlocal/Library/Atlas2/Assets/parseDefinitions")
    

    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)
    CommBuilder.setLogFilePath(workingDirectory .. "/uart.log", workingDirectory .. "/rawuart.log")
    -- CommBuilder.setActiveChannelOnOff(1)
    
    local slot_num = tostring(deviceName):sub(-1)
   
    Log.LogInfo("slot_num .. " .. tostring(slot_num))
    local vp_url = string.format("/tmp/dev/DUT1%s",(tonumber(slot_num)))
    vp_url = "uart://" .. vp_url
    local virtualport = string.format("xav://169.254.1.32:780%d:uart_SoC",slot_num + 1)
    Log.LogInfo("vp_url .. " .. vp_url .. " virtualport " .. virtualport)
    local unit_id = string.format("Device-%d",slot_num)

    topology = {
        groups = {
                    {
                      identifier = "Group-0",
                          units = {
                                   {
                                      identifier = unit_id,
                                      unit_transports = {
                                                  {
                                                    url = vp_url,
                                                    metadata ={
                                                          virtualport = virtualport,
                                                          virtualportConfig = {
                                                                loggingfolder = workingDirectory
                                                            }
                                                          }
                                                  }
                                             }
                                }
                        }
                  }
            }
    }
    -- local virtualPort = require "VirtualPort" 
    local virtualPort = Atlas.loadPlugin("VirtualPort")
    virtualPort.setup({
    group_id = "Group-0",
    unit_id = unit_id,
    topology = topology,
    loggingfolder = workingDirectory
    })

    -- local dut = CommBuilder.createEFIPlugin(Group.getDeviceTransport(device_name))
    local channelBuilder = Atlas.loadPlugin("ChannelBuilder")
    local channelPlugin = channelBuilder.createChannelPlugin()
    channelPlugin.setLogFilePath(workingDirectory .. "/dcUART.log")
    local dataChannel = channelPlugin.createDataChannel(vp_url)
    local dut = CommBuilder.createEFIPlugin(dataChannel)
    -- local dut = CommBuilder.createEFIPlugin(vp_url)

    os.execute("sleep " .. tonumber(2))
    xpcall(dut.open,debug.traceback,3)

    CommBuilder.setLogFilePath(workingDirectory .. "/uart_dims1.log", workingDirectory .. "/rawuart_dims1.log")
    local dimension_url = "uart:///dev/cu.usbmodemefidmns" .. string.char((string.byte('A') + slot_num)) .. "11"
    local dimension_dut = CommBuilder.createEFIPlugin(dimension_url)
    
    local resources = Group.getResources()

    local variableTable = Atlas.loadPlugin("TablePlugin")
    variableTable.reset()
    variableTable.setVar("Device_name",deviceName)
    

    return {
        channelPlugin = channelPlugin,
        dut = dut,
        dimension_dut = dimension_dut,
        VirtualPort = virtualPort,
        VariableTable = variableTable,
        SOCParser = socParser,
        MDParser = mdParser,
        SFC = Atlas.loadPlugin("SFC"),
        -- DCSD = Atlas.loadPlugin("DCSD"),
        runtest = Atlas.loadPlugin("RunTest"),
        runShellCmd = Atlas.loadPlugin("RunShellCommand"),
    }
end

function Plugins.shutdownPlugins(device_plugins)
    Log.LogInfo("--------shutdown Plugins-------")
    device_plugins['VirtualPort'].teardown()
    local vt = device_plugins['VariableTable']
    local device_name = vt.getVar('Device_name')
    local dut = device_plugins['dut']
    local status,ret = xpcall(dut.close,debug.traceback)
    Log.LogInfo("$$$$ dut.close status .." .. tostring(status).. "ret " .. tostring(ret))
    local overallResult = Group.getDeviceOverallResult(device_name)
    local slot_num = tonumber(device_name:sub(-1)) + 1
    Log.LogInfo("$$$$ overallResult:" .. tostring(overallResult))
    local fixturePlugin = device_plugins['FixturePlugin']
    if overallResult == Group.overallResult.pass then
        fixturePlugin.led_green_on(slot_num)
    else
        -- Log.LogInfo("[Test Start][main-9999-9999][][<OverallResult> <Result> <>]")
        -- Log.LogInfo("[Test Fail][main-9999-9999][][<OverallResult> <Result> <>]")
        fixturePlugin.led_red_on(slot_num)
    end
    
end


function Plugins.loadGroupPlugins(resources)
    Log.LogInfo("--------loading group plugins-------")
    os.execute("ping 169.254.1.32 -c 1 -t 1")
    os.execute("pkill -9 virtualport")
    local GroupTablePlugin = Atlas.loadPlugin("TablePlugin")
    local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    local fixturePlugin = fixtureBuilder.createFixtureBuilder(0)
    -- fixturePlugin.init()
    -- fixturePlugin.fixture_open()
    Log.LogInfo(resources)
    --local StationInfo = Atlas.loadPlugin("StationInfo")
    --local station_overlay = StationInfo.station_overlay()
    --Log.LogInfo("StationOverlay: " .. station_overlay)
  
    --local site = StationInfo.site()
    --Log.LogInfo("site: " .. site)
    local runShell = Atlas.loadPlugin("RunShellCommand")
    xpcall(runShell.run, debug.traceback,"mkdir -p /vault/Atlas/FixtureLog/Microtest")
    xpcall(runShell.run, debug.traceback,"mkdir -p /vault/Atlas/FixtureLog/RPC_CH1")
    xpcall(runShell.run, debug.traceback,"mkdir -p /vault/Atlas/FixtureLog/RPC_CH2")
    xpcall(runShell.run, debug.traceback,"mkdir -p /vault/Atlas/FixtureLog/RPC_CH3")
    xpcall(runShell.run, debug.traceback,"mkdir -p /vault/Atlas/FixtureLog/RPC_CH4")
    -- local status, resp = xpcall(runShell.run, debug.traceback, "/usr/bin/expect /Users/gdlocal/Library/Atlas2/supportFiles/syncXavierClock.exp")
  
    local InteractiveView = Remote.loadRemotePlugin(resources["InteractiveView"])
    
    return {
        InteractiveView = InteractiveView,
        FixturePlugin = fixturePlugin,
        GroupTablePlugin = GroupTablePlugin,
    }
end

function Plugins.resetFixture(groupPlugins)
    Log.LogInfo("-------- resetFixture -------")
    os.execute("ping 169.254.1.32 -c 1 -t 1")
    os.execute("pkill -9 virtualport")
    -- local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    -- local fixturePlugin = fixtureBuilder.createFixtureBuilder(0)
    local fixturePlugin = groupPlugins['FixturePlugin']
    fixturePlugin.init()
    fixturePlugin.fixture_open()
    -- fixturePlugin.teardown()
    local runShell = Atlas.loadPlugin("RunShellCommand")
    local status, resp = xpcall(runShell.run, debug.traceback, "/usr/bin/expect /Users/gdlocal/Library/Atlas2/supportFiles/clear_all_rpc_log.exp")
    local status, resp = xpcall(runShell.run, debug.traceback, "cp -r /vault/Atlas/FixtureLog/Microtest /vault/Atlas/FixtureLog_BK")
    xpcall(runShell.run, debug.traceback,"rm -r /vault/Atlas/FixtureLog/Microtest/*")
    xpcall(runShell.run, debug.traceback,"rm -r /vault/Atlas/FixtureLog/RPC_CH*/*")
    local status, resp = xpcall(runShell.run, debug.traceback, "/usr/bin/expect /Users/gdlocal/Library/Atlas2/supportFiles/syncXavierClock.exp")
end


function Plugins.shutdownGroupPlugins(groupPlugins)
    -- Group.getDeviceOverallResult(Device_name)
    return {}
end

function Plugins.groupShouldExit(groupPlugins)
    print('exiting current group script')
    return true
end

function writeFile( filePath, content )
    local file = io.open(filePath, "w")
        if file then
            file:write(tostring(content))
            file:close()
            return true
        end
    return false
end

function getLen( tab )
    local count = 0
    for k,v in pairs(tab) do
        count = count + 1
    end
    return count
end

function Plugins.getSlots(groupPlugins)
    -- add code here if want to wait for start button before testing.

    -- pseudo code for calling fixture plugin
    -- fixture_plugin = groupPlugins.fixture
    -- fixture.isReady()   -- block wait until duts are ready to test

    -- demo code to not test slot1
    local ret = {}
    local slot = {}
    local InteractiveView = groupPlugins.InteractiveView
    local GroupTablePlugin = groupPlugins.GroupTablePlugin
    GroupTablePlugin.setVar("restore_delay_count",0)
    GroupTablePlugin.setVar("readyChannelCount",0)
    GroupTablePlugin.setVar("totalChannelCount",0)
    --InteractiveView.splitView(1)
  
    local viewConfig88 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=8, ["input"] = {"slot0", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6", "slot7"} }
    
    local viewConfig84 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=4, ["input"] = {"slot0", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6", "slot7"} }
    
    local viewConfig66 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=6, ["input"] = {"slot0", "slot1", "slot2", "slot3", "slot4", "slot5"} }
    local viewConfig63 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=3, ["input"] = {"slot0", "slot2", "slot1", "slot3", "slot4", "slot5"} }
    local viewConfig55 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=5, ["input"] = {"slot0", "slot1", "slot2", "slot3", "slot4"} }

    local viewConfig44 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=4, ["input"] = {"slot0", "slot1", "slot2", "slot3"} }
                         
    local viewConfig42 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=2, ["input"] = {"slot0", "slot1", "slot2", "slot3"} }
    local viewConfig3 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=3, ["input"] = {"slot0", "slot1", "slot2"} }
                     
    local viewConfig2 = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=2, ["input"] = {"slot0", "slot1"} }
    
    local viewConfig1 = { ["length"] = 17, ["switch"] = {"slot0", "slot1", "slot2", "slot3"} }

    Plugins.resetFixture(groupPlugins)

    local isNeedToShowGroupView = true
    local output = {}

    local loopConfigPath = "/Users/gdlocal/.loopConfig.json"
    local outputPath = "/Users/gdlocal/.outputConfig.json"
    if Plugins.groupShouldExit() then
        local localLoopConfig = comFunc.fileRead(loopConfigPath)
        if localLoopConfig and #localLoopConfig > 0 then
            Log.LogInfo("$$$$$ localLoopConfig " .. tostring(localLoopConfig))
            local status,loopConfig = xpcall(json.decode,debug.traceback,localLoopConfig)
            Log.LogInfo("$$$$$ localLoopConfig decode status " .. tostring(status))
            Log.LogInfo("$$$$$ loopConfig " .. comFunc.dump(loopConfig))
            if status and loopConfig and loopConfig.LoopMax and tonumber(loopConfig.LoopMax) > 1 then
                loopConfig.LoopMax = tonumber(loopConfig.LoopMax) - 1
                localLoopConfig = json.encode(loopConfig)
                writeFile(loopConfigPath,localLoopConfig)
                local outputConfig = comFunc.fileRead(outputPath)
                if outputConfig and #outputConfig > 0 then
                    status,output = xpcall(json.decode,debug.traceback,outputConfig)
                    Log.LogInfo("$$$$$ outputConfig decode status " .. tostring(status))
                    Log.LogInfo("$$$$$ output " .. comFunc.dump(output))
                    if status and output and getLen(output) > 0 then
                        isNeedToShowGroupView = false
                    end
                end
            end
        end
    end

    -- ################### loop control by Plugin.lua   ########################
    if Plugins.loopMax > 1 and Plugins.current_loop_count < Plugins.loopMax then
        -- local isLoopFinished = InteractiveView.isLoopFinished(Group.index - 1)
        -- Log.LogInfo("isLoopFinished " .. tostring(isLoopFinished))
        Plugins.current_loop_count = Plugins.current_loop_count + 1
        -- fixture_plugin = groupPlugins.FixturePlugin
        -- fixture_plugin.fixture_close()
    else
        Plugins.loopMax = 1
        Plugins.current_loop_count = 1
        if isNeedToShowGroupView then
            output = InteractiveView.showGroupView(Group.index - 1, viewConfig44)
            local status,loopConfig = xpcall(InteractiveView.getLoopConfig,debug.traceback)
            if  status and loopConfig then
                Log.LogInfo('loopConfig: ' .. comFunc.dump(loopConfig))
                Plugins.loopMax = tonumber(loopConfig.LoopMax)
                writeFile(outputPath,json.encode(output))
                writeFile(loopConfigPath,json.encode(loopConfig))
                -- Plugins.loops_per_detection = tonumber(loopConfig.LoopMax)
            end
        end

        for i, v in pairs(output) do
            print("########output i = " .. tostring(i) .. " v =" .. tostring(v))
        end

        local units = Group.getSlots()
        -- units = {"slot0", "slot1", "slot2", "slot3"}

        fixture_plugin = groupPlugins.FixturePlugin

        for i, v in ipairs(units) do
            fixture_plugin.led_off(i)
            print("########units i = " .. tostring(i) .. " v =" .. tostring(v))
            if output[v] ~= nil then table.insert(ret, v) end
        end

        Plugins.ret = ret
    end
    fixture_plugin = groupPlugins.FixturePlugin
    fixture_plugin.fixture_close()
    -- ###########################################

    return Plugins.ret
end

return Plugins
