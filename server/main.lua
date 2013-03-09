local net = require('net')
local json = require 'json'

local next_client_id = 1

local clients = {}

function send_to_all(message, clients)
	local json = json.stringify(message)
	send_to_all_raw(json, clients)
end

function send_to_all_raw(data, clients)
	for k,v in pairs(clients) do
		k:write(data)
	end
end

function send_to_other_raw(data, client, clients)
	for k,v in pairs(clients) do
		if k ~= client then k:write(data) end
	end
end

function send_to_one_raw(data, client)
	client:write(data)
end

function send_to_one(message, client)
	local json = json.stringify(message)
	client:write(json)
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
		k:write(leaveMessage)
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
		print("data", client, data, ...)
		send_to_other_raw(data, client, clients)
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
