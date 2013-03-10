-- MonitorChanges

MonitorChanges = Class:extend
{
	obj = nil,
	keys = {},
	last = {},
	last_time = 0,
	timeout = 1/10,
	
	-- returns bool
	changed = function  (self)
		local obj = self.obj
		local last = self.last
		local keys = self.keys
		
		if not obj then return false end
		local t = love.timer.getTime()
		
		if t - self.last_time < self.timeout then return end
		self.last_time = t
		
		local c = false
		
		for _,key in pairs(keys) do
			print(key, last[key], obj[key])
			if last[key] ~= obj[key] then c = true last[key] = obj[key] end
		end

		return c
	end,
}
