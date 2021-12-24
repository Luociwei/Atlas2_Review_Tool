Common = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")
local Record = require("Matchbox/record")

local SKIP_FILE_LIST = { "Common.lua", "WriteLog.lua", "Display.lua", "BatteryCharger.lua", "Orion.lua", "PMU.lua", "SOC.lua", "Speaker.lua", "Touch.lua" }
--local SKIP_FILE_LIST = {"Common.lua"}
local techPath = string.gsub(Atlas.assetsPath, "Assets", "Modules/Tech")
local runShellCommand = Atlas.loadPlugin('RunShellCommand')
local techFiles = runShellCommand.run("ls " .. techPath).output
Log.LogInfo("file list: ", techFiles)
local techFileList = comFunc.splitBySeveralDelimiter(techFiles, '\n\r')
for i, file in ipairs(techFileList) do
    if not comFunc.hasVal(SKIP_FILE_LIST, file) then
        Log.LogInfo("file: ", file)
        local requirePath = "Tech/" .. file:match("(.*)%.lua")
        local lib = require(requirePath)
        for name, func in pairs(lib) do
            Common[name] = function(params)
                params.Commands = params.varSubCmd()
                params.AdditionalParameters = params.varSubAP()
                return func(params)
            end
        end
    end
end

return Common

