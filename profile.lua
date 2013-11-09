
local list = require 'list'

local profile = {}

local enabled = false

local data = {}
local current_stack_pos = 0
local stack = {}

function profile.setActive (active)
    enabled = active
    print("profiler is", enabled)
end

function profile.clear ()
	if not enabled then return end
	data = {}
end

function profile.print ()
	if not enabled then print("profiler disabled") return end

	print("--TIME--------------------------")
	local ordered = list.process_values(data)
		:orderby(function (a,b) return a.sum > b.sum end)
		:done()
	for k,v in pairs(ordered) do
		if v.count > 0 then
			print(v.name, "sum", v.sum, "avg", v.sum / v.count, "count", v.count, "max", v.max, "min", v.min)
		end
	end
	print("--MEM---------------------------")
	local ordered = list.process_values(data)
		:orderby(function (a,b) return a.mem_sum > b.mem_sum end)
		:done()
	for k,v in pairs(ordered) do
		if v.count > 0 then
			print(v.name, "sum", v.mem_sum, "avg", v.mem_sum / v.count, "count", v.count, "max", v.mem_max, "min", v.mem_min)
		end
	end
	print("--------------------------------")
	if current_stack_pos > 0 then print ("ERROR profile stack is not clean", current_stack_pos) end
end

function profile.start (name)
	if not enabled then return end
	current_stack_pos = current_stack_pos + 1
	stack[current_stack_pos] = { name = name, start = love.timer.getTime() * 1000, 
		mem_start = math.floor(collectgarbage("count")*1024) }
end

function profile.stop ()
	if not enabled then return end
	if current_stack_pos > 0 then
		local entry = stack[current_stack_pos]
		local dt = love.timer.getTime() * 1000 - entry.start
		local dmem = math.floor(collectgarbage("count")*1024) - entry.mem_start
		local name = entry.name
		
		if not data[name] then
			data[name] = {
				name = name,
				count = 0,
				sum = 0,
				min = nil,
				max = nil,
				mem_sum = 0,
				mem_min = nil,
				mem_max = nil,		
			}
		end
		
		local d = data[name]
		d.count = d.count + 1

		d.sum = d.sum + dt
		d.min = math.min(d.min or dt, dt) 
		d.max = math.max(d.max or dt, dt)

		d.mem_sum = d.mem_sum + dmem
		d.mem_min = math.min(d.mem_min or dmem, dmem) 
		d.mem_max = math.max(d.mem_max or dmem, dmem)
	end
	
	current_stack_pos = current_stack_pos - 1
end

return profile
