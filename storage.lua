-- storage

--[[ example

local s = storage.load("lala.json") or {}
print(json.encode(s))
s["lala"] = (s["lala"] or 0) + 1
storage.save("lala.json", s)
print(json.encode(s))
os.exit()

--]]

local storage = {}

-- returns {}
storage.load = function (path)
	local f = function()
		local l = io.open(path)
		local s = l:read("*a")
		l:close()
		return json.decode(s)
	end
	
	local ok, result = pcall(f)
	if ok then return result else return nil end
end

-- 
storage.save = function (path, content)
	local f = function()
		local l = io.open(path, "w")
		l:write(json.encode(content))
		l:close()
	end
	
	local ok, result = pcall(f)
	return ok
end


return storage

