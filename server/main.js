var async = require("async");
var optimist = require("optimist");
var q = require("q");
var synchronized = require("synchronized");
var _ = require("underscore");
var _s = require("underscore.string");
var wilson = require("wilson");
var net = require("net");
var os = require("os");
var enet = require("enet");
var toobusy = require('toobusy');
var config = require('./config.js');

// -> [message|null, buffer]
function tryToParseBuffer (buffer) {
	var s = buffer.toString();
	try {
		var m = JSON.parse(s);
		return [m, new Buffer(0)];
	}
	catch (e) {}
	
	// fallback to partial parser
	for (var i = buffer.length; i >= 0; --i) {
		if (buffer[i] != 10) continue;
		
		var b = buffer.slice(0, i);
		try {
			var m = JSON.parse(b.toString());
			return [m, buffer.slice(i, buffer.length)];
		} 
		catch(e) {}
	}
	
	return [null, buffer]
}

var clients = [];
var clients_count = 0;

// returns {msg: message, rest: buffer }
function decode_message(buffer) {
	var t = tryToParseBuffer(buffer);
	return {msg: t[0], rest: t[1]};
}

function encode_message(message) {
	return JSON.stringify(message);
}

function send_to_other_raw(data, client, clients, reliable) {
	_.each(clients, function(c) {
		if (c != client) send_to_one_raw(data, c, reliable);
	});
}

function send_to_one_raw(data, client, reliable) {
	reliable = typeof reliable !== 'undefined' ? reliable : true;
	// FIXME enet.Packet.FLAG_RELIABLE should be 1 but seems to be broken (undefined)
	var packet = new enet.Packet(data, reliable ? 1 : 0);
	//~ console.log("SEND DATA TO", client.id, data);
	if (reliable) client.messages_send = client.messages_send + 1;
	client.peer.send(reliable ? 1 : 0, packet); // channel number, packet.
}

function send_to_one(message, client, reliable) {
	var JSON = encode_message(message);
	send_to_one_raw(JSON, client, reliable);
}

function send_to_other(message, client, clients, reliable) {
	var JSON = encode_message(message);
	send_to_other_raw(JSON, client, clients, reliable);
}

function disconnect(client, clients) {
	if (_.contains(clients, client) == false) return;
	
	clients_count = clients_count - 1;
	
	// remove client
	var index = clients.indexOf(client);
	if( index != -1) clients.splice(index, 1);
	
	// send leave message
	var leaveMessage = encode_message({channel: "server", cmd: "left", id: client.id});
	_.each(clients, function(c) {
		send_to_one_raw(leaveMessage, c);
	});
}

function client_by_peer(clients, peer) {
	return _.find(clients, function(p) {
		return p.peer._pointer == peer._pointer;
	});
}

setInterval(function() {
	if (clients) {
		var ids = _.map(clients, function(c) { return c.id; });
		var lastActives = _.map(clients, function(c) { return os.uptime() - c.last_active; });
		console.log("CONNECTED IDS", ids);	
		console.log("CONNECTED TIMEOUTS", lastActives);	
		console.log("CONNECTED IDS DATA", clients);	
	
		// disconnect broken clients
		var t = os.uptime();
		_.each(clients, function(c) {
			if (t - c.last_active > 20) {
				console.log("TIMOUET CLIENT", c.id);	
				disconnect(c, clients);
				return;
			}
		});
	} else {
		console.log("NO ONE CONNECTED");
	}
}, 5000 );

var storage = {};

var next_free_client_id = 1;

var bindaddr = new enet.Address('0.0.0.0', 9998);

var server = enet.createServer({
    address: bindaddr, /* the enet.Address to bind the server host to */
    peers:32, /* allow up to 32 clients and/or outgoing connections */
    channels:2, /* allow up to 2 channels to be used, 0 and 1 */
    down:0, /* assume any amount of incoming bandwidth */
    up:0 /* assume any amount of outgoing bandwidth */
});

