
local profile = {}

local data = {}
local current_name = nil

function profile.clear ()
	data = {}
end

function profile.print ()
	print("--------------------------------")
	for k,v in pairs(data) do
		if v.count > 0 then
			print(k, "sum", v.sum, "avg", v.sum / v.count, "count", v.count, "max", v.max, "min", v.min)
		end
	end
	print("--------------------------------")
end

function profile.start (name)
	current_name = name
	
	if not data[name] then
		data[name] = {
			count = 0,
			sum = 0,
			min = nil,
			max = nil,
			start = love.timer.getTime() * 1000
		}
	else
		data[name].start = love.timer.getTime() * 1000
	end
end

function profile.stop ()
	if current_name and data[current_name] then
		local d = data[current_name]
		local dt = love.timer.getTime() * 1000 - d.start
		d.count = d.count + 1
		d.start = nil
		d.sum = d.sum + dt
		d.min = math.min(d.min or dt, dt) 
		d.max = math.max(d.max or dt, dt)
		
		current_name = nil
	end
end

return profile
