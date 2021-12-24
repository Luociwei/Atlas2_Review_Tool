local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")

function unitSetup(device_name, slot_info, groupPlugins)
    local Log = require("Matchbox/logging")
    local userOverride = require("Station/Plugins")
    local unitSetupInner = function ()
        Log.LogInfo("Constructing testableDevice with name " .. device_name)
        Group.startDevice(device_name, slot_info)
        dutPath = Group.getDeviceTransport(device_name)
        local device_plugins = userOverride.loadPlugins(device_name, groupPlugins)
        Log.LogInfo("Unit setup successful for " .. device_name)
        pluginStore[device_name] = device_plugins
    end
    retval = true
    comFunc.try(unitSetupInner,
        function (erawr)
            Log.LogError("Failed to initialize " .. device_name .. "due to error " .. erawr)
            retval = false
    end)
    return retval
end

-- Running Teardown.csv in DAG for all devices.
function runTeardownCSV(index, allGlobals, allConditions, limitsTable)
    local seqFunc = require("Matchbox/SequenceControl")
    Log.LogDebug('Running Teardown.csv')

    local item = {
        TestName = "Teardown",
        testName = "Teardown",
        limits = limitsTable,
        condition = "",
        testTech = "Teardown",
        mainIndex = index,
        loopTimes = 1,
        loopTurn = 1,
        nameSuffix = "",
        Cof = "COF"
    }
    for _, device in ipairs(Group.allDevices()) do
        local dag = Group.scheduler(device, pluginStore[device])
        dag.enableExitOnAmIOkay()

        local globals = allGlobals[device]
        local conditions = allConditions[device]
        seqFunc.scheduleTests(dag, "Matchbox/Teardown.lua", {item},
                              globals, conditions,
                              comFunc.tableKeys(pluginStore[device]))
    end
    Group.execute()
end

function unit_teardown(device_name)
    local userOverride = require 'Station/Plugins'
    local unit_teardown__inner = function ()
        -- TODO protection for potential risk: user shutdowns group plugins at device teardown
        userOverride.shutdownPlugins(pluginStore[device_name])
        pluginStore[device_name] = nil
        Log.LogInfo("Deconstructing testable device plugins " .. device_name)
        Group.stopDevice(device_name)
    end
    retval = true
    comFunc.try(unit_teardown__inner,
        function (erawr)
            Log.LogError("Unit Teardown failure:" .. erawr)
            retval = false
    end)
    return retval
end

function executeItems(action, mainItems, allGlobals, allConditions)
    local seqFunc = require("Matchbox/SequenceControl")
    local lastResolvables = {}
    for _, device in ipairs(Group.allDevices())
    do
        local dag = Group.scheduler(device, pluginStore[device])
        -- remove Atlas threadpool size limit to support 4+ parallel actions
        dag.clearThreads()
        dag.enableExitOnAmIOkay()

        -- unmanage all plugins to run in parallel.
        -- Matchbox pass all plugins to every test and here any test can run in parallel
        -- as long as every plugins are thread safe when they are used in parallel test
        -- we are good here.
        for pluginName, _ in pairs(pluginStore[device]) do
            dag.unmanage(pluginName)
        end

        local globals = allGlobals[device]
        local conditions = allConditions[device]

        lastResolvables[device] = seqFunc.scheduleTests(dag,action,mainItems,globals,conditions,comFunc.tableKeys(pluginStore[device]))
    end

    local ret = Group.execute()

    local updatedAllGlobals = {}
    local updatedAllConditions = {}
    for _, device in ipairs(Group.allDevices()) do
        if ret.checkSuccessful(device) == true then
            -- get updated globals and conditions after group execution
            -- TODO: need to handle disabled slots here.
            local globals, conditions = lastResolvables[device].returnValue()
            updatedAllGlobals[device] = globals
            updatedAllConditions[device] = conditions
        else
            local failMsg = ret.deviceError(device)
            Log.LogError('executItems: tests interrupted by error; msg=' .. failMsg)
        end
    end

    return updatedAllGlobals, updatedAllConditions
end

-- return slots to test, allow user to filter units or control test start
-- for example, selected units to retest in a panel, or start with a start button.
-- @param groupPlugins: group plugin instances, possibly used during unit detection.
-- user overrided getSlots() needs to call Group.getSlots() inside and return slots to test.
function unitDetection(groupPlugins)
    -- Wait for new unit to start the device
    local userOverride = require("Station/Plugins")
    if userOverride.getSlots then
        return userOverride.getSlots(groupPlugins)
    else
        return Group.getSlots()
    end
end

function runInitTable(globals, conditions)
    local item = {
        TestName = "Init",
        testName = "Init",
        limits = limitsTable,
        condition = "",
        testTech = "Init",
        mainIndex = 0,
        loopTimes = 1,
        loopTurn = 1,
        nameSuffix = "",
        Cof = "COF"
    }
    initAction = "Matchbox/Init.lua"
    return executeItems(initAction, {item}, globals, conditions)

end

function matchboxMain(groupPlugins, filteredMainCSVTable, limitsTable)
    local Log = require("Matchbox/logging")
    -- unit & resource detection
    local slots = unitDetection(groupPlugins)

    local userOverride = require("Station/Plugins")

    -- loop per detection: loop times from userOverride.loops_per_detection
    -- the code below also works when user input a 'false' but user shouldn't do that;
    -- and semantically no loop (just run once) seems to match expectation.
    local loops_per_detection = userOverride.loops_per_detection or 1

    -- loops_per_detection should be an integer.
    -- check if number here; ignore the case when user input float like 3.5... user shouldn't do that.
    -- if really to ensure integer, need to add `math.floor(i) == i`
    -- which involes `math` lib that is used nowhere but here.
    if type(loops_per_detection) ~= 'number' then
        error('loops_per_detection:' .. tostring(loops_per_detection) .. ' should be integer.')
    end

    local loopTurn = 1
    repeat
        if loops_per_detection > 1 then Log.LogInfo('Loops per detection: loop ' .. loopTurn) end
        if matchboxTestMain(slots, groupPlugins, filteredMainCSVTable, limitsTable) == false
        then
            Log.LogError("Something terrible happened !!!")
            break
        end
        loopTurn = loopTurn + 1
    until loopTurn > loops_per_detection
end

function matchboxTestMain(slots, groupPlugins,filteredMainCSVTable,limitsTable)
    -- generate a local copy of the CSV table to ensure it is not modified when running in 2nd loop.
    local enabledTests = comFunc.clone(filteredMainCSVTable)
    pluginStore = {}
    local allGlobals = {}
    local allConditions = {}

    for _, slot in ipairs(slots)
    do
        local device_name = "Device_" .. slot
        unitSetup(device_name, slot, groupPlugins)
        for pluginName, plugin in pairs(groupPlugins) do
            if pluginStore[device_name][pluginName] ~= nil then
                error("Duplicate plugin name " .. pluginName .. " between group and unit")
            end
            pluginStore[device_name][pluginName] = plugin
        end
        -- setup initial globals and conditions table
        -- Store default value in global table for later using in CSV
        allGlobals[device_name] = {TRUE=true, FALSE=false}
        allConditions[device_name] = {didSOF="FALSE", didFail="FALSE", Poison="FALSE"}
    end

    -- run init table
    allGlobals, allConditions = runInitTable(allGlobals, allConditions)

    -- run test table: expand main csv into runnable test items
    -- and feed to executeItems()
    local mainItems = {}
    local itemNameList = {}
    for index, test in ipairs(enabledTests)
    do
        test.mainIndex = index
        -- get limits for current main item
        test.limits = limitsTable
        test.testName = test.TestName
        test.condition = test.Condition
        test.testTech = test.Technology
        test.loopTimes = 1
        test.loopTurn = 1
        -- allow duplicate test in Main.csv
        if itemNameList[test.TestName] == nil then
            itemNameList[test.TestName] = 1
            test.nameSuffix = ""
        else
            itemNameList[test.TestName] = itemNameList[test.TestName] + 1
            test.nameSuffix = "_"..itemNameList[test.TestName]
        end

        if test.Thread == "" then test.Thread = nil end
        if test.Loop ~= "" then
            test.loopTimes = tonumber(test.Loop)
        end
        -- default COF value
        test.cofFlag = "COF"
        if test.Cof ~= "" then test.cofFlag = test.CoF end

        mainItems[index] = test
    end

    allGlobals, allConditions = executeItems("Matchbox/Tech.lua", mainItems, allGlobals, allConditions)

    -- teardown device
    -- run Teardown.csv in DAG
    runTeardownCSV(#mainItems, allGlobals, allConditions, limitsTable)
    for _, device_name in ipairs(Group.allDevices())
    do
        -- teardown unit plugins
        unit_teardown(device_name)
        Log.LogInfo(device_name .. " unit_teardown")
    end
end

function main()
    -- load group plugins
    local userOverride = require("Station/Plugins")
    local groupPlugins = {}
    if userOverride.loadGroupPlugins ~= nil then
        local res = Group.getResources()
        groupPlugins = userOverride.loadGroupPlugins(res)
    end
    groupPlugins["Regex"] = Atlas.loadPlugin("Regex")
    groupPlugins["RunShellCommand"] = Atlas.loadPlugin("RunShellCommand")
    -- csv syntax check
    Log.LogInfo("Checking CSV syntax..")
    local syntaxCheck = require("Matchbox/CheckCSVSyntax")
    syntaxCheck.checkCSVSyntax(Atlas.assetsPath)
    -- load Main.csv/Limits.csv
    local CSVLoad = require("Matchbox/CSVLoad")
    local mainCSVTable = CSVLoad.loadItems(Atlas.assetsPath.."/Main.csv")
    local testMode = Group.isAudit() and "Audit" or "Production"
    local filteredMainCSVTable = CSVLoad.filterItems(mainCSVTable,testMode)
    local limitsTable = CSVLoad.loadLimits(Atlas.assetsPath.."/Limits.csv")

    local groupShouldExit = userOverride.groupShouldExit or function() return false end

    repeat
        if matchboxMain(groupPlugins,filteredMainCSVTable,limitsTable) == false
        then
            Log.LogError("Something terrible happened !!!")
            break
        end

        -- move sleep here to ensure all devices finish matchboxMain()
        if dutPath:match("fake%-path") ~= nil then
            comFunc.sleep(2000)
        end
    until groupShouldExit(groupPlugins) == true

    if userOverride["shutdownGroupPlugins"] ~= nil then
        userOverride["shutdownGroupPlugins"](groupPlugins)
    end
end

