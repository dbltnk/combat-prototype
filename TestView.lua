-- TestView

local id = 1

TestView = View:extend
{
    onNew = function (self)
		self:setupNetworkHandler()
    end,
    
    onUpdate = function (self, elapsed)
		local data = ""
		for i = 1,1800 do data = data .. i end
		if id <= 100 then network.send({id=id, lala="lala", x=10, l={1,2,3}, f=1.4, data=data}) end
		id = id + 1
    end,	

	setupNetworkHandler = function ()
		table.insert(network.on_message, function(m) 
			print ("RECEIVED", json.encode(m))			
		end)	
	end,
}
