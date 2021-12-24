-------------------------------------------------------------------
----***************************************************************
----Condition plugins and conditions
----***************************************************************
-------------------------------------------------------------------

local Condition = {}
local comFunc = require("Matchbox/CommonFunc")
local ftcsv = require("Matchbox/ftcsv")

local allowedConditionTable = nil
local function getAllowedConditions()
    if allowedConditionTable == nil then
        allowedConditionTable = {}
        local tempCSVTable = ftcsv.parse(Atlas.assetsPath .. "/Conditions.csv", "," ,{["headers"] = false,})
        for rowNum in ipairs(tempCSVTable) do
            if rowNum ~= 1 then
                local row = tempCSVTable[rowNum]
                -- TODO: this should be moved to CSVSyntaxCheck.
                if not comFunc.hasVal({"Static", "Dynamic"}, row[3]) then
                    error("Condition type " .. row[3] .. " for condition " .. row[1] .. " is unknown")
                end
                allowedConditionTable[row[1]] = { type=row[3], values=comFunc.parseValArr(row[2]) }
            end
        end
    end
    return allowedConditionTable
end

function Condition.setCondition(name, value, allowStatic, conditions)
    print('Setting condition: '..name..' = '..value)
    if name == nil or name == "" then
        error('condition name (' .. tostring(name) .. ') cannot be nil or empty string.')
    end
    if value == nil then
        error('condition ' .. tostring(name) .. ' value cannot be nil.')
    end

    local allowedConditionTable = getAllowedConditions()[name]
    if allowedConditionTable == nil then
        error("Condition " .. name .. " not specified in Conditions.csv")
    end
    if allowedConditionTable.type == "Static" and not allowStatic then
        error("Not allowed to set static condition " .. name)
    end
    if not comFunc.hasVal(allowedConditionTable["values"], value) then
        error("Condition value " .. tostring(value) .. " not allowed for condition " .. name)
    end
    conditions[name] = value
end

return Condition
