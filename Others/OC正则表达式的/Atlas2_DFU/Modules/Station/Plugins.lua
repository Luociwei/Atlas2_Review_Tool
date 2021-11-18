local Plugins = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local json = require("Matchbox/json")
local plist2lua = require("Matchbox/plist2lua")

local FIXTURE_LOG_DIRS = { "/vault/Atlas/FixtureLog/Microtest",
                          "/vault/Atlas/FixtureLog/RPC_CH1",
                          "/vault/Atlas/FixtureLog/RPC_CH2",
                          "/vault/Atlas/FixtureLog/RPC_CH3",
                          "/vault/Atlas/FixtureLog/RPC_CH4" }
local PARSE_DEFINITIONS_PATH = "/Users/gdlocal/Library/Atlas2/Assets/parseDefinitions"
local STATION_TOPOLOGY = plist2lua.read("/Users/gdlocal/Library/Atlas2/supportFiles/StationTopology.plist")
local XAVIER_IP = STATION_TOPOLOGY["groups"][Group.index]["xavier_ip"]
local DEVICES_NUM = 4

-- uncomment the line below to enable loop per detection.
-- Plugins.loops_per_detection = 1
Plugins.current_loop_count = 1
Plugins.ret = {}

function Plugins.loadPlugins(deviceName , groupPlugins)
    -- deviceName = Device_slot#
    local group_id = Group.index
    local slot_id = tonumber(tostring(deviceName):sub(-1))
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)

    -- load MDParser Plugin
    local mdParser = Atlas.loadPlugin("MDParser")
    mdParser.init(PARSE_DEFINITIONS_PATH)

    -- load VirtualPort Plugin
    local vp_url = STATION_TOPOLOGY["groups"][group_id]["units"][slot_id]["unit_transports"][1]["url"]
    local virtualPort = loadVirtualPortPlugin(group_id, slot_id, STATION_TOPOLOGY, workingDirectory)

    -- load dut plugin and channelPlugin
    local logFilePath = workingDirectory .. "/uart.log"
    local dut, channelPlugin = loadEFIPluginAndChannelPlugin(vp_url, logFilePath)

    -- load dimension dut plugin
    local url_dmns = "uart:///dev/cu.usbmodemefidmns" .. string.char((string.byte('A') + slot_id - 1)) .. "11"
    local logFilePath_dmns = workingDirectory .. "/uart_dmns.log"
    local dimension_dut = loadEFIPluginAndChannelPlugin(url_dmns, logFilePath_dmns)
    
    -- load DCSD and DCSD progress plugin
    local DCSD = Atlas.loadPlugin("DCSD")
    local restoreProgressPlugin = DCSD.get_progress_plugin()

    return {
        mutex = Atlas.loadPlugin("MutexPlugin"),
        channelPlugin = channelPlugin,
        dut = dut,
        dimension_dut = dimension_dut,
        VirtualPort = virtualPort,
        MDParser = mdParser,
        SFC = Atlas.loadPlugin("SFC"),
        DCSD = DCSD,
        restoreProgressPlugin = restoreProgressPlugin,
        RunTest = Atlas.loadPlugin("RunTest"),
        Utilities = Atlas.loadPlugin("Utilities"),
    }
end

function loadEFIPluginAndChannelPlugin( url, logFilePath )
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    local channelBuilder = Atlas.loadPlugin("SMTDataChannel")
    local baseChannel = CommBuilder.createBaseChannel(url)
    local channelPlugin = channelBuilder.createChannelPlugin()
    channelPlugin.setLogFilePath(logFilePath)
    channelPlugin.setLegacyLogMode(1)
    local dataChannel = channelPlugin.createDataChannel(baseChannel)
    local dut = CommBuilder.createEFIPlugin(dataChannel)
    return dut, channelPlugin
end

function loadVirtualPortPlugin( group_id, slot_id, topology, workingDirectory )
    local group_identifier = STATION_TOPOLOGY["groups"][group_id]["identifier"]
    local unit_identifier = STATION_TOPOLOGY["groups"][group_id]["units"][slot_id]["identifier"]
    Log.LogInfo("$$$$ topology " .. comFunc.dump(topology))
    local virtualPort = Atlas.loadPlugin("VirtualPort")
    virtualPort.setup({
        group_id = group_identifier,
        unit_id = unit_identifier,
        topology = topology,
        loggingfolder = workingDirectory
    })
    return virtualPort
end

function Plugins.shutdownPlugins(device_plugins)
    Log.LogInfo("--------shutdown Plugins-------")
    device_plugins['VirtualPort'].teardown()
    local dut = device_plugins['dut']
    local mutex = device_plugins['mutex']
    local status,ret = xpcall(dut.close,debug.traceback)
    Log.LogInfo("$$$$ dut.close status .." .. tostring(status).. "ret " .. tostring(ret))
    local status,ret = xpcall(mutex.reset,debug.traceback)
    Log.LogInfo("$$$$ mutex.reset status .." .. tostring(status).. "ret " .. tostring(ret))
end

function Plugins.loadGroupPlugins(resources)
    Log.LogInfo("--------loading group plugins-------")
    local InteractiveView = Remote.loadRemotePlugin(resources["InteractiveView"])
    pingIP(XAVIER_IP)
    createDirs(FIXTURE_LOG_DIRS)
    local fixturePlugin = nil
    local status,ret = xpcall(loadFixturePluginAndInitFixture,debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "init fixture failed ...\r\n治具初始化失败 ...", "red")
        error(ret)
    else
        fixturePlugin = ret
        clearGroupViewMessage(InteractiveView)
    end

    return {
        InteractiveView = InteractiveView,
        FixturePlugin = fixturePlugin,
    }
