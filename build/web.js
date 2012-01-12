(function() {
  var Web, http, sys, url, util;

  sys = require('sys');

  util = require('util');

  http = require('http');

  url = require('url');

  Web = http.createServer(request, response)(function() {
    var uri;
    uri = url.parse(request.url, true);
    sys.puts(request.url);
    if ('/' === uri.pathname) {
      sys.puts('found!');
      response.writeHead(200, {
        'Content-Type': 'text/html'
      });
      return response.end('<html>H1 there</html>');
    } else if ('/hosts' === uri.pathname) {
      response.writeHead(200, {
        'Content-Type': 'application/json'
      });
      return riak.getHosts(function() {
        return hosts(response.end(JSON.stringify(hosts)));
      });
    } else if ('/sessions' === uri.pathname) {
      response.writeHead(200, {
        'Content-Type': 'application/json'
      });
      return riak.getSessions(uri.query['host'], function() {
        return sessions(response.end(JSON.stringify(sessions)));
      });
    } else if ('/paths' === uri.pathname) {
      response.writeHead(200, {
        'Content-Type': 'application/json'
      });
      return riak.getPaths(uri.query['host'], uri.query['session'], function() {
        return sessions(response.end(JSON.stringify(sessions)));
      });
    } else {
      response.writeHead(200, {
        'Content-Type': 'text/html'
      });
      return response.end('Error: could not find "' + uri.pathname + '"');
    }
  });

}).call(this);
