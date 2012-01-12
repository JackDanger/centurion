(function() {
  var i, _i, _len, _ref;

  See(function() {
    return console.log.apply(this, arguments);
  });

  require.paths.unshift('./vendor');

  require('web');

  _ref = process.argv;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    i = _ref[_i];
    if ('--port' === process.argv[i]) {
      Web.port = process.argv[parseInt(i) + 1];
      require('sys').puts("Starting Centurion web app on port " + Web.port);
      Web.listen(Web.port);
    }
  }

}).call(this);
