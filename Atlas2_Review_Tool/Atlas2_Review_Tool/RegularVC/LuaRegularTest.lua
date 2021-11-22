
function add (a, b)
    ---ss
    local c = 100
    local content = 'ssss'
    local pattern = 'fffff'
    return a+b+c

end

function regular (content, pattern)
    ---ss
    local result_str = ''
    local index = 1
    for w in string.gmatch(content,pattern) do

result_str =result_str..'results['..index..']:'..w..'\n'
        index = index + 1
    end

    return result_str

end

function makeList()
	-- body
	local list = {}
	for i=1,600 do
		local obj = {}
		obj.name = "test"
		table.insert(list, obj)
	end
	print("---------- ok")

    return list;

end

