log = require 'Matchbox/logging'
local common = require 'Matchbox/CommonFunc'
local matchBoxRecord = require 'Matchbox/record'
local flow_log = require("Tech/WriteLog")
local Record = {}

function Record.createRecordAndLog(result, paraTab, msg)

    local tick = paraTab.AdditionalParameters.tick
    if paraTab.AdditionalParameters.record == nil or paraTab.AdditionalParameters.record == "YES" or tick == nil then

        local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
        local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
        local subsubtestname = paraTab.AdditionalParameters.subsubtestname or ""

        local limitTab = paraTab.limit
        local limit = nil
        if limitTab then
            limit = limitTab[paraTab.AdditionalParameters.subsubtestname]
        end

        if paraTab.AdditionalParameters.attribute ~= nil then
            if result ~= nil then
                DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, result))
            else
                DataReporting.submit(DataReporting.createAttribute(paraTab.AdditionalParameters.attribute, 'nil'))
            end
        end

        local isPass = false
        local failureMsg = ''
        local testRecordValue = ''
        -- when limit is not found, treat as open limit
        -- log.LogInfo('judge result: ', testname,subtestname,subsubtestname,': ', type(limit))
        local record = nil
        if limit == nil then
            isPass = true
            -- log.LogInfo('Does not have limit.')
            -- create p-record for number; otherwise create pass binary record
            if tonumber(result) ~= nil and string.match(tostring(result), "%a") == nil then
                matchBoxRecord.createParametricRecord(tonumber(result), testname, subtestname, subsubtestname, nil, nil)
                testRecordValue = tonumber(result)

            else
                matchBoxRecord.createBinaryRecord(true, testname, subtestname, subsubtestname, nil)
                if paraTab.AdditionalParameters.attribute ~= nil then
                    testRecordValue = result
                else
                    testRecordValue = true
                end
            end
        else
            -- log.LogInfo('has limit defined.')
            -- has limit defined;
            -- check if string limit
            -- log.LogInfo(limit.units)
            if limit.units == 'string' then
                -- string limit; pass if in allowed array
                -- log.LogInfo('checking string limits......: result: '..tostring(result)..', string limit: '..limit.upperLimit)
                if type(result) ~= 'string' then
                    failureMsg = testname .. ' ' .. subtestname .. ' ' .. subsubtestname .. ' result (' .. tostring(result) .. ') type (' .. type(result) .. ') is not string, while has string limit: units is string in Limit.csv.'
                    matchBoxRecord.createBinaryRecord(false, testname, subtestname, subsubtestname, failureMsg)
                    testRecordValue = false
                end
                -- non-empty lower string limit does not make sense.
                if limit.lowerLimit and limit.lowerLimit ~= '' then
                    error('String limit has non-empty lowerLimit, which does not take effect.')
                end
                -- open limit: upper limit not defined(empty string or nil).
                isPass = nil
                if limit.upperLimit == '' or limit.upperLimit == nil then
                    isPass = true
                    testRecordValue = true
                elseif common.hasVal(common.parseValArr(limit.upperLimit), result) then
                    isPass = true
                    testRecordValue = result
                else
                    isPass = false
                    failureMsg = 'String value [' .. result .. '] out of limit; expecting ' .. limit.upperLimit
                    if msg then
                        failureMsg = failureMsg .. '; additional msg: ' .. tostring(msg)
                    end
                    testRecordValue = result
                end

                matchBoxRecord.createBinaryRecord(isPass, testname, subtestname, subsubtestname, failureMsg)
            else
                -- everything else is numeric limit; apply limit, also consider relaxed limit.
                -- log.LogInfo('checking numeric limits......: result: '..result..', lowerLimit: '..tostring(limit.lowerLimit)..', upperLimit: '..tostring(limit.upperLimit))
                -- support strings parsed from uart output, like '32'; convert into number 32.
                numResult = tonumber(result)
                if numResult == nil then
                    -- failed to convert to number; result is not a number or numeric string.

                    failureMsg = 'Failed to convert ' .. tostring(result) .. ' into number while it has numeric limit; check if test function return types match limit type.'
                    matchBoxRecord.createBinaryRecord(false, testname, subtestname, subsubtestname, failureMsg)
                    testRecordValue = false
                else
                    matchBoxRecord.createParametricRecord(numResult, testname, subtestname, subsubtestname, limit, msg)
                    testRecordValue = numResult

                end
            end
        end

        Timer.tock(testname .. " " .. subtestname .. " " .. subsubtestname)
        flow_log.writeFlowLimitAndResult(paraTab, testRecordValue)
    end

    return testRecordValue


end

return Record


