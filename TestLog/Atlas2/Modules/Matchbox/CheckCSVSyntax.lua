-------------------------------------------------------------------
----***************************************************************
----CSV syntax check
----***************************************************************
-------------------------------------------------------------------

local CheckCSVSyntax = {}
local comFunc = require "Matchbox/CommonFunc"
local ftcsv = require "Matchbox/ftcsv"
local log = require 'Matchbox/logging'


-- check main/site csv syntax
function CheckCSVSyntax.checkMainCSVSyntax(mainCSVPath)

    local isCSVValid = true
    local reportStr1 = "Main.csv"
    local reportStr2 = ""
    local reportStr3 = ""

    local csvTable = ftcsv.parse(mainCSVPath,",",{["headers"] = false,})
    local titleRow = csvTable[1]
    local isTitleValid = true
    local tempThreadFlag,tempSampFlag
    local threadFlagArr,sampFlagArr = {},{}

    if titleRow[1] ~= "TestName" or titleRow[2] ~= "Technology" or
        titleRow[3] ~= "Disable" or titleRow[4] ~= "Production" or
        titleRow[5] ~= "Audit" or titleRow[7] ~= "Loop" or
        titleRow[8] ~= "Sample" or titleRow[9] ~= "CoF" or
        titleRow[10] ~= "Condition" or titleRow[6] ~= "Thread" then
        isTitleValid = false
    end

    if isTitleValid == false then
        isCSVValid = false
        reportStr2 = "title row invalid"
    else
        for i, v in ipairs(csvTable) do
        if i ~= 1 then
            local TestName = v[1]
            local Disable = v[3]:upper()
            if Disable ~= '' and Disable ~= 'Y' and Disable ~= 'N' then
                reportStr2 = TestName
                reportStr3 = 'Disable flag invalid; expecting Y/N/empty'
                isCSVValid = false
            end

            local Production = v[4]:upper()
            if Production ~= '' and Production ~= 'Y' and Production ~= 'N' then
                reportStr2 = TestName
                reportStr3 = 'Production flag invalid; expecting Y/N/empty'
                isCSVValid = false
            end
            local Audit = v[5]:upper()
            if Audit ~= '' and Audit ~= 'Y' and Audit ~= 'N' then
                reportStr2 = TestName
                reportStr3 = "Audit flag invalid; expecting Y/N/empty"
                isCSVValid = false
            end
            if v[6] ~= "" then
                if v[6] ~= tempThreadFlag then
                    if comFunc.hasVal(threadFlagArr,v[6]) then
                        reportStr2 = v[1]
                        reportStr3 = "Put same thread flags together"
                        isCSVValid = false
                    else
                        tempThreadFlag = v[6]
                        threadFlagArr[#threadFlagArr+1] = v[6]
                    end
                end
            end
            if v[7] ~= "" then
                if tonumber(v[7]) == nil then
                    reportStr2 = v[1]
                    reportStr3 = "Loop flag invalid"
                    isCSVValid = false
                elseif tonumber(v[7]) <= 0 or math.floor(tonumber(v[7])) < tonumber(v[7]) then
                    reportStr2 = v[1]
                    reportStr3 = "Loop flag invalid"
                    isCSVValid = false
                end
            end
            if v[8] ~= "" then
                if v[8] ~= tempSampFlag then
                    if comFunc.hasVal(sampFlagArr,v[8]) then
                        reportStr2 = v[1]
                        reportStr3 = "Put same sampling flags together"
                        isCSVValid = false
                    else
                        tempSampFlag = v[8]
                        sampFlagArr[#sampFlagArr+1] = v[8]
                    end
                end
            end
            if v[9] ~= "" and v[9] ~= "COF" and v[9] ~= "SOF" and v[9] ~= "Waived" then
                reportStr2 = v[1]
                reportStr3 = "CoF flag invalid"
                isCSVValid = false
            end
        end
        end
    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2..", "..reportStr3)
    end

    return isCSVValid
end

-- check sampling csv syntax
function CheckCSVSyntax.checkSamplingCSVSyntax(samplingCSVPath)

    local isCSVValid = true
    local reportStr1 = "Sampling.csv"
    local reportStr2 = ""
    local csvTable = ftcsv.parse(samplingCSVPath,",",{["headers"] = false,})

    local titleRow = csvTable[1]
    local isTitleValid = true
    if titleRow[1] ~= "name" or titleRow[2] ~= "proposedRate" then
        isTitleValid = false
    end

    if isTitleValid == false then
        isCSVValid = false
        reportStr2 = "title row invalid"
    else
        for i,v in ipairs(csvTable) do
            if i ~= 1 then
                if tonumber(v[2]) == nil then
                    reportStr2 = "Sampling group ".. v[1] .. " invalid"
                    isCSVValid = false
                end
            end
        end
    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2)
    end

    return isCSVValid
