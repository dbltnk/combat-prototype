local net = require 'net'
local json = require 'json'
local string = require 'string'
local list = require 'list'

local clients = {}

function send_to_all(message, clients)
	local json = json.stringify(message)
	send_to_all_raw(json, clients)
end

function send_to_all_raw(data, clients)
	for k,v in pairs(clients) do
		k:write(data .. "\n")
	end
end

function send_to_other_raw(data, client, clients)
	for k,v in pairs(clients) do
		if k ~= client then k:write(data .. "\n") end
	end
end

function send_to_one_raw(data, client)
	client:write(data .. "\n")
end

function send_to_one(message, client)
	local json = json.stringify(message)
	send_to_one_raw(json, client)
end

function send_to_other(message, client, clients)
	local json = json.stringify(message)
	send_to_other_raw(json, client, clients)
end

function disconnect(client, clients)
	if not clients[client] then return end
	
	clients[client] = nil
	-- send leave message
	local leaveMessage = json.stringify({channel = "server", cmd = "left", id = client.id})
	for k,v in pairs(clients) do
		k:write(leaveMessage .. "\n")
	end	
end

-- returns part, new_buffer
function pop_part_from_buffer (buffer)
	local p = string.find(buffer, "\n", 1, true)
	if p then
		local part = string.sub(buffer, 1, p)
		local rest = string.sub(buffer, p + 1)
		return part, rest
	else
		return nil, buffer
	end
end

local server
server = net.createServer(function (client)
	-- find first free id
	local client_id = 1
	while list.count(list.process_keys(clients):where(function(c) return c.id == client_id end):done()) > 0 do
		client_id = client_id + 1
	end
	
	client.id = client_id
	client.unprocessed = ""
	clients[client] = true
	
	send_to_other({channel = "server", cmd = "join", id = client.id}, client, clients)
	send_to_one({channel = "server", cmd = "id", id = client.id}, client)
	client:on("data", function(data, ...)
		client.unprocessed = client.unprocessed .. data

		while true do
			local part, rest = pop_part_from_buffer(client.unprocessed)
			client.unprocessed = rest
			if not part then break end
			
			local message = json.parse(data)
			print("data", client, data, ...)
			
			if (message.channel == "server") then
				if (message.cmd == "who") then
					print("WHO")
					local ids = list.process_keys(clients):select(function(c) return c.id end):done()
					send_to_one({seq = message.seq, ids = ids, fin = true}, client)
				elseif message.cmd == "ping" then
					print("PING")
					send_to_one({seq = message.seq, time = message.time, fin = true}, client)			
				end
			else
				send_to_other_raw(data, client, clients)
			end
		end
	end)
	
	client:on("end", function(...) 
		disconnect(client, clients)
		print("end", client, ...)
	end)
	
	client:on("close", function(...) 
		disconnect(client, clients)
		print("close", client, ...)
	end)
	
	client:on("error", function(...) 
		disconnect(client, clients)
		print("error", client, ...)
	end)
	
	client:on("timeout", function(...) 
		disconnect(client, clients)
		print("timeout", client, ...)
	end)

end):listen(9999)

print("TCP echo server listening on port 9999")
