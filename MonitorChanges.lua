-- MonitorChanges

MonitorChanges = Class:extend
{
	obj = nil,
	keys = {},
	last = {},
	last_time = 0,
	timeout = 1/10,
	last_zoneless_time = 0,
	last_complete_time = 0,
	-- local reuse of var to reduce gc pressure
	changedKeys = {},
	
	-- returns nil or table of changed keys
	changed = function  (self)
		local obj = self.obj
		local last = self.last
		local keys = self.keys
		local changedKeys = self.changedKeys

		-- clear to reuse
		for k,v in pairs(changedKeys) do changedKeys[k] = nil end

		if not obj then return false end
		local t = love.timer.getTime()
		
		if t - self.last_time < self.timeout then return end
		
		local c = false
		
		for _,key in pairs(keys) do
			local s = self:toReadable(obj[key])
			if last[key] ~= s then 
				c = true 
				last[key] = s 
				table.insert(changedKeys, key)
			end
		end
		
		if c then
			self.last_time = t
			return changedKeys
		else
			return nil
		end
	end,

	toReadable = function (self, x)
	    local t = type(x)
	    if t == "table" then return json.encode(x) end
	    return tostring(x)
	end,
	
	-- its possible to notify the changed keys to reduce network message size
	send = function (self, changedKeys)
		local nils = {}
		local obj = self.obj

		local zone = nil
		
		-- is complete update? even unchanged values?
		
		-- flip changed key table, key <-> value
		if changedKeys then
			local ckFlipped = {}
			for k,v in pairs(changedKeys) do ckFlipped[v] = true end
			changedKeys = ckFlipped
		end
		
		local t = love.timer.getTime()
		local isCompleteUpdate = false
		if changedKeys == nil or t - self.last_complete_time > config.sync_complete_timeout then
			self.last_complete_time = t
			isCompleteUpdate = true
			--~ print("complete UPDATE---------------------")
		end
		
		--~ utils.vardump(changedKeys or {})
		
		local msg = { channel = "game", cmd = "sync", oid = obj.oid, zone = zone, owner = obj.owner, time = network.time, }
		--~ local msg = { channel = "game", cmd = "sync", oid = obj.oid, owner = obj.owner, time = network.time, }
		for _,key in pairs(self.keys) do 
			if changedKeys == nil or changedKeys[key] then
				if obj[key] == nil then table.insert(nils, key) end
				msg[key] = obj[key] 
			end
		end
		msg.nils = nils
		network.send (msg, false)
		--~ utils.vardump(msg)
	end,
	
	forceSend = function (self)
		send:send()
		self.last_time = love.timer.getTime()
	end,
	
	checkAndSend = function (self)
		local changedKeys = self:changed()
		if changedKeys then
		    self:send(changedKeys)
		end
	end,
}
