-------------------------------------------------------------------
----***************************************************************
----DUT Communication Mux Functions
----Created at: 08/26/2020
----Author: Roy Yang/Bin Zhao
----***************************************************************
-------------------------------------------------------------------
local Log = require("Matchbox/logging")
local dutCmd = require("Tech/DUTCmd")

local dut = {}


-- Open dut channel
-- @param params(table): table of csv line
-- @return: open result(true/false)
function dut.open(params)
    
    local channel_to_open = params.AdditionalParameters['channel']
    local channel = Device.getPlugin(channel_to_open)
    local channel_query_name = constructChannelName(params.thread)
    if channel then
        
        return channel.open()
    else
        error(channel_to_open .. "not exists")
    end
end

-- Close dut channel
-- @param params(table): table of csv line
-- @return: close result(true/false)
function dut.close(params)
    local channel_to_open = params.AdditionalParameters['channel']
    local channel
    if channel_to_open then
        channel = Device.getPlugin(channel_to_open)
    else
        channel = Device.getPlugin(constructChannelName(params.thread))
    end
    if channel then
        return channel.close()
    else
        error(channel_to_open .. "not exists")
    end
end



function dut.sendCmd(params)
    local dut = Device.getPlugin("dut")
    resp = dut.send(params.Commands)
    print("diags send CMD" .. tostring(resp))
    return resp
end

-- function dut.sendAndParseCommandWithPlugin( params )
--     print("enter sendAndParseCommandWithPlugin>>>")
--     return dutCmd.sendAndParseCommandWithPlugin(params)
    
-- end


return dut