end

function loadFixturePluginAndInitFixture( )
    local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    local fixturePlugin = fixtureBuilder.createFixtureBuilder(Group.index-1)
    fixturePlugin.reset()
    return fixturePlugin
end


function showGroupViewMessage( InteractiveView, message, messageColor)
    local groupIndex = Group.index - 1
    InteractiveView.showGroupView(groupIndex, { ["message"] = message, ["messageColor"]= messageColor, ["messageFont"]=18, ["messageAlignment"]=0} )
end

function clearGroupViewMessage( InteractiveView )
    local groupIndex = Group.index - 1
    InteractiveView.showGroupView(groupIndex, { ["message"] = " ", ["messageColor"]= "blue", ["messageFont"]=18, ["messageAlignment"]=0} )
end

function pingIP( xavierIP )
    local pingCmd = "ping " .. xavierIP .. " -c 1 -t 1"
    executeShellCommand(pingCmd)
end

function createDirs( directories )
    for _,dir in ipairs(directories) do
        local createDirCmd = "mkdir -p " .. dir
        executeShellCommand(createDirCmd)
    end
end

function runExpectScript( scriptPath )
    local command = "/usr/bin/expect " .. scriptPath
    executeShellCommand(command)
end

function clearAndBackupFixtureLog( )
    executeShellCommand("cp -r /vault/Atlas/FixtureLog/Microtest /vault/Atlas/FixtureLog_BK")
    executeShellCommand("rm -r /vault/Atlas/FixtureLog/Microtest/*")
    executeShellCommand("rm -r /vault/Atlas/FixtureLog/RPC_CH*/*")
end

function executeShellCommand( command )
    local status = os.execute(command)
    Log.LogInfo("Run command : " .. command .. "\n status: " .. tostring(status))
end

function Plugins.groupStart( groupPlugins )
    local fixturePlugin = groupPlugins['FixturePlugin']
    for i=1,DEVICES_NUM do
        fixturePlugin.reset_xavier_log(i)
        fixturePlugin.led_off(i)
    end
end

function Plugins.groupStop( groupPlugins )
    clearAndBackupFixtureLog()
    local fixturePlugin = groupPlugins['FixturePlugin']
    local status,ret = xpcall(fixturePlugin.reset,debug.traceback)
    local InteractiveView = groupPlugins.InteractiveView
    if not status then 
        showGroupViewMessage(InteractiveView, "reset fixture failed ...\r\n治具初始化失败 ...", "red")
        error(ret)
    end
    local status,ret = xpcall(fixturePlugin.fixture_open,debug.traceback)
    if not status then 
        showGroupViewMessage(InteractiveView, "open fixture failed ...\r\n治具打开失败 ...", "red")
        error(ret)
    end
end

function Plugins.shutdownGroupPlugins(groupPlugins)
    local fixture_plugin = groupPlugins.FixturePlugin
    fixture_plugin.teardown()
    return {}
end

function Plugins.groupShouldExit(groupPlugins)
    Log.LogInfo('exiting current group script')
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

function Plugins.getSlotsByInteractiveView( groupPlugins , viewConfig)
    local ret = {}
    local slot = {}
    local InteractiveView = groupPlugins.InteractiveView
    local isLoopFinished = InteractiveView.isLoopFinished(Group.index - 1)
    --InteractiveView.splitView(1)
    Log.LogInfo("isLoopFinished " .. tostring(isLoopFinished))
    local output = InteractiveView.showGroupView(Group.index - 1, viewConfig)
    for i, v in pairs(output) do
        Log.LogInfo("########output i = " .. tostring(i) .. " v =" .. tostring(v))
    end

    local units = Group.getSlots()
    -- units = {"slot0", "slot1", "slot2", "slot3"}

    local fixture_plugin = groupPlugins.FixturePlugin
    for i, v in ipairs(units) do
        fixture_plugin.led_off(i)
        Log.LogInfo("########units i = " .. tostring(i) .. " v =" .. tostring(v))
        if output[v] ~= nil then table.insert(ret, v) end
    end
    Plugins.ret = ret
    return Plugins.ret
end


function Plugins.getSlots(groupPlugins)
    -- add code here if want to wait for start button before testing.
    -- demo code to not test slot1
    local InteractiveView = groupPlugins.InteractiveView
    --InteractiveView.splitView(1)
    local viewConfigInput = { ["length"] = 17, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=4, ["input"] = {"slot1", "slot2", "slot3", "slot4"} }
    local viewConfigSwitch = { ["length"] = 17, ["switch"] = {"slot1", "slot2", "slot3", "slot4"} }
    Plugins.getSlotsByInteractiveView(groupPlugins, viewConfigInput)
    executeShellCommand("pkill -9 virtualport")
    local fixturePlugin = groupPlugins['FixturePlugin']
    local status,ret = xpcall(fixturePlugin.fixture_close,debug.traceback)
    if not status then 
        showGroupViewMessage(InteractiveView, "close fixture failed ...\r\n治具关闭失败 ...", "red")
        error(ret)
    else
        clearGroupViewMessage(InteractiveView)
    end

    return Plugins.ret
end

return Plugins
