local net = require 'net'
local json = require 'json'
local list = require 'list'

local next_client_id = 1

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

local server
server = net.createServer(function (client)
	local client_id = next_client_id
	next_client_id = next_client_id + 1
	client.id = client_id
	clients[client] = true

	send_to_other({channel = "server", cmd = "join", id = client.id}, client, clients)
	send_to_one({channel = "server", cmd = "id", id = client.id}, client)
	client:on("data", function(data, ...)
		local message = json.parse(data)
		print("data", client, data, ...)
		
		if (message.channel == "server") then
			if (message.cmd == "who") then
				print("WHO")
				local ids = list.process_keys(clients):print():select(function(c) return c.id end):done()
				send_to_one({seq = message.seq, ids = ids, fin = true}, client)
			elseif message.cmd == "ping" then
				print("PING")
				send_to_one({seq = message.seq, time = message.time, fin = true}, client)			
			end
		else
			send_to_other_raw(data, client, clients)
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