end

-- check condition csv syntax
function CheckCSVSyntax.checkConditionCSVSyntax(ConditionCSVPath)

    local isCSVValid = true
    local reportStr1 = "Conditions.csv"
    local reportStr2 = ""
    local csvTable = ftcsv.parse(ConditionCSVPath,",",{["headers"] = false,})

    local titleRow = csvTable[1]
    local isTitleValid = true
    if titleRow[1] ~= "ConditionName" or titleRow[2] ~= "Values" or titleRow[3] ~= "ConditionType" then
        isTitleValid = false
    end

    if isTitleValid == false then
        isCSVValid = false
        reportStr2 = "title row invalid"
    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2)
    end
end

-- check tech csv syntax.
-- Failure, Init and Teardown does not have FA;
-- Tech CSV has FA.
function CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, fileName, hasFA)
    local isCSVValid
    local reportStr1 = ""
    local reportStr2 = ""
    local reportStr3 = ""
    local expectedColumns = {}
    if hasFA then
        expectedColumns = {
            "TestName", "TestActions", "Disable","Input", "Output",     -- 1-5
            "Timeout", "Retries", "AdditionalParameters", "ExitEarly",  -- 6-9
            "SetPoison", "Commands", "FA", "Condition"                  -- 10-13
        }
    else
        expectedColumns = {
            "TestName", "TestActions", "Disable","Input", "Output",     -- 1-5
            "Timeout", "Retries", "AdditionalParameters", "Commands",   -- 6-9
            "Condition"                                                 -- 10
        }
    end

    TechCSVPath = resourcesPath .. "/" .. fileName

    local techCSVPathArr
    if comFunc.fileRead(TechCSVPath) == nil then
        local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
        local techCSVPathStr = RunShellCommand.run("ls ".. TechCSVPath)
        techCSVPathStr = techCSVPathStr.output
        techCSVPathArr = comFunc.splitBySeveralDelimiter(techCSVPathStr,'\n\r')
        for i,_ in ipairs(techCSVPathArr) do
            techCSVPathArr[i] = TechCSVPath .. "/" ..techCSVPathArr[i]
        end
    else
        techCSVPathArr = {TechCSVPath}
    end

    local testNameArr = {}

    for csvIndex in ipairs(techCSVPathArr) do
        isCSVValid = true
        if fileName:match("Tech") ~= nil then
            reportStr1 = techCSVPathArr[csvIndex]:match(fileName .."/(.*)%.csv") .. ".csv"
        else
            reportStr1 = fileName
        end

        log.LogInfo('Checking CSV syntax for '..techCSVPathArr[csvIndex])
        local csvTable = ftcsv.parse(techCSVPathArr[csvIndex],",",{["headers"] = false,})

        local titleRow = csvTable[1]
        local i = 0
        -- check if the Tech CSV title row strictly matches expectation.
        isCSVValid, i = comFunc.arrayCmp(expectedColumns, titleRow)

        if not isCSVValid then
            setmetatable(titleRow, {__index=function() return 'empty' end})
            setmetatable(expectedColumns, {__index=function() return 'empty' end})
            reportStr2 = 'Title row invalid: Column['..i..'] is '..tostring(titleRow[i])..', expecting '..tostring(expectedColumns[i])
        else
            for i, v in ipairs(csvTable) do
                if i ~= 1 then
                    -- why TestName not testName here: using var name same as column name.
                    -- TODO: store in a key-value table instead of index table.
                    local TestName = v[1]
                    if TestName ~="" then
                        if comFunc.hasVal(testNameArr, TestName) then
                            reportStr2 = TestName
                            reportStr3 = "item name duplicate"
                            isCSVValid = false
                        else
                            testNameArr[#testNameArr+1] = TestName
                        end
                    end
                    local TestActions = v[2]
                    local actionPlugin, actionFunc = string.match(TestActions, "^([_%a%d]*)%:([_%a%d]*)$")
                    if not actionPlugin or not actionFunc then
                        reportStr2 = "Row " .. i
                        reportStr3 = "Action " .. TestActions .. " invalid"
                        isCSVValid = false
                    end

                    -- ensure "Disable" column has one of the following allowed value:
                    -- 1. empty 2. Y 3. N
                    local Disable = v[3]
                    if Disable ~= nil and comFunc.hasVal({'', 'Y', 'N'}, string.upper(Disable))==false then
                        reportStr2 = "Row " .. i
                        reportStr3 = "Parameter Disable " .. Disable .. " invalid; expecting Y, N or empty"
                        isCSVValid = false
                    end

                    -- ensure AdditionalParameters is a valid json string.
                    local AdditionalParameters = v[8]
                    if AdditionalParameters ~= "" and xpcall(comFunc.parseParameter,debug.traceback, AdditionalParameters) == false then
                        reportStr2 = "Row " .. i
                        reportStr3 = "Parameter " .. AdditionalParameters .. " invalid; expecting valid json string."
                        isCSVValid = false
                    end

                    -- Poison: should be Y/y, N/n or empty.
                    if hasFA then
                        local SetPoison = v[10]
                        if SetPoison ~= nil and comFunc.hasVal({'', 'Y', 'N'}, string.upper(SetPoison) == false) then
                        reportStr2 = "Row " .. i
                        reportStr3 = "Parameter SetPoison " .. SetPoison .. " invalid; expecting Y/N/empty."
                        isCSVValid = false
                        end
                    end
                end
            end
        end

        if isCSVValid == false then
            error(reportStr1..", "..reportStr2..", "..reportStr3)
        end
    end
end

-- check limit csv syntax
function CheckCSVSyntax.checkLimitCSVSyntax(LimitCSVPath)
    local reportStr1 = "Limits.csv"
    local reportStr2 = ""
    local reportStr3 = ""

    local csvTable = ftcsv.parse(LimitCSVPath,",",{["headers"] = false,})
    local titleRow = csvTable[1]
    local isTitleValid = true
    local expectedColumns = {
        "TestItem", "ParameterName", "units", "upperLimit", "lowerLimit",
         "relaxedUpperLimit", "relaxedLowerLimit", "Condition"
    }
    local isCSVValid, i = comFunc.arrayCmp(expectedColumns, titleRow)

    if not isCSVValid then
        setmetatable(titleRow, {__index=function() return 'empty' end})
        setmetatable(expectedColumns, {__index=function() return 'empty' end})
        reportStr2 = 'Title row invalid: Column['..i..'] is '..tostring(titleRow[i])..', expecting '..tostring(expectedColumns[i])
    else
        for i,v in ipairs(csvTable) do
            if i ~= 1 then
                reportStr2 = v[1]
                if v[3] == "string" then
                    if v[5] ~= "" then
                        reportStr3 = "lowerLimit invalid"
                        isCSVValid = false
                    end
                    if v[6] ~= "" then
                        reportStr3 = "relaxedUpperLimit invalid"
                        isCSVValid = false
                    end
                    if v[7] ~= "" then
                        reportStr3 = "relaxedLowerLimit invalid"
                        isCSVValid = false
                    end
                else
                    if v[4] ~= "" and tonumber(v[4]) == nil then
                        reportStr3 = "upperLimit invalid"
                        isCSVValid = false
                    end
                    if v[5] ~= "" and tonumber(v[5]) == nil then
                        reportStr3 = "lowerLimit invalid"
                        isCSVValid = false
                    end
                    if v[6] ~= "" and tonumber(v[6]) == nil then
                        reportStr3 = "relaxedUpperLimit invalid"
                        isCSVValid = false
                    end
                    if v[7] ~= "" and tonumber(v[7]) == nil then
                        reportStr3 = "relaxedLowerLimit invalid"
                        isCSVValid = false
                    end
                end
            end
        end
    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2..", "..reportStr3)
    end
end


-- check csv sanitary
-- TODO: check Init.csv and Teardown.csv. rdar://72279073.
function CheckCSVSyntax.checkCSVSyntax(resourcesPath)

    local isCSVValid = true

    CheckCSVSyntax.checkMainCSVSyntax(resourcesPath.."/Main.csv")

    local samplingCSVPath = resourcesPath .. "/Sampling.csv"
    if comFunc.fileExists(samplingCSVPath) then
        CheckCSVSyntax.checkSamplingCSVSyntax(samplingCSVPath)
    end

    ConditionCSVPath = resourcesPath .. "/Conditions.csv"
    if comFunc.fileExists(ConditionCSVPath) then
        isCSVValid = CheckCSVSyntax.checkConditionCSVSyntax(ConditionCSVPath) and isCSVValid
    end

    CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, "Tech", true)
    CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, "Failure.csv", false)
    CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, "Init.csv", false)
    CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, "Teardown.csv", false)
    CheckCSVSyntax.checkLimitCSVSyntax(resourcesPath .. "/Limits.csv")
end

return CheckCSVSyntax
