
/**
 * Module dependencies.
 */

var express = require('express')
  , http = require('http')
  , fs = require('fs')
  , path = require('path')
  , winston = require('winston')
  , config = require('../config.js');

var _ = require('underscore');
var _s = require('underscore.string');

var app = express();

// dummy database

var log = function(req) {
	var s = '';
	for (var i = 1; i < arguments.length; i++) {
		s += arguments[i] + ' ';
	}
	if (req && req.session && req.session.user && req.session.user.name) {
		s = "[WEB user=" + req.session.user.name + "] " + s;
	}
	else
	{
		s = "[WEB] " + s;
	}
	winston.info(s);
};

app.configure(function(){
  app.set('port', config.webPort);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.methodOverride());
  app.use(express.bodyParser());
  app.use(require('stylus').middleware(__dirname + '/public'));
  app.use(express.static(path.join(__dirname, 'public')));
  app.use(express.cookieParser('shhhh, very secret'));
  app.use(express.session());
  //Session-persisted message middleware
  app.use(function(req, res, next){
	  var err = req.session.error
	    , msg = req.session.success;
	  delete req.session.error;
	  delete req.session.success;
	  res.locals.message = '';
	  if (err) res.locals.message = '<p class="msg error">' + err + '</p>';
	  if (msg) res.locals.message = '<p class="msg success">' + msg + '</p>';
	  next();
	});
  app.use(app.router);
});


app.configure('development', function(){
  app.use(express.errorHandler());
});



function readJsonFile(filename, defaultContent)
{
	        try {
			                return JSON.parse(fs.readFileSync(filename));
					        } catch(e) {
							console.log(e);
							                return defaultContent;
									        }
}

function writeJsonFile(filename, jsonObj)
{
	        fs.writeFileSync(filename, JSON.stringify(jsonObj));
}


// ---------------------------------------------------------------

app.get("/online_history", function(req, res) {
	res.set('Content-Type', 'plain/text');
	res.set('Cache-Control', 'no-cache');
	var h = readJsonFile("online_history.json", {"history":{}, "current":0});
	var out = "Date,Users\n";
	_.each(h["history"], function(v,k){
		out = out + k + "," + v + "\n";
	});
	res.send(out);
});

app.get("/online_current", function(req, res) {
	res.set('Content-Type', 'plain/text');
	res.set('Cache-Control', 'no-cache');
	var h = readJsonFile("online_history.json", {"history":{}, "current":0});
	var out = "Users\n" + h["current"];
	res.send(out);
});

app.get("/stats/:name", function(req, res) {
	res.set('Content-Type', 'text/plain');
	res.set('Cache-Control', 'no-cache');
	res.send("" + globals.stats[req.params.name]);
});

http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});

module.exports = app;
