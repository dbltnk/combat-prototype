-- network

--[[
S>C {channel = "server", cmd = "join", id = client.id}
S>C {time=, channel = "server", cmd = "id", id = client.id, first = , }
S>C {channel = "server", cmd = "left", id = client.id}
C>S {channel = "server", cmd = "who", seq = } -> { ids }
C>S {channel = "server", cmd = "ping", time = seq = } -> { time }
C>S {channel = "server", cmd = "time", } -> { time }
C>S {channel = "server", cmd = "get", key =, } -> { value }
C>S {channel = "server", cmd = "set", key =, value = }
C>C {channel = "game", cmd = "sync", oid = , owner = , ...}
C>C {channel = "game", cmd = "create", class = , oid = , owner = , ...}
C>C {channel = "game", cmd = "request", oid = }
C>C {channel = "game", cmd = "delete", oid = }
C>C {channel = "game", cmd = "msg", oid = , name =, params = [...]}
]]

local socket = require 'socket'

network = {}

local client = nil
local next_seq = 1

-- contains callbacks function(message)
-- this method will not deliver request replies
network.on_message = {}

network.stats = ""

local stats = {
	in_bytes = 0,
	in_messages = 0,
	out_bytes = 0,
	out_messages = 0,
}

local stats_timeout = 1
local stats_last_time = 0

network.client_id = nil
network.is_first = false
network.time = 0
network.last_time_update = 0
network.connected_client_id_map = {}
network.lowest_client_id = nil

local open_requests = {}

local unprocessed = ""
local bytes_read = 0

-- returns message, buffer
function decode_message(buffer)
	local ok, message, newBuffer = pcall(bson.decode, buffer)
	if ok then
		return message, newBuffer
	else
		print("ERROR", message)
		return nil, buffer
	end
end

function replaceNonPrintableChars(s, replacement)
	local r = ""
	for i = 1,string.len(s) do
		local b = s:byte(i)
		if b >= 33 and b <= 126 then r = r .. string.char(b)
		else r = r .. replacement end
	end
	return r
end

function toHex(s)
	if not s or type(s) ~= "string" then return "<nil>" end
	
	local r = ""
	for i = 1,string.len(s) do
		r = r .. (s:byte(i) < 16 and "0" or "") .. string.format("%x ", s:byte(i))
	end
	r = r .. "(" .. string.len(s) .. " bytes) [" .. replaceNonPrintableChars(s, ".") .. "]"
	return r
end

function network.update_lowest_client_id ()
	local l = nil
	for _, id in pairs(network.connected_client_id_map) do
		l = math.min(l or id, id)
	end
	print("UPDATE LOWEST",l)
	network.lowest_client_id = l
end

function network.update (dt)
	-- update time and keep in sync
	network.time = network.time + dt
	
	if love.timer.getTime() - network.last_time_update > 5 then
		local t0 = love.timer.getTime()
		network.send_request({channel = "server", cmd = "time"}, function(fin, result)
			local t1 = love.timer.getTime()
			local latency = (t1 - t0) / 2
			network.time = result.time + latency
		end)
		network.last_time_update = t0
	end
	
	while client do
		local err, err_text, buffer = client:receive(1024*1024)
		if buffer then 
			unprocessed = unprocessed .. buffer
			stats.in_bytes = stats.in_bytes + string.len(buffer)
		end
	
		--~ if string.len(unprocessed) > 0 then print("NET IN STATUS", toHex(unprocessed)) end
	
		if (not unprocessed or string.len(unprocessed) == 0) then break end
		
		local m, rest = decode_message(unprocessed)
		unprocessed = rest

		if not m or type(m) ~= "table" then break end
	
		print("NET IN", json.encode(m))
		
		stats.in_messages = stats.in_messages + 1
		
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
			-- id message?
			if m.channel == "server" then
				if m.cmd == "id" then
					network.client_id = m.id
					network.time = m.time
					network.is_first = m.first
					object_manager.nextFreeId = (m.id - 1) * 100000 + 1
					network.connected_client_id_map = {}
					for _,id in pairs(m.ids) do network.connected_client_id_map[id] = id end
					network.update_lowest_client_id()
				elseif m.cmd == "join" then
					network.connected_client_id_map[m.id] = m.id
					network.update_lowest_client_id()
				elseif m.cmd == "left" then
					network.connected_client_id_map[m.id] = nil
					network.update_lowest_client_id()
				end
			end
			
			-- normal message
			for k,fun in pairs(network.on_message) do
				fun(m)
			end
		end
	end
	
	-- refresh stats
	if love.timer.getTime() - stats_last_time > stats_timeout then
		stats_last_time = love.timer.getTime()
		
		network.stats = "\nTIME " .. math.floor(network.time) .. "\n" .. 
			"IN " .. math.floor(stats.in_bytes / 1024) .. " k/s " .. stats.in_messages .. " m/s\n" ..
			"OUT " .. math.floor(stats.out_bytes / 1024) .. " k/s " .. stats.out_messages .. " m/s\n" ..
			"LOWEST " .. (network.client_id == network.lowest_client_id and "yes" or "no")
			
		local objs = ""
		object_manager.visit(function(oid,o)
			local loc = "?"
			if o.isLocal then
				if o:isLocal() then 
					loc = "LOCAL"
				else 
					loc = "REMOTE" 
				end
			end
			local obj = "#" .. oid .. " " .. (o.class or "?") .. " " .. loc .. " " .. (o.propsToString and o:propsToString() or "") .. "\n"
			objs = objs .. obj
		end)
		network.stats = network.stats .. "\n\n" .. objs
			
		stats = {
			in_bytes = 0,
			in_messages = 0,
			out_bytes = 0,
			out_messages = 0,
		}
	end
end

function network.shutdown()
	if not client then return end
	client:close()
end

-- seq gets added to the message, fin terminates the message
-- response_callback(finished, reply)
function network.send_request (message, response_callback)
	if not client then return end
	local seq = next_seq
	message.seq = seq
	next_seq = next_seq + 1
	open_requests[seq] = response_callback
	network.send(message)
end

function network.send (message)
	if not client then return end

	print("NET OUT", json.encode(message))

	local m = bson.encode(message)
	stats.out_messages = stats.out_messages + 1
	stats.out_bytes = stats.out_bytes + string.len(m)

	local i,j = 1, string.len(m)
	
	while true do
		local r = client:send(m, i, j)
		if r == nil then print("NET ERROR sending") break end
		i = r + 1
		if i > j then break end
	end
end

function network.connect (host, port)
	if client then client:close() end
	
	client = socket.connect(host, port)
	if client then client:settimeout(0, "t") end
end

-- callback(value)
function network.get (key, callback)
	network.send_request({channel = "server", cmd = "get", key = key, }, function(fin, result)
		if callback then callback(result.value) end
	end)
end

function network.set (key, value)
	network.send_request({channel = "server", cmd = "set", key = key, value = value}, function(fin, result)
		
	end)
end
