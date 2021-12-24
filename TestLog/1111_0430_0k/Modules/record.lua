--   record.lua
--   Torchwood lua module for record creation and limit handling.

--   Created by Roy Yang/Shark Liu/Bin Zhao on 2020/7/13.
--   Copyright © 2020 HWTE. All rights reserved.

--[[
-- SMT cannot use matchbox(1.0.2)'s createBinaryRecord() and createParametricRecord() api because
-- 1. (dominante) matchbox's 2 API is designed for calling from csv; it accepts a paraTab table, and get result from its "Input" field. SMT's logic is sequencer to create record for each tech item, result doesn't necessary goes into a variable if we are to use it, we need to construct a paraTab table then call it, which is totally un-necessary.
-- 2. didn't see partial open limit handling in matchbox's API, for example only have one of upper or lower limit.
-- 3. Overall code readibility and quality of matchbox's 2 api is not as good; for example matchbox's relaxed limit handling is not leveraging Atlas2 applyLimit and has some dup code; also numeric limit and relaxed numeric limit handling is separated in matchbox but actually they can both be handled by Atlas2's applyLimit().
--]]
Record = {}
local Log = require("Matchbox/logging")


function Record.trimFailureMsg(msg)
    if (#msg > 509) then
        msg = string.sub(msg, 0, 509) .. '...'
    end
    --remove all \n
    msg = string.gsub(msg, '\n', '')

    return msg
end

function Record.createBinaryRecord(result, testname, subtestname, subsubtestname, failureMsg)
    local record = DataReporting.createBinaryRecord(result, testname, subtestname, subsubtestname)
    if failureMsg and failureMsg ~= '' then
        Log.LogError(failureMsg)
        record.addFailureReason(Record.trimFailureMsg(failureMsg))
    end
    
    DataReporting.submit(record)
    -- local status, ret = xpcall(DataReporting.submit(), debug.traceback, record)
    -- Log.LogDebug('submit record: ' .. tostring(status) .. ', ret=' .. tostring(ret))
    -- return status
end

function Record.createParametricsRecord(numResult, testname, subtestname, subsubtestname, limit, ifUseRelaxedLimit, msg)
    if limit == nil then limit = {} end
    local record = DataReporting.createParametricRecord(numResult, testname, subtestname, subsubtestname)
    -- check if use relaxed limits
    local relaxedLowerLimit, relaxedUpperLimit
    if ifUseRelaxedLimit then
        relaxedLowerLimit = tonumber(limit.relaxedLowerLimit)
        relaxedUpperLimit = tonumber(limit.relaxedUpperLimit)
    else
        relaxedLowerLimit = nil
        relaxedUpperLimit = nil
    end
    -- applyLimit does not return limit check result but only return nil.
    record.applyLimit(relaxedLowerLimit,
                      tonumber(limit.lowerLimit),
                      tonumber(limit.upperLimit),
                      relaxedUpperLimit,
                      limit.units)
    -- record.getResult() have limit check pass/fail
    -- 0: fail 1: relaxed pass 2: pass
    local r = record.getResult()
    if r == 0 then
        -- set message for FAIL records

        local _limit = 'lowerLimit: ' .. tostring(limit.lowerLimit) .. ', upperLimit: ' .. tostring(limit.upperLimit)

        if relaxedLowerLimit then
            _limit = 'relaxedLowerLimit: ' .. tostring(relaxedLowerLimit) .. ', ' .. _limit .. ', relaxedUpperLimit: '..tostring(relaxedUpperLimit)
        end

        failureMsg = 'Out of limit: result=' .. numResult .. ', limit={' .. _limit .. '}'

        if msg and msg ~= '' then
            failureMsg = failureMsg .. 'additional msg: ' .. tostring(msg)
        end

        Log.LogError(failureMsg)
        record.addFailureReason(Record.trimFailureMsg(failureMsg))
    end

    DataReporting.submit(record)
    -- local status, ret = xpcall(DataReporting.submit(), debug.traceback, record)
    -- Log.LogDebug('submit record: ' .. tostring(status) .. ', ret=' .. tostring(ret))
    -- return status and r ~= 0
end

--[[
--  check limit and create record
--  limit: limit dict for the whole test group (main.csv item)
--  check if limit for subsubtestname exist; if yes, apply it.
--  if not, create pass binary record.
--  for test with limit, if limit "unit" is string, check if result is in upperLimit, which is ";" delimited string array; for other unit, treat as parametric record.
--]]
function Record.judgeResult(result, testGroupLimit, stepInfo, ifUseRelaxedLimit, msg)
    local isPass = false
    local record, failureMsg
    -- when limit is not found, treat as open limit
    local ifApplyLimit = true
    if testGroupLimit == nil then ifApplyLimit = false end
    Log.LogInfo("judge result: ".. tostring(result) .. "limit: " ..tostring(limit) .."ifUseRelaxedLimit: " .. tostring(ifUseRelaxedLimit))
    -- in torchwood, record's
    -- testname: Technology
    -- subtestname: "TestName" column in test plan, with 2 suffix:
    --    mainNameSuffix: for dup main item in main.csv; 2nd+ items will have _2, _3, etc
    --    testNameSuffix: for _Loop1 and _FA
    -- subsubtestname: "subsubtestname" in AdditionalParameters
    local tech = stepInfo.testTech
    local testname = stepInfo.TestName
    local subsubtestname = stepInfo.nameSuffix
    if subsubtestname == nil or subsubtestname == "" then
        subsubtestname = ""
    end

    limit = testGroupLimit[testname]
    if limit == nil then
        ifApplyLimit = false
    end

    local record = nil
    if not ifApplyLimit then
        isPass = true
        Log.LogDebug('Does not have limit.')
        -- create p-record for number; otherwise create pass binary record
        numResult = tonumber(result)
        if numResult == nil then
            return Record.createBinaryRecord(true, tech, testname, subsubtestname, nil)
        else
            return Record.createParametricsRecord(numResult, tech, testname, subsubtestname, nil, false, nil)
        end
    else
        Log.LogDebug('has limit defined.')
        -- has limit defined;
        -- check if string limit
        if limit.units == 'string' then
            -- string limit; pass if in allowed array
            Log.LogDebug('checking string limits......: result: '..tostring(result)..', string limit: '..limit.upperLimit)
            if type(result) ~= 'string' then
                failureMsg = tech..' '..testname..' '..subsubtestname..' result ('..tostring(result)..') type ('..type(result)..') is not string, while has string limit: units is string in Limit.csv.'
                Record.createBinaryRecord(false, tech, testname, subsubtestname, failureMsg)
                return false
            end
            -- report warning for non-empty lower limit, because it does not take effect.
            -- matchbox use upper limit for string limit; Torchwood align at it.
            if limit.lowerLimit and limit.lowerLimit ~= '' then
                Log.LogError('String limit has non-empty lowerLimit, which does not take effect.')
            end
            -- open limit: upper limit not defined(empty string or nil).
            isPass = nil
            if limit.upperLimit == '' or limit.upperLimit == nil then
                isPass = true
            elseif comFunc.hasVal(comFunc.parseValArr(limit.upperLimit), result) then
                isPass = true
            else
                isPass = false
                failureMsg = 'String value [' .. result .. '] does not match; expecting ' .. limit.upperLimit
                if msg then
                    failureMsg = failureMsg .. '; additional msg: '..tostring(msg)
                end
            end

            ret = Record.createBinaryRecord(isPass, tech, testname, subsubtestname, failureMsg)
            return isPass and ret
        else
            -- everything else is numeric limit; apply limit, also consider relaxed limit.
            Log.LogDebug('checking numeric limits......: result: '..result..', lowerLimit: '..tostring(limit.lowerLimit)..', upperLimit: '..tostring(limit.upperLimit))
            -- support strings parsed from uart output, like '32'; convert into number 32.
            numResult = tonumber(result)
            if numResult == nil then
                -- failed to convert to number; result is not a number or numberic string.

                failureMsg = 'Failed to convert '..tostring(result)..' into number while it has numeric limit; check if test function return types match limit type.'
                Record.createBinaryRecord(false, tech, testname, subsubtestname, failureMsg)
                return false

            else
                return Record.createParametricsRecord(numResult, tech, testname, subsubtestname, limit, ifUseRelaxedLimit, msg)
            end
        end
    end

end

return Record
