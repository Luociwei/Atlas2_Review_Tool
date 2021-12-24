local deviceFT = {}

-- Default implementation to error out since this is required
deviceFT.setup = function (deviceName, groupPluginTable)
    error("You must implement deviceFunctionTable.setup(deviceName, groupPluginTable)")
end

-- Default empty implementation if no device plugins
deviceFT.teardown = function (deviceName, devicePluginTable)
    if (devicePluginTable ~= nil and next(devicePluginTable) ~= nil) then
        error("Implement deviceFunctionTable.teardown(deviceName, devicePluginTable) to teardown plugins from deviceFunctionTable.setup(...)")
    end
end

return deviceFT
