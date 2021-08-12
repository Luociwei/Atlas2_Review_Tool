-------------------------------------------------------------------
----***************************************************************
----CSV loading functions
----***************************************************************
-------------------------------------------------------------------

local CSVLoad = {}
local comFunc = require("Matchbox/CommonFunc")
local ftcsv = require("Matchbox/ftcsv")

-- Load Main.csv.
-- Result will be an array containing item dictionaries.
-- String in the first row will be keys for each item dictionary.
-- e.g. for item "Enter_Diags", the dictionary may look like:
-- {["TestName"] = "Enter_Diags",["Technology"] = "DUTstatus",["Disable"] = "",["Production"] = "1",["Audit"] = "",["Loop"] = "2",["Sample"] = "",["CoF"] = "",["Condition"] = "",}
-- Test name must be unique for indexing actions
-- @param mainCSVPath: the path of Main.csv, string type
-- @return Parsed CSV table
function CSVLoad.loadItems(mainCSVPath)
    return ftcsv.parse(mainCSVPath,",")
end

-- filter all items by mode and disable flag.
-- Remove disabled items and needless mode items.
-- Result will be an array containing necessary item dictionaries.
-- e.g. for item "Enter_Diags", the dictionary may look like:
-- {["TestName"] = "Enter_Diags",["Technology"] = "DUTstatus",["Disable"] = "",["Production"] = "1",["Audit"] = "",["Loop"] = "2",["Sample"] = "",["CoF"] = "",["Condition"] = "",}
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

-- load all limits
-- Result will be a dictionary with test names as keys and limit dictionaries as values
-- e.g. for item "SN", the key-value pair may look like:
-- ["SN"] = 
--     { ["TestName"] = "SN",["Units"] = "string",["UpperLimit"] = "DLXX0000AAAA",
--       ["LowerLimit"] = "",["UpperCoF"] = "",["LowerCoF"] = "",["Conditions"] = ""}
-- @param limitsPath: the path of Limits.csv, string type
-- @return limits table
function CSVLoad.loadLimits(limitsPath)
    local limitsTable = {}
    local itemArr = ftcsv.parse(limitsPath,",")
    for _,v in ipairs(itemArr) do
        if limitsTable[v["TestItem"]] == nil then
            limitsTable[v["TestItem"]] = {[v["ParameterName"]] = v,}
        else
            limitsTable[v["TestItem"]][v["ParameterName"]] = v
        end
    end

    return limitsTable
end


return CSVLoad
