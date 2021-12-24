local PListSerialization = {}

if Atlas ~= nil then 
    PListSerialization.PListPlugin = Atlas.loadPlugin("PListSerializationPlugin")
else
    PListSerialization.PListPlugin= require("PListSerializationPlugin")
end

--! @brief Load dictionary from PList file
--! @param PListFileName PList file name
--! @returns Dictionary object
function PListSerialization.LoadFromFile(PListFileName)
	local file = io.open(PListFileName, "rb")
    if not file then 
    	print ("PListSerialization Error: Could not read file")
    	return nil 
    end

    local content = file:read("*a")
    file:close()

    local dict = {}
    if content then
		dict = PListSerialization.PListPlugin.decode(content)
		print(dict)
	end

	return dict
end

--! @brief Save dictionary to PList file
--! @param data Dictionary to save
--! @param PListFileName PList file name
function PListSerialization.SaveToFile(data, PListFileName)
	dataStr = PListSerialization.PListPlugin.encode(data)
	local file = io.open(PListFileName, "wb")
    if not file then 
    	print ("PListSerialization Error: Could not open file for writing")
    	return nil 
    end

    file:write(dataStr) 
	file:close()
end

return PListSerialization
