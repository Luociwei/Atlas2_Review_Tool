-------------------------------------------------------------------
----***************************************************************
----Condition plugins and conditions
----***************************************************************
-------------------------------------------------------------------

local Condition = {}
local common = require("Matchbox/CommonFunc")
local ftcsv = require("Matchbox/ftcsv")

local allowedConditionTable = nil
-- reserved conditions has predefined allowed values and type
-- shouldn't appear in Conditions.csv
local reservedConditions = {'Hang', 'didSOF', 'didFail', 'Poison'}

local function getAllowedConditions()
    if allowedConditionTable == nil then
        allowedConditionTable = {}
        local tempCSVTable = ftcsv.parse(Atlas.assetsPath .. "/Conditions.csv", ",")
        for rowNum, row in ipairs(tempCSVTable) do
            if common.hasVal(reservedConditions, row.ConditionName) then
                error(row.ConditionName..' is a reserved condition; do not redefine it in Conditions.csv')
            end
            -- allowedValues is ';' separated list of string.
            local allowedValues = common.parseValArr(row.Values)
            local isDynamic = row.Dynamic:upper() == 'Y'
            allowedConditionTable[row.ConditionName] = {isDynamic=isDynamic, values=allowedValues}
        end
    end
    -- hardcode allowed list and type only for "Hang"
    -- don't allow user to set other reserved condition.
    allowedConditionTable['Hang'] = {isDynamic=true, values={'TRUE', 'FALSE'}}
    return allowedConditionTable
end

function Condition.setCondition(name, value, allowStatic, conditions)
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
    if allowedConditionTable.isDynamic == false and not allowStatic then
        error("Not allowed to set static condition " .. name)
    end
    if not common.hasVal(allowedConditionTable.values, value) then
        error("Condition value " .. tostring(value) .. " not allowed for condition " .. name)
    end
    conditions[name] = value
end

return Condition
