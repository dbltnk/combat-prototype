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
			local s = json.encode(obj[key])
			if last[key] ~= s then c = true last[key] = s end
		end
		
		return c
	end,
	
	send = function (self)
		local nils = {}
		local obj = self.obj
		local msg = { channel = "game", cmd = "sync", oid = obj.oid, owner = obj.owner, time = network.time, }
		for _,key in pairs(self.keys) do 
			if obj[key] == nil then table.insert(nils, key) end
			msg[key] = obj[key] 
		end
		msg.nils = nils
		network.send (msg, false)
	end,
	
	checkAndSend = function (self)
		if self:changed() then
			self:send()
		end
	end,
}
