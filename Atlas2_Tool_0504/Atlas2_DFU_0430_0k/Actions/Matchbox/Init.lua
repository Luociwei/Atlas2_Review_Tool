-- Init.lua, action to run Init.csv for each device.

function runInit(itemInfo, globals, conditions)
    local seqFunc = require("Matchbox/SequenceControl")
    local Log = require("Matchbox/logging")
    itemInfo.testTech = "Init"
    itemInfo.process = "Init"
    itemInfo.logID = "Init"
    local comFunc = require("Matchbox/CommonFunc")
    local initSequence = comFunc.techSequence(Atlas.assetsPath .. "/Init.csv")
    Log.LogInfo("Init sequence: ")
    Log.LogInfo(comFunc.dump(initSequence))
    for index,name in ipairs(initSequence) do
        itemInfo.mainIndex = index
        itemInfo.techIndex = index
        itemInfo.testName = name
        Device.updateProgress(itemInfo.testName)
        seqFunc.executeInit(itemInfo, globals, conditions)
    end
    return globals, conditions
end

function main(itemInfo,globals,conditions)
    globals,conditions = runInit(itemInfo, globals, conditions)
    return globals, conditions
end
