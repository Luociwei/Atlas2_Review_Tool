-- Teardown.lua
-- run Teardown.csv in dag.

function runTeardown(itemInfo, globals, conditions)
    local seqFunc = require("Matchbox/SequenceControl")
    local Log = require("Matchbox/logging")
    itemInfo.testTech = "Teardown"
    itemInfo.process = "Teardown"
    itemInfo.logID = "Teardown"
    local comFunc = require("Matchbox/CommonFunc")
    local teardownSequence = comFunc.techSequence(Atlas.assetsPath .. "/Teardown.csv")
    Log.LogInfo("Teardown sequence: ")
    Log.LogInfo(comFunc.dump(teardownSequence))
    for index,name in ipairs(teardownSequence) do
        itemInfo.mainIndex = index
        itemInfo.techIndex = index
        itemInfo.testName = name
        Device.updateProgress(itemInfo.testName)
        seqFunc.executeTech(itemInfo, globals, conditions)
    end
    return globals,conditions
end

function main(itemInfo, globals, conditions)
	return runTeardown(itemInfo, globals, conditions)
end
