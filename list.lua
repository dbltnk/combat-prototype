
local list = {}

-- ipair list helper methods

--[[
local l = {1,2,3}
l = list.concat(l, {1,2})
l = list.skip(l, 1)
l = list.take(l, 3)
l = list.concat(l, {1,2})
l = list.distinct(l)
l = list.order_by(l, function(a,b) return a < b end)
list.print(l)

local l = list.process({1,2,3})
local mt = getmetatable(l)

for k,v in pairs(l) do print(k,v) end
for k,v in pairs(mt) do print(k,v) end

print(unpack(l:done()))

l:concat({1,2})
	:skip(1)
	:take(3)
	:concat({1,2})
	:distinct()
	:order_by(function(a,b) return a < b end)
	:print()
]]


function list.take (l, n)
	local r = {}
	if l then for i = 1,n do table.insert(r, l[i]) end end
	return r
end

function list.skip (l, n)
	local r = {}
	if l then for i = n+1,#l do table.insert(r, l[i]) end end
	return r
end

-- function fun(x, i) -> x'
function list.select (l, fun)
	local r = {}
	for i,v in ipairs(l) do table.insert(r, fun(v,i)) end
	return r
end

function list.distinct (l)
	local r = {}
	if l then
		local c = {}
		for i,v in ipairs(l) do 
			if not c[v] then table.insert(r, v) c[v] = true end
		end
	end
	return r
end

-- function fun(a,b) -> bool, true if a < b, not stable
function list.order_by (l, fun)
	local r = {}
	if l then for i,v in ipairs(l) do table.insert(r, v) end end
	table.sort(r, fun)
	return r
end

-- function fun(v,i) -> bool, true if contained in result
function list.where (l, fun)
	local r = {}
	if l then for i,v in ipairs(l) do if fun(v,i) then table.insert(r, v) end end end
	return r
end

function list.concat (l, ll)
	local r = {}
	if l then for i,v in ipairs(l) do table.insert(r, v) end end
	if ll then for i,v in ipairs(ll) do table.insert(r, v) end end
	return r
end

function list.count (l)
	return #l
end

function list.print (l)
	print(unpack(l))
end

-- will wrap the list in a "processing" object (fluent)
-- eg. list.process({1,2,3,4,5}):select(function (x) return x*x end):print()
-- list.process(...):done() converts the object back to a list
-- list.process({1,2,3,4,5}):X(6,"lala") will call list.X({1,2,3,4,5}, 6,"lala")
-- if list.X returns a non table table it gets wrapped into a 1-element list
function list.process (l)
	local p = {}
	local mt = {
		__index = function (self, name)
			local f = list[name]
			if f then
				return function (self, ...) 
					local r = f(l, ...)
					if type(r) ~= "table" then r = {r} end
					return list.process(r) 
				end
			end
		end,
	}
	
	p.done = function () return l end
	p.print = function () list.print(l) return p end
		
	setmetatable(p, mt)
	return p
end

function list.process_values (m)
	local r = {}
	for k,v in pairs(m) do table.insert(r, v) end
	return list.process(r)
end

function list.process_keys (m)
	local r = {}
	for k,v in pairs(m) do table.insert(r, k) end
	return list.process(r)
end

return list
