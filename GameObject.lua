-- GameObject

-- mixin
GameObject = {
	-- x,y,oid,class,owner
	-- props
	-- sync_high, sync_low
	
	-- changeMonitorHigh
	-- changeMonitorLow
	
	-- counts object destructions to be able to kill running tickers (eg. after)
	die_counter = 0,
	
	onMixin = function (self)
		--~ print("GO MIXIN")
		
		object_manager.create(self)
				
		if not self.created_via_network then
--			print("CREATE FOR NETWORK", self.oid, self.class)
			self:netCreate()
		end

		if self.sync_high then
			self.changeMonitorHigh = MonitorChanges:new{ timeout = config.sync_high, obj = self, keys = self.sync_high }
		end
		if self.sync_low then
			self.changeMonitorLow = MonitorChanges:new{ timeout = config.sync_low, obj = self, keys = self.sync_low }
		end
	end,
	
	onUpdate = function (self, ...)
		--~ print("GO UPDATE")

		if self:isLocal() then
			if self.onUpdateLocal then self:onUpdateLocal(...) end
			
			if self.changeMonitorHigh then self.changeMonitorHigh:checkAndSend() end
			if self.changeMonitorLow then self.changeMonitorLow:checkAndSend() end
		else
			if self.onUpdateRemote then self:onUpdateRemote(...) end
		end
		
		if self.onUpdateBoth then self:onUpdateBoth(...) end
	end,
	
	after = function (self, duration, fun)
		local starting_die_counter = self.die_counter
		the.app.view.timer:after(duration, function()
			if self.die_counter == starting_die_counter then fun() end
		end)
	end,
	
	every = function (self, duration, fun)
		local starting_die_counter = self.die_counter
		the.app.view.timer:every(duration, function()
			if self.die_counter == starting_die_counter then fun() end
		end)
	end,
	
	onDie = function (self, ...)
		self.die_counter = self.die_counter + 1
	
		if self:isLocal() then
			if self.onDieLocal then self:onDieLocal(...) end
			network.send({channel = "game", cmd = "delete", oid = self.oid, })
		else
			if self.onDieRemote then self:onDieRemote(...) end
		end
		
		if self.onDieBoth then self:onDieBoth(...) end
		
		object_manager.delete(self)
	end,
	
	receive = function (self, message_name, ...)
		
	end,
	
	receiveWithoutResendingToNet = function (self, message_name, ...)
		--~ print("GO RECEIVE", message_name, ...)

		if self:isLocal() then
			if self.receiveLocal then self:receiveLocal(message_name, ...) end
		else
			if self.receiveRemote then self:receiveRemote(message_name, ...) end
		end
		
		if self.receiveBoth then self:receiveBoth(message_name, ...) end	
	end,
	
	receive = function (self, message_name, ...)
		self:receiveWithoutResendingToNet(message_name, ...)
		
		-- deliver message to network
		local params = {...}
		network.send({channel = "game", cmd = "msg", oid = self.oid, 
			name = message_name, params = params, time = network.time})		
	end,
	
	netCreate = function (self)
		local m = { 
			channel = "game", cmd = "create", class = self.class, oid = self.oid, owner = self.owner, 
			x = self.x, y = self.y, width = self.width, height = self.height,  
		}

		if self.props then
			for _,prop in pairs(self.props) do
				m[prop] = self[prop]
			end
		end
		
		network.send(m)
	end,
	
	isLocal = function (self)
		if self.owner and self.owner > 0 then
			return self.owner == network.client_id
		else
			return network.client_id == network.lowest_client_id
		end
	end,
	
	sendResync = function (self)
		if not self:isLocal() then return end
		
		local nils = {}
		local msg = { channel = "game", cmd = "sync", oid = self.oid, owner = self.owner, time = network.time, }
		for _,prop in pairs(self.props) do
			if self[prop] == nil then table.insert(nils, prop) end
			msg[prop] = self[prop] 
		end
		msg.nils = nils
		network.send (msg)
	end,
	
	propsToString = function (self)
		local r = ""
		if self.props then 
			for k,v in pairs(self.props) do
				r = r .. v .. "=" .. tostring(self[v]) .. " "
			end
		end
		return r
	end,
}
