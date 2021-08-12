local Log = require("Matchbox/logging")
local comFunc = require("Matchbox/CommonFunc")

local versions
return function()
    if versions == nil then
        versions = {}
        -- local path = "/Users/gdlocal/Library/Atlas2/supportFiles/VersionCompare.txt"
        local path = "/Users/gdlocal/Public/supportFiles/VersionCompare.txt"
        local content = comFunc.fileRead(path)
        local rows = comFunc.splitString(content, '\n')
        local key
        local index = 1
        for _, row in ipairs(rows) do
            local linearr = comFunc.splitString(row, ':')
            if #linearr == 2 then
                key = linearr[1]
                if linearr[2] ~= "" then
                    versions[key] = comFunc.trim(linearr[2])
                else
                    versions[key] = {}
                    index = 1
                end
            elseif row ~= "" then
                versions[key][index] = comFunc.trim(row)
                index = index + 1
            end
        end
        -- comFunc.exLog("VersionCompare:  " .. comFunc.dump(versions) .. '\n')
    end
    return versions
end