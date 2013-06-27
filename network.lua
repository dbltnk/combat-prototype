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

local host = nil
local server = nil

local socket = require 'socket'
List = require 'pl.List'

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

network.messages_send = 0
network.messages_received = 0

local stats_timeout = 1
local stats_last_time = 0

network.client_id = nil
network.is_first = false
network.lag = -1
network.time = 0
network.last_server_time = 0
network.last_time_update = 0
network.connected_client_id_map = {}
network.connected_client_count = 0
network.lowest_client_id = nil
network.open_request_count = 0

network.loss_send = 0
network.loss_recv = 0

local open_requests = {}
local open_requests_payload = {}
local unprocessed = ""
local bytes_read = 0
local out_buff = ""

-- -> message|nil, buffer
function decode_message(buffer)
	local ok, m, l = pcall(json.decode, buffer)
	
	if ok and m ~= nil then
		return m, buffer:sub(l)
	end
	
	return nil, buffer
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
	network.connected_client_count = 0
	local l = nil
	for _, id in pairs(network.connected_client_id_map) do
		l = math.min(l or id, id)
		network.connected_client_count = network.connected_client_count + 1
	end
	print("UPDATE LOWEST",l)
	network.lowest_client_id = l
end

function network.update (dt)
	--~ for k,v in pairs(open_requests_payload) do print(k,v) end

	-- update time and keep in sync
	network.time = network.time + dt
	
	if not host then return end
	
	profile.start("network.ping")
	if love.timer.getTime() - network.last_time_update > 1 then
		local t0 = love.timer.getTime()
		network.send_request({channel = "server", cmd = "time"}, function(fin, result)
			local t1 = love.timer.getTime()
			local latency = (t1 - t0) / 2
			network.time = result.time + latency
			network.last_server_time = network.time
		end)
		network.last_time_update = t0
		
		local msg_send = network.messages_send
		local msg_recv = network.messages_received
		network.send_request({channel = "server", cmd = "msg", send = msg_send, recv = msg_recv}, function(fin, result)
			local server_send = result.send
			local server_recv = result.recv
			
			--~ print("NETWORK MSG STATS", "ls", msg_send, "lr", msg_recv, "rs", server_send, "rr", server_recv)
			
			local send_loss = math.abs(server_recv - msg_send)
			--~ if msg_send > 0 then send_loss = send_loss / msg_send end
			
			local recv_loss = math.abs(server_send - msg_recv)
			--~ if server_send > 0 then recv_loss = recv_loss / server_send end
			
			network.loss_send = send_loss
			network.loss_recv = recv_loss
			--~ print("NETWORK LOSS send", math.floor(send_loss), "recv", math.floor(recv_loss))
		end)
		
		--~ network.send({channel = "stats", cmd = "lag", time = network.time, from = network.client_id})
	end
	profile.stop()
	
	profile.start("network.messages")
	while true do
		local event = host:service(1)
		if event == nil then break end
		
		-- count reliable
		if event.channel == 1 then 
			network.messages_received = network.messages_received + 1
		end
		
		if event then
			if event.type == "connect" then
				print("Connected to", event.peer)
				--~ event.peer:send("hello world")
			elseif event.type == "receive" and tostring(event.data) ~= "0" then
				--~ print("Got message: ", event.data, event.peer, type(event.data))
				--~ done = true
				local m = json.decode(event.data)
				
				if type(m) == "table" then
					m = network.patch_message(m, network_message_keywords_short_to_long)
				
					stats.in_messages = stats.in_messages + 1
					stats.in_bytes = stats.in_bytes + event.data:len()
			
					-- is this a reply?
					local seq = m.seq or nil
					if seq then
						-- response
						local cb = open_requests[seq]
						if cb then
							local fin = m.fin or false
							if fin then 
								open_requests[seq] = nil 
								open_requests_payload[seq] = nil
								network.open_request_count = network.open_request_count - 1
							end
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
								network.connected_client_id_map = {}
								--~ print("XXXXX", json.encode(m))
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
				else
					--~ print("SKIPPING MESSAGE", m)
				end
			elseif tostring(event.data) ~= "0" then
				--~ print("NETEVENT", event.type, event.data, event.peer)
			end
		end
    end
    profile.stop()
    
    profile.start("network.stats")
	-- refresh stats
	if love.timer.getTime() - stats_last_time > stats_timeout then
		stats_last_time = love.timer.getTime()
		
		local timeout = math.floor(network.time-network.last_server_time)
		local timeoutWarning = ""
		if timeout > 8 then timeoutWarning = " DISCONNECTED!!!!!!!!!!! " else timeoutWarning = "" end
		
		local out_msg_size = -1
		local in_msg_size = -1
		if stats.in_messages > 0 then in_msg_size = math.floor(stats.in_bytes / stats.in_messages) end
		if stats.out_messages > 0 then out_msg_size = math.floor(stats.out_bytes / stats.out_messages) end
		
		network.stats = "\nTIME " .. math.floor(network.time) .. " (" .. timeout .. ")" .. timeoutWarning .. "\n" .. 
			"IN " .. math.floor(stats.in_bytes / 1024) .. " k/s " .. stats.in_messages .. " m/s " .. in_msg_size .. " b\n" ..
			"OUT " .. math.floor(stats.out_bytes / 1024) .. " k/s " .. stats.out_messages .. " m/s " .. out_msg_size .. " b\n" ..
			"LAG " .. network.lag .. " LOSS SEND " .. tools.floor1(network.loss_send) .. " RECV " .. tools.floor1(network.loss_recv) .. "\n" ..
			"LOWEST " .. (network.client_id == network.lowest_client_id and "yes" or "no") .. 
				" OUTBUFF " .. out_buff:len() .. " REQS " .. network.open_request_count
				 --~ .. "\n" ..
			--~ "ZONES " .. json.encode(the.player and the.player.zones or {})
		
		-- groups
		local objs = ""
		local groups = {}
		object_manager.visit(function(oid,o)
			local c = o.class or "?"
			if not groups[c] then groups[c] = 0 end
			groups[c] = groups[c] + 1
		end)
		for k,v in pairs(groups) do
			objs = objs .. k .. ": " .. v .. "\n"
		end
		
		-- details
		if config.show_object_list then
			objs = objs .. "\n"
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
		end
		
		network.stats = network.stats .. "\n\n" .. objs
		
		stats = {
			in_bytes = 0,
			in_messages = 0,
			out_bytes = 0,
			out_messages = 0,
		}
	end
	profile.stop()
end

function network.shutdown()
	if server then server:disconnect() end
	if host then host:flush() end
	server = nil
	host = nil
end

-- seq gets added to the message, fin terminates the message
-- response_callback(finished, reply)
local reqs = {}
function network.send_request (message, response_callback)
	if not server then return end
	local seq = next_seq
	message.seq = seq
	next_seq = next_seq + 1
	open_requests[seq] = response_callback
	open_requests_payload[seq] = json.encode(message)
	network.open_request_count = network.open_request_count + 1
	network.send(message, true)
end

network_message_keywords = {
	"incapacitated", 
	"description", 
	"oid", 
	"class", 
	"currentPain", 
	"image", 
	"key", 
	"team", 
	"level", 
	"focused_target", 
	"nils", 
	"isInCombat", 
	"hidden", 
	"rotation", 
	"name", 
	"height", 
	"xpWorth", 
	"seq", 
	"anim_speed", 
	"velocity", 
	"marked", 
	"teamscore", 
	"time", 
	"dmgModified", 
	"alive", 
	"deaths", 
	"anim_name", 
	"armor", 
	"highscore", 
	"owner", 
	"maxPainOverdrive", 
	"width", 
	"invul", 
	"cmd", 
	"finalDamage", 
	"channel", 
	"controller", 
	"value", 
	"maxPain", 
	"weapon", 
	"snared",
	"powerblocked",
	"rooted",
	"mezzed",
	"stunned",
}

network_message_keywords_long_to_short = {}
network_message_keywords_short_to_long = {}

for k,v in pairs(network_message_keywords) do
	network_message_keywords_long_to_short[v] = "p" .. k
	network_message_keywords_short_to_long["p" .. k] = v
end

network_message_keywords = {}

function network.patch_message (message, patch_map)
	local m = {}
	for k,v in pairs(message) do
		if patch_map[k] then m[patch_map[k]] = v else m[k] = v end
	end
	return m
end

function network.send (message, reliable)
	if not server then return end
	
	if reliable == nil then reliable = true end
	--~ print ("reliable", reliable)
	
	-- shorten non server messages
	if message.channel ~= "server" then
		message = network.patch_message(message, network_message_keywords_long_to_short)
	end
	
	-- round to save space
	for k,v in pairs(message) do
		if k:len() > 2 and not network_message_keywords_short_to_long[k] and not network_message_keywords_long_to_short[k] then 
			network_message_keywords[k] = true 
		end
		
		if type(v) == "number" then
			local f = 1000
			message[k] = math.floor(v * f) / f
			--~ print("round", k,v,message[k])
		end
	end
	
	--~ utils.vardump(network_message_keywords)
	
	local m = json.encode(message)
	--~ print("SEND", server, m:len(), m, reliable and "TRUE" or "FALSE")
	local channel = reliable and 1 or 0
	local flag = reliable and "reliable" or "unsequenced"
	server:send(m, channel, flag)
	
	if reliable then
		network.messages_send = network.messages_send + 1
	end

	stats.out_messages = stats.out_messages + 1
	stats.out_bytes = stats.out_bytes + string.len(m)
end

function network.connect (_host, _port)
	require "enet"

	print("luasocket version", socket._VERSION)

	host = enet.host_create()
	server = host:connect(_host .. ":" .. _port, 2)
	
	network.update(1)
	
	print(host,server)
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
