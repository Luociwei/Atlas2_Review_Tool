-------------------------------------------------------------------
----***************************************************************
----CSV loading functions
----***************************************************************
-------------------------------------------------------------------

local CSVLoad = {}
local comFunc = require("Matchbox/CommonFunc")
local ftcsv = require("Matchbox/ftcsv")
local CSVSyntax = require 'Matchbox/CheckCSVSyntax'
local log = require 'Matchbox/logging'

-- Load Main.csv.
-- Result will be an array containing item dictionaries.
-- String in the first row will be keys for each item dictionary.
-- Test name must be unique for indexing actions
-- @param mainCSVPath: the path of Main.csv, string type
-- @return Parsed CSV table
-- @param mainCSVPath: the path of Main/Init/Teardown.csv, string type
-- @return Parsed CSV table without Notes column
function CSVLoad.loadItems(mainCSVPath)
    local columns = comFunc.clone(CSVSyntax.mainCSVColumns)

    -- keep every column except for Notes
    for i, column in ipairs(columns) do
        if column == 'Notes' then
            table.remove(columns, i)
            break
        end
    end
    return ftcsv.parse(mainCSVPath,",", {fieldsToKeep=columns})
end

-- filter all items by mode and disable flag.
-- Remove disabled items and needless mode items.
-- Result will be an array containing necessary item dictionaries.
-- e.g. for item "Enter_Diags", the dictionary may look like:
-- @param parsedCSVTable: table
-- @param testMode: string
-- @return Filtered CSV table
function CSVLoad.filterItems(parsedCSVTable,testMode)
    local filteredCSVTable = {}
    local isItemLoad = {}
    local newRowNum = 1
    
    for i,v in ipairs(parsedCSVTable) do
        isItemLoad[i] = true
        -- load test mode
        -- TODO: change Y/N to upper when loading CSV, not doing upper() here
        if testMode == "Production" and v.Production:upper() ~= 'Y' then
            isItemLoad[i] = false
        end
        if testMode == "Audit" and v.Audit:upper() ~= 'Y' then
            isItemLoad[i] = false
        end
        -- check disabled items
        if isItemLoad[i] and v.Disable:upper() == 'Y' then
            isItemLoad[i] = false
        end
        -- Load items
        if isItemLoad[i] then
            filteredCSVTable[newRowNum] = v
            newRowNum = newRowNum + 1
        end
    end
    return filteredCSVTable
end

-- load tech csv
-- Result will be a dictionary with test names as keys and action arrays as values
-- e.g. for item "Enter_Diags", the key-value pair may look like:
-- ["Enter_Diags"] = 
-- {
--    {["TestName"] = "Enter_Diags", ["Tech"] = "DUTstatus",["Actions"] = "Lua:createCommandRecord",
--     ["Parameter"] = "",["Command"] = "diags",["Conditions"] = ""},
--    {["TestName"] = "Enter_Diags", ["Tech"] = "DUTstatus",["Actions"] = "Lua:createParametricRecord",
--     ["Parameter"] = "{"Input":"enter diag success"}",["Command"] = "",["Conditions"] = ""}
-- }
-- Test name must be unique for indexing actions
-- @param techPath: the path of tech file, string type
-- @return action table
function CSVLoad.loadTech(techPath)
    local actionTable = {}
    local techName = techPath:match("/([^/]-)%.csv")
    if techName == nil then
        error("Tech path should contain Tech/Failure/Init/Teardown")
    end
    local techCSVTable = ftcsv.parse(techPath,",",{["headers"] = false,})
    local techTitleRow = techCSVTable[1]
    local parsedTechCSVTable = {}
    for i,v in ipairs(techCSVTable) do
        if i ~= 1 then
            parsedTechCSVTable[i-1] = {}
        end
    end
    local tempTestName = ""
    for i,v in ipairs(parsedTechCSVTable) do
        for ii = 1,#techTitleRow do
            v[techTitleRow[ii]] = techCSVTable[i+1][ii]
            if v["TestName"] ~= "" then
                tempTestName = v["TestName"]
            else 
                v["TestName"] = tempTestName
            end
            v["Technology"] = techName
            v["Notes"] = nil
        end
    end
    for i,v in ipairs(parsedTechCSVTable) do
        if v.Disable == nil or string.upper(v.Disable) ~= 'Y' then
            if actionTable[v["TestName"]] == nil then
                actionTable[v["TestName"]] = {v}
            else
                table.insert(actionTable[v["TestName"]],v)
            end
        end
    end
    return actionTable
end

-- load limits from Assets/Limits.csv
-- @param limitsPath: string, the path of Limits.csv
-- @return limits table:
--        key: TestName
--        value: limits table:
--               key: ParameterName
--            values: limits table with ll, ul, units and a like
function CSVLoad.loadLimits(limitsPath)
    local limitsTable = {}
    local itemArr = ftcsv.parse(limitsPath,",")
    for _,v in ipairs(itemArr) do
        if limitsTable[v["TestName"]] == nil then
            limitsTable[v["TestName"]] = {[v["ParameterName"]] = v,}
        else
            limitsTable[v["TestName"]][v["ParameterName"]] = v
        end
    end

    return limitsTable
end

function CSVLoad.loadSamplingGroups(samplingCSVPath)
    local sampleTable = ftcsv.parse(samplingCSVPath, ",")
    -- table passed into plugin: {{name1, rate1}, {name2, rate2}}
    -- use array which has less serialization overhead than dictionary
    local ret = {}
    for i, sampleLine in ipairs(sampleTable) do
        local name = sampleLine.name
        local numRate = tonumber(sampleLine.proposedRate)
        assert(numRate ~= nil, name..' has non-number default sample rate')
        log.LogInfo('Sample group: '..name..', proposed rate: '..numRate)
        ret[i] = {name, numRate}
    end
    return ret
end


return CSVLoad
