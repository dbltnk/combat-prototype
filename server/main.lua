local net = require 'net'
local json = require 'json'
local string = require 'string'
local list = require 'list'
local bson = require 'bson'
local os = require 'os'
local math = require 'math'

json.encode = json.stringify
json.decode = json.parse

local clients = {}
local clients_count = 0

local function toLSB(bytes,value)
  local res = ''
  local size = bytes
  local str = ""
  for j=1,size do
     str = str .. string.char(value % 256)
     value = math.floor(value / 256)
  end
  return str
end

local function toLSB32(value) return toLSB(4,value) end

local function fromLSB32(s)
   return s:byte(1) + (s:byte(2)*256) + 
      (s:byte(3)*65536) + (s:byte(4)*16777216)
end

-- returns message, buffer
function decode_message_json(buffer)
	if buffer == nil then return nil, buffer end
	if buffer:len() < 4 then return nil, buffer end
	
	local size = fromLSB32(buffer:sub(1,4))
	--~ print(size)
	
	if buffer:len() < 4 + size then return nil, buffer end
	
	local s = buffer:sub(5, 5 + size - 1)
	
	local rest = nil
	if buffer:len() - size - 4 > 0 then
		rest = buffer:sub(5 + size - 1 + 1)
	end
	
	--~ print("REST", utils.toHex(rest))
	
	return json.decode(s), rest
end

function encode_message_json(message)
	local s = json.encode(message)
	return toLSB32(s:len()) .. s
end

-- returns message, buffer
function decode_message(buffer)
	local msg, buf = decode_message_json(buffer)
	return msg, buf
end

function encode_message(message)
	return encode_message_json(message)
end

-- returns message, buffer
function decode_message(buffer)
	local msg, buf = decode_message_json(buffer)
	return msg, buf
end

function send_to_all(message, clients)
	local json = encode_message(message)
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
	local json = encode_message(message)
	send_to_one_raw(json, client)
end

function send_to_other(message, client, clients)
	local json = encode_message(message)
	send_to_other_raw(json, client, clients)
end

function disconnect(client, clients)
	if not clients[client] then return end
	
	clients_count = clients_count - 1
	clients[client] = nil
	-- send leave message
	local leaveMessage = encode_message({channel = "server", cmd = "left", id = client.id})
	for k,v in pairs(clients) do
		send_to_one_raw(leaveMessage, k)
	end	
end

-- returns part, new_buffer
--[[
function pop_part_from_buffer (buffer)
	if buffer == nil or string.len(buffer) == 0 then return nil, buffer end
	local p = string.find(buffer, "\n", 1, true)
	if p then
		local part = string.sub(buffer, 1, p)
		local rest = string.sub(buffer, p + 1)
		if string.len(rest) == 0 then rest = nil end
		return part, rest
	else
		return nil, buffer
	end
end
]]

local storage = {}

local server
server = net.createServer(function (client)
	-- find first free id
	local client_id = 1
	while list.count(list.process_keys(clients):where(function(c) return c.id == client_id end):done()) > 0 do
		client_id = client_id + 1
	end
	
	clients_count = clients_count + 1
	
	client.id = client_id
	client.unprocessed = ""
	clients[client] = true
	
	local ids = list.process_keys(clients):select(function(c) return c.id end):done()
	
	send_to_other({channel = "server", ids = ids, cmd = "join", id = client.id}, client, clients)
	send_to_one({time=os.uptime(), channel = "server", ids = ids, cmd = "id", id = client.id, first = clients_count == 1, }, client)
	client:on("data", function(data, ...)
		--~ print("data", client, data, ...)

		client.unprocessed = (client.unprocessed or "") .. data
		--~ print("DATA", data)
		while true do
			local message, rest = decode_message(client.unprocessed)
			client.unprocessed = rest
		
			if not message then break end
			
			print("RECEIVED", json.stringify(message))
			
			if (message.channel == "server") then
				if (message.cmd == "who") then
					print("WHO")
					local ids = list.process_keys(clients):select(function(c) return c.id end):done()
					send_to_one({seq = message.seq, ids = ids, fin = true}, client)
				elseif message.cmd == "ping" then
					print("PING")
					send_to_one({seq = message.seq, time = message.time, fin = true}, client)			
				elseif message.cmd == "time" then
					print("TIME")
					send_to_one({seq = message.seq, time = os.uptime(), fin = true}, client)			
				elseif message.cmd == "get" then
					local key = message.key
					local value = storage[key]
					print("GET", key, value)
					send_to_one({seq = message.seq, value = value, fin = true}, client)			
				elseif message.cmd == "set" then
					local key = message.key
					local value = message.value
					print("SET", key, value)
					if key then storage[key] = value end
					send_to_one({seq = message.seq, fin = true}, client)			
				end
			else
				print("DELIVER TO OTHERS")
				send_to_other(message, client, clients)
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
