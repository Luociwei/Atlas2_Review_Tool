--   env.lua
--   Torchwood

--   Created by Roy Yang on 2020/7/13.
--   Copyright © 2020 HWTE. All rights reserved.


local comFunc = require("Matchbox/CommonFunc")
-- local run = require('RunShellCommand')

env = {}

-- env.HOME = comFunc.trim(run.run("echo ~").output)
env.ASSETS_PATH = Group and Group.assetsPath or Atlas.assetsPath
env.WORKING_DIRECTORY = env.ASSETS_PATH .. "/../"
env.CONFIG_PATH = env.WORKING_DIRECTORY .. "/Config"
env.ACTIONS_PATH = env.WORKING_DIRECTORY .. "/Actions"
env.MODULES_PATH = env.WORKING_DIRECTORY .. "/Modules"
env.PLUGINS_PATH = env.WORKING_DIRECTORY .. "/Plugins"
env.SEQUENCES_PATH = env.WORKING_DIRECTORY .. "/Sequences"
env.MD_PATH = env.ASSETS_PATH .. "/parseDefinitions"
env.ATTRIBUTE_FILE = env.ASSETS_PATH .. "/attributes.plist"
env.INFO_AFFIX = "------------"
env.ERROR_AFFIX = "!!!!!!!!!!!!"
env.DEBUG_AFFIX = "$$$$$$$$$$$$"

env.COF = "cof"
env.SOF = "sof"
env.WAIVED = "waived"

env.DISABLE = "1"
env.ENABLE = ""

env.DISABLED_DEVICE = "DISABLED%-DEVICE"
env.DATA_CHANNEL = "_data_channel"

return env