server.on('connect', function(peer, data) {
    // Peer connected.
    // data is an integer with out-of-band data
    console.log("CONNECT", peer, data);
	// find first free id
	var client_id = next_free_client_id;
	++next_free_client_id;
	
	clients_count = clients_count + 1;
	
	client = {};
	client.id = client_id;
	client.peer = peer;
	clients.push(client);
	client.messages_send = 0;
	client.messages_received = 0;
	
	client.last_active = os.uptime();
	
	var ids = _.map(clients, function(c) { return c.id; });
	
	send_to_other({channel: "server", ids: ids, cmd: "join", id: client.id}, client, clients);
	send_to_one({time: os.uptime(), channel: "server", ids: ids, cmd: "id", id: client.id, first: clients_count == 1, }, client);

}).on('disconnect', function(peer, data) {
    // Peer disconnected.
    console.log("DISCONNECT", peer, data);
    var client = client_by_peer(clients, peer);
    console.log(client);
    disconnect(client, clients);
}).on('message', function(peer, packet, channel)
{
    // Peer sent a message to us in `packet' on `channel'.
	var client = client_by_peer(clients, peer);
	//~ console.log("DATA", packet, peer, channel);
	
	try {
		var message = JSON.parse(packet.data().toString());
		//~ console.log(message);
		
		var reliable = channel == 1;
		
		// only count reliable
		if (reliable) client.messages_received = client.messages_received + 1;

		client.last_active = os.uptime();
		
		if (message.channel == "server") {
			if (message.cmd == "who") {
				console.log("WHO");
				var ids = _.map(clients, function(c) { return c.id; });
				send_to_one({seq: message.seq, ids: ids, fin: true}, client, reliable);
			} else if (message.cmd == "msg") {
				//~ console.log("MSG")
				send_to_one({seq: message.seq, send: client.messages_send, recv: client.messages_received, fin: true}, client, reliable);
			} else if (message.cmd == "restart") {
				console.log("RESTART");
				
				if (message.password == config.adminPassword)
				{			
					send_to_other({channel: "chat", cmd: "text", from: "SERVER", text: "restart in 3 sec", time: os.uptime()}, null, clients, reliable);
					setTimeout(function(){
						send_to_other({channel: "chat", cmd: "text", from: "SERVER", text: "restart in 2 sec", time: os.uptime()}, null, clients, reliable);
					}, 1000);
					setTimeout(function(){
						send_to_other({channel: "chat", cmd: "text", from: "SERVER", text: "restart in 1 sec", time: os.uptime()}, null, clients, reliable);
					}, 2000);
					setTimeout(function(){
						send_to_other({channel: "chat", cmd: "text", from: "SERVER", text: "restart in 0 sec", time: os.uptime()}, null, clients, reliable);
						send_to_other({channel: "server", cmd: "disconnect"}, null, clients, reliable);
					}, 3000);
					setTimeout(function(){
						process.exit();
					}, 4000);
				}
			} else if (message.cmd == "ping") {
				//~ console.log("PING");
				send_to_one({seq: message.seq, time: message.time, lag: toobusy.lag(), fin: true}, client, reliable);
			} else if (message.cmd == "bye") {
				console.log("BYE");
				console.log(client);
				disconnect(client, clients);
			} else if (message.cmd == "time") {
				//~ console.log("TIME");
				send_to_one({seq: message.seq, time: os.uptime(), fin: true}, client, reliable);
			} else if (message.cmd == "get") {
				var key = message.key;
				var value = storage[key];
				if (value === undefined) value = null;
				console.log("GET", key, value);
				send_to_one({seq: message.seq, value: value, fin: true}, client, reliable);
			} else if (message.cmd == "set") {
				var key = message.key;
				var value = message.value;
				console.log("SET", key, value);
				if (key) { storage[key] = value; }
				send_to_one({seq: message.seq, fin: true}, client, reliable);
			}
		} else {
			//~ console.log("DELIVER TO OTHERS");
			send_to_other(message, client, clients, reliable);
		}
	}
	catch(e){}
});

server.start();

console.log("TCP echo server listening on port 9998");
