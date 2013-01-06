
local utils = {}

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


return utils
