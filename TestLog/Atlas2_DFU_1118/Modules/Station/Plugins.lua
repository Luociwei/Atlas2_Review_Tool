local Plugins = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local json = require("Matchbox/json")
local plist2lua = require("Matchbox/plist2lua")
local STATION_TOPOLOGY = plist2lua.read(string.gsub(Atlas.assetsPath, "Assets", "supportFiles/StationTopology.plist"))

-- uncomment the line below to enable loop per detection.
-- Plugins.loops_per_detection = 1
Plugins.current_loop_count = 1
Plugins.ret = {}

function Plugins.loadPlugins(deviceName, groupPlugins)
    Log.LogInfo("--------loadPlugins-------")
    -- deviceName = Device_slot#
    local group_id = Group.index
    local slot_id = tonumber(tostring(deviceName):sub(-1))
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)

    local mdParser = Atlas.loadPlugin("MDParser")
    --mdParser.init("/Users/gdlocal/Library/Atlas2/Assets/parseDefinitions")

    -- load VirtualPort Plugin
    local vp_url = STATION_TOPOLOGY["groups"][group_id]["units"][slot_id]["unit_transports"][1]["url"]
    local virtualPort = loadVirtualPortPlugin(group_id, slot_id, STATION_TOPOLOGY, workingDirectory)

    -- load CommBuilder plugin
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    local flitetCharacter = {}
    for i = 128, 255 do
        -- from 80 to FF
        table.insert(flitetCharacter, string.format("%2x", i))
    end
    CommBuilder.setReadFiltersHex(flitetCharacter)

    -- Create base channel from CommBuilder
    local baseChannel = CommBuilder.createBaseChannel(vp_url)

    -- load channelPlugin
    local channelBuilder = Atlas.loadPlugin("SMTDataChannel")
    local channelPlugin = channelBuilder.createChannelPlugin()
    channelPlugin.setLogFilePath(workingDirectory .. "/uart.log")
    channelPlugin.setLegacyLogMode(1)

    -- Create a data channel with hang detection ability.
    local dataChannel = channelPlugin.createDataChannel(baseChannel)

    -- load dut plugin
    -- Pass data channel with hang detection ability as base channel to CommBuilder
    local dut = CommBuilder.createEFIPlugin(dataChannel)

    return {
        channelPlugin = channelPlugin,
        dut = dut,
        VirtualPort = virtualPort,
        MDParser = mdParser,
        SFC = Atlas.loadPlugin("SFC"),
        USBFS = Atlas.loadPlugin("USBFS"),
        TimeStamp = Atlas.loadPlugin("TimeStamp"),
    }
end

function loadVirtualPortPlugin(group_id, slot_id, topology, workingDirectory)
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
    if device_plugins['VirtualPort'] ~= nil then
        device_plugins['VirtualPort'].teardown()
    end
    if device_plugins['dut'] ~= nil then
        local dut = device_plugins['dut']
        local status, ret = xpcall(dut.close, debug.traceback)
        Log.LogInfo("$$$$ dut.close status .." .. tostring(status) .. "ret " .. tostring(ret))
    end
    Log.LogInfo("$$$$ dut.close status ")

end

function Plugins.loadGroupPlugins(resources)
    Log.LogInfo("--------loading group plugins-------")
    local InteractiveView = Remote.loadRemotePlugin(resources["InteractiveView"])

    local fixturePlugin = nil
    local status, ret = xpcall(loadFixturePluginAndInitFixture, debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "init Xavier failed...\r\n初始化 Xavier 失败!!!", "red")
        error(ret)
    else
        fixturePlugin = ret
        clearGroupViewMessage(InteractiveView)
    end

    local dockchannel = nil
    local status, ret = xpcall(loadDockChannelPluginAndInit, debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "init Dock Channel failed ...\r\n初始化 Dock Channel失败!!!", "red")
        error(ret)
    else
        dockchannel = ret
        clearGroupViewMessage(InteractiveView)
    end

    local eowyn = nil
    local status, ret = xpcall(loadEowynPluginAndInit, debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "init Eowyn failed...\r\n初始化 Eowyn Board 失败!!!", "red")
        error(ret)
    else
        eowyn = ret
        clearGroupViewMessage(InteractiveView)
    end

    return {
        InteractiveView = InteractiveView,
        FixturePlugin = fixturePlugin,
        DockChannel = dockchannel,
        Eowyn = eowyn,
    }
end

function loadFixturePluginAndInitFixture()
    Log.LogInfo("---loadFixturePluginAndInitFixture--" .. tostring(Group.index - 1))
    local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    local fixturePlugin = fixtureBuilder.createFixtureBuilder(0)
    fixturePlugin.init()
    return fixturePlugin
end

