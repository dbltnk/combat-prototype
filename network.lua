-- network

local socket = require 'socket'

network = {}

local c = nil
local next_seq = 1

-- contains callbacks function(message)
-- this method will not deliver request replies
network.on_message = {}

local open_requests = {}

function network.update ()
	while c do
		local plain = c:receive()
		if (not plain) then break end

		print("NET IN", plain)
		m = json.decode (plain);
		
		-- is this a reply?
		local seq = m.seq or nil
		if seq then
			-- response
			local cb = open_requests[seq]
			if cb then
				local fin = m.fin or false
				if fin then open_requests[seq] = nil end
				cb(fin, m)
			else
				print("ERROR", "missing callback for", m)
			end
		else
			-- normal message
			for k,fun in pairs(network.on_message) do
				fun(m)
			end
		end
	end
end

-- seq gets added to the message, fin terminates the message
-- response_callback(finished, reply)
function network.send_request (message, response_callback)
	local seq = next_seq
	message.seq = seq
	next_seq = next_seq + 1
	open_requests[seq] = response_callback
	network.send(message)
end

function network.send (message)
	local m = json.encode(message)
	print("NET OUT", m)
	c:send(m .. "\n")
end

function network.connect (host, port)
	if c then c:close() end
	
	c = socket.connect(host, port)
	if c then c:settimeout(0, "t") end
end

