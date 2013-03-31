
local list = require 'list'

local profile = {}

local data = {}
local current_stack_pos = 0
local stack = {}

function profile.clear ()
	data = {}
end

function profile.print ()
	print("--------------------------------")
	local ordered = list.process_values(data)
		:orderby(function (a,b) return a.sum > b.sum end)
		:done()
	for k,v in pairs(ordered) do
		if v.count > 0 then
			print(v.name, "sum", v.sum, "avg", v.sum / v.count, "count", v.count, "max", v.max, "min", v.min)
		end
	end
	print("--------------------------------")
end

function profile.start (name)
	current_stack_pos = current_stack_pos + 1
	stack[current_stack_pos] = { name = name, start = love.timer.getTime() * 1000 }
end

function profile.stop ()
	if current_stack_pos > 0 then
		local entry = stack[current_stack_pos]
		local dt = love.timer.getTime() * 1000 - entry.start
		local name = entry.name
		
		if not data[name] then
			data[name] = {
				name = name,
				count = 0,
				sum = 0,
				min = nil,
				max = nil,
			}
		end
		
		local d = data[name]
		d.count = d.count + 1
		d.sum = d.sum + dt
		d.min = math.min(d.min or dt, dt) 
		d.max = math.max(d.max or dt, dt)
	end
	
	current_stack_pos = current_stack_pos - 1
end

return profile