function loadDockChannelPluginAndInit()
    Log.LogInfo("--loadDockChannelPluginAndInit--")
    local dockchannel = Atlas.loadPlugin("DockChannel")
    dockchannel.openDevice(STATION_TOPOLOGY["groups"][Group.index]["xavier_ip1"], tonumber(STATION_TOPOLOGY["groups"][Group.index]["dockChannelSettingPort"]), tonumber(STATION_TOPOLOGY["groups"][Group.index]["dockChannelPort"]))
    local units = Group.getSlots()
    for i, v in ipairs(units) do
        dockchannel.creatLogFilePath(STATION_TOPOLOGY["groups"][Group.index][string.format("dockChannelSettingPath%d", i)], i, 31336)
        dockchannel.creatLogFilePath(STATION_TOPOLOGY["groups"][Group.index][string.format("dockChannelPath%d", i)], i, 31337)
    end
    dockchannel.initdevice()
    return dockchannel
end

function loadEowynPluginAndInit()
    Log.LogInfo("--loadEowynPluginAndInit--")
    local eowynPlugin = Atlas.loadPlugin("Eowyn")
    executeShellCommand("mkdir " .. STATION_TOPOLOGY["groups"][Group.index]["eowynLogFolder"])
    eowynPlugin.connectEowyn(STATION_TOPOLOGY["groups"][Group.index]["eowyn_ip"], STATION_TOPOLOGY["groups"][Group.index]["eowynLogPath"])
    eowynPlugin.led_init()
    eowynPlugin.fixture_open()
    return eowynPlugin
end

function showGroupViewMessage(InteractiveView, message, messageColor)
    local groupIndex = Group.index - 1
    InteractiveView.showGroupView(groupIndex, { ["message"] = message, ["messageColor"] = messageColor, ["messageFont"] = 18, ["messageAlignment"] = 0 })
end

function clearGroupViewMessage(InteractiveView)
    local groupIndex = Group.index - 1
    InteractiveView.showGroupView(groupIndex, { ["message"] = " ", ["messageColor"] = "blue", ["messageFont"] = 18, ["messageAlignment"] = 0 })
end

function executeShellCommand(command)
    local status = os.execute(command)
    Log.LogInfo("Run command : " .. command .. "\n status: " .. tostring(status))
end

function Plugins.groupStart(groupPlugins)

end

function Plugins.groupStop(groupPlugins)
    Log.LogInfo("-Plugins.groupStop start-")
    local fixturePlugin = groupPlugins['FixturePlugin']
    local status, ret = xpcall(fixturePlugin.init, debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "init fixture failed...\r\n初始化 Xavier 失败!!!", "red")
        error(ret)
    end

    local eowynPlugin = groupPlugins['Eowyn']
    local status, ret = xpcall(eowynPlugin.fixture_open, debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "open fixture failed...\r\n打开 Fixture 失败!!!", "red")
        error(ret)
    end
    Log.LogInfo("-Plugins.groupStop stop-")
end

function Plugins.shutdownGroupPlugins(groupPlugins)
    local fixture_plugin = groupPlugins.FixturePlugin
    fixture_plugin.teardown()

    groupPlugins.DockChannel.teardown()
    Log.LogInfo("$$$$ DockChannel teardown ")
    return {}
end

function Plugins.groupShouldExit(groupPlugins)
    Log.LogInfo('exiting current group script')
    return true
end

function Plugins.getSlotsByInteractiveView(groupPlugins, viewConfig)
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

    local fixture_plugin = groupPlugins.Eowyn
    for i, v in ipairs(units) do
        Log.LogInfo("########units i = " .. tostring(i) .. " v =" .. tostring(v))
        fixture_plugin.led_off(i)
        if output[v] ~= nil then
            table.insert(ret, v)
        end
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
                              ["column"] = 4, ["input"] = { "slot1", "slot2", "slot3", "slot4" } }
    local viewConfigSwitch = { ["length"] = 17, ["switch"] = { "slot1", "slot2", "slot3", "slot4" } }
    Plugins.getSlotsByInteractiveView(groupPlugins, viewConfigInput)
    local fixturePlugin = groupPlugins['FixturePlugin']
    for i = 1, 4 do
        local ip = "169.254.1.3" .. tostring(i + 1)
        local response = fixturePlugin.fixture_command("get_xavier_ip", 5000, i)
        print(" ip --> " .. ip)
        if response ~= ip then
            showGroupViewMessage(InteractiveView, "PRCServer is not ready ...\r\n连接 Xavier 失败!!!", "red")
            error("PRCServer is not ready ...\r\n连接 Xavier 失败!!!")
        end
    end
    local eowynPlugin = groupPlugins['Eowyn']
    local status, ret = xpcall(eowynPlugin.fixture_close, debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "close fixture failed ...", "red")
        error(ret)
    else
        clearGroupViewMessage(InteractiveView)
    end

    return Plugins.ret
end

return Plugins
