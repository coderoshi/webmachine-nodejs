var vows   = require('vows'),
    assert = require('assert'),
    net    = require('net'),
    http   = require('http'),
    wm     = require('../lib/webmachine');

var port = 9000;
var baseUrl = '127.0.0.1';

vows.describe('Server').addBatch({
  'create a route and start webmachine': {
    topic: function () {
      var self = this;
      root = {
        route: "/",
        serviceAvailable: function(req, res, next) {
          next(false);
        },
        finishRequest: function(req, res) {
          self.callback(undefined, req, res);
        },
      };
      wm.add(root);
      wm.start(port, baseUrl);

      http.get('http://'+baseUrl+':'+port+'/');

      // TODO: need to turn this off?
      setTimeout(function() {
        self.callback('timeout');
      }, 3000)
    },
    'and service is not available': function (err, req, res, next) {
      assert.notEqual(err, 'timeout');
      assert.equal(res.statusCode(), 503);
      wm.server.close()
    }
  }
}).export(module);
