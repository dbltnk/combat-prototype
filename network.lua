-- network

local socket = require 'socket'

network = {}

local c = nil

-- contains callbacks function(message)
network.on_message = {}

function network.update ()
	while c do
		local m = c:receive()
		if (not m) then break end

		print("NET IN", m)
		m = json.decode (m);
		
		for k,fun in pairs(network.on_message) do
			fun(m)
		end
	end
end

function network:send (message)
	local m = json.encode(message)
	print("NET OUT", m)
	c:send(m)
end

function network.connect (host, port)
	if c then c:close() end
	
	c = socket.connect(host, port)
	if c then c:settimeout(0, "t") end
end

