local func = {}
local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")

function func.execute( cmd )
    local file = assert(io.popen(cmd, 'r'))
    local data = assert(file:read("*all"))
    file:close()
    return data
end

return func