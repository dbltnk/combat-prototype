
local utils = {}

-- eg. utils.get_by_path({a={b=1}}, "a.b")
function utils.get_by_path(tbl, path, default)
	local l = str.split("%.", path)
	
	if tbl == nil then return default end
	if #l == 0 then return default end

	local t = tbl
	
	--~ utils.vardump(t)
	for i = 1, #l do
		local k = l[i]
		-- try to use key as number type if possible
		local kn = tonumber(k)
		if kn then t = t[kn] else t = t[k] end
		--~ print(i,k,t,#l)
		if t == nil then return default end -- print("key " .. i .. " not found: " .. k) return default end
	end
	
	return t
end

function utils.vardump(value, max_depth)
	utils.vardump_rec(max_depth or 1, value)
end

function utils.vardump_rec(max_depth, value, depth, key)
  if (depth or 0) > max_depth then return end
  
  local linePrefix = ""
  local spaces = ""
  
  if key ~= nil then
    linePrefix = "["..key.."] = "
  end
  
  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i=1, depth do spaces = spaces .. "  " end
  end
  
  if type(value) == 'table' then
    local mTable = getmetatable(value)
    if mTable == nil then
      print(spaces ..linePrefix.."(table) ")
    else
      print(spaces .."(metatable) ")
        value = mTable
    end		
    for tableKey, tableValue in pairs(value) do
      utils.vardump_rec(max_depth, tableValue, depth, tableKey)
    end
  elseif type(value)	== 'function' or 
      type(value)	== 'thread' or 
      type(value)	== 'userdata' or
      value		== nil
  then
    print(spaces..tostring(value))
  else
    print(spaces..linePrefix.."("..type(value)..") "..tostring(value))
  end
end

function utils.clamp (value, min, max)
	if value < min then return min
	elseif value > max then return max
	else return value end
end

function utils.mapIntoRange (srcValue, srcMin, srcMax, dstMin, dstMax)
	if srcMax - srcMin <= 0.0000001 then return dstMin end
	local r = (utils.clamp (srcValue, srcMin, srcMax) - srcMin) / (srcMax - srcMin)
	return dstMin + (dstMax - dstMin) * r
end

function utils.sign (x)
	if x < 0 then return -1 end
	if x > 0 then return 1 end
	return 0
end

-- function fun(key, value) -> key, value
function utils.filter2 (l, fun)
	local r = {}
	for k,v in pairs(l) do
		if fun(k,v) then r[kk] = vv end
	end
	return r
end

-- function fun(key, value) -> key, value
function utils.map2 (l, fun)
	local r = {}
	for k,v in pairs(l) do
		local kk,vv = fun(k,v)
		r[kk] = vv
	end
	return r
end

-- function fun(value) -> value
function utils.map1 (l, fun)
	local r = {}
	for k,v in pairs(l) do
		r[k] = fun(v)
	end
	return r
end

-- returns {key0, key1, ...}
function utils.keys (l)
	r = {}
	
	for k,v in pairs(l) do
		table.insert(r, k)
	end
	
	return r
end

-- returns {value0, value1, ...}
function utils.values (l)
	r = {}
	
	for k,v in pairs(l) do
		table.insert(r, v)
	end
	
	return r
end

function utils.toHex(s)
	local replaceNonPrintableChars = function (s, replacement)
		local r = ""
		for i = 1,string.len(s) do
			local b = s:byte(i)
			if b >= 33 and b <= 126 then r = r .. string.char(b)
			else r = r .. replacement end
		end
		return r
	end

	if not s or type(s) ~= "string" then return "<nil>" end
	
	local r = ""
	for i = 1,string.len(s) do
		r = r .. (s:byte(i) < 16 and "0" or "") .. string.format("%x ", s:byte(i))
	end
	r = r .. "(" .. string.len(s) .. " bytes) [" .. replaceNonPrintableChars(s, ".") .. "]"
	return r
end

return utils
