DEVICE_TRANSPORT_URL = {
    {detectionURL = {endpoint="tcp://169.254.1.32:7801",site=1}, commURL = "group1-1"},
    {detectionURL = {endpoint="tcp://169.254.1.32:7802",site=2}, commURL = "group1-2"},
    {detectionURL = {endpoint="tcp://169.254.1.32:7803",site=3}, commURL = "group1-3"},
    {detectionURL = {endpoint="tcp://169.254.1.32:7804",site=4}, commURL = "group1-4"}
}
function initDeviceDetection()
    local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    local dataChannel = fixtureBuilder.createFixtureBuilder(0)
    for _,transport in ipairs(DEVICE_TRANSPORT_URL) do
        local detector = fixtureBuilder.createDeviceDetector(dataChannel,transport.commURL,1)
        Detection.addDeviceDetector(detector)
    end
end

function initDeviceRouting()
    local devRoutingFunc = function(url)
        local slots = Detection.slots()
        local groups = Detection.groups()
        local pattern = '([0-9]+)-([0-9]+)$'
        local group_index, slot_index = string.match(url, pattern)
        group_index = tonumber(group_index)
        slot_index = tonumber(slot_index)
        return slots[slot_index], groups[group_index]
    end
    Detection.setDeviceRoutingCallback(devRoutingFunc)
end

function main()
    -- initDeviceDetection()
    initDeviceRouting()
    Detection.addDevice("group1-1")
    Detection.addDevice("group1-2")
    Detection.addDevice("group1-3")
    Detection.addDevice("group1-4")
end
