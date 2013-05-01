var async = require("async");
var optimist = require("optimist");
var q = require("q");
var synchronized = require("synchronized");
var _ = require("underscore");
var _s = require("underscore.string");
var wilson = require("wilson");
var net = require("net");
var os = require("os");

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
	return JSON.stringify(message) + "\n";
}

function send_to_all(message, clients) {
	var JSON = encode_message(message);
	send_to_all_raw(JSON, clients);
}

function send_to_all_raw(data, clients) {
	_.each(clients, function(c) {
		c.write(data);
	});
}

function send_to_other_raw(data, client, clients) {
	_.each(clients, function(c) {
		if (c != client) c.write(data);
	});
}

function send_to_one_raw(data, client) {
	client.write(data);
}

function send_to_one(message, client) {
	var JSON = encode_message(message);
	send_to_one_raw(JSON, client);
}

function send_to_other(message, client, clients) {
	var JSON = encode_message(message);
	send_to_other_raw(JSON, client, clients);
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

var storage = {};

var next_free_client_id = 1;
var server = null;
server = net.createServer(function (client) {
	// find first free id
	var client_id = next_free_client_id;
	++next_free_client_id;
	
	clients_count = clients_count + 1;
	
	client.id = client_id;
	client.unprocessed = new Buffer(0);
	clients.push(client);
	
	var ids = _.map(clients, function(c) { return c.id; });
	
	send_to_other({channel: "server", ids: ids, cmd: "join", id: client.id}, client, clients);
	send_to_one({time: os.uptime(), channel: "server", ids: ids, cmd: "id", id: client.id, first: clients_count == 1, }, client);
	client.on("data", function(data) {
		if (client.unprocessed == null) client.unprocessed = data;
		else client.unprocessed = Buffer.concat([client.unprocessed, data]);

		while (true) {
			var t = decode_message(client.unprocessed);
			var message = t.msg;
			var rest = t.rest;
			
			client.unprocessed = rest;
		
			if (message == null) break;
			
			console.log("RECEIVED", JSON.stringify(message), client.unprocessed ? "<"+client.unprocessed.length+">" : "<>");
			
			if (message.channel == "server") {
				if (message.cmd == "who") {
					console.log("WHO");
					var ids = _.map(clients, function(c) { return c.id; });
					send_to_one({seq: message.seq, ids: ids, fin: true}, client);
				} else if (message.cmd == "ping") {
					console.log("PING");
					send_to_one({seq: message.seq, time: message.time, fin: true}, client);
				} else if (message.cmd == "time") {
					console.log("TIME");
					send_to_one({seq: message.seq, time: os.uptime(), fin: true}, client);
				} else if (message.cmd == "get") {
					var key = message.key;
					var value = storage[key];
					if (value === undefined) value = null;
					console.log("GET", key, value);
					send_to_one({seq: message.seq, value: value, fin: true}, client);
				} else if (message.cmd == "set") {
					var key = message.key;
					var value = message.value;
					console.log("SET", key, value);
					if (key) { storage[key] = value; }
					send_to_one({seq: message.seq, fin: true}, client);
				}
			} else {
				//~ console.log("DELIVER TO OTHERS");
				send_to_other(message, client, clients);
			}
		}
	});
	
	client.on("end", function() {
		disconnect(client, clients);
		console.log("end", client.id);
	});
	
	client.on("close", function() {
		disconnect(client, clients);
		console.log("close", client.id);
	});
	
	client.on("error", function() {
		disconnect(client, clients);
		console.log("error", client.id);
	});
	
	client.on("timeout", function() {
		disconnect(client, clients);
		console.log("timeout", client.id);
	});

}).listen(9999);

console.log("TCP echo server listening on port 9999");
