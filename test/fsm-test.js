var vows      = require('vows'),
    assert    = require('assert'),
    net       = require('net'),
    http      = require('http'),
    url       = require('url'),
    scenarios = require("./scenarios.js"),
    iced      = require('iced-coffee-script'),
    ResData   = require('../lib/response_data'),
    ReqData   = require('../lib/request_data'),
    FSM       = require('../lib/fsm'),
    wm        = require('../lib/webmachine');

var port = 9000;
var baseUrl = '127.0.0.1';

tests = {};

test = scenarios[0];

tests[test.name] = {
  topic: function () {
    var self = this;

    mockNodeReq = {
      method: test.method
    };
    mockNodeRes = {
      end: function(){
        console.log('done');
      }
    };
    mockResource = {
      route: "/",
      service_available: function(req, res, next) {
        self.callback(undefined, req, res, next);
      }
    };

    req = new ReqData(mockNodeReq, url.parse('/', true), {});
    res = new ResData(mockNodeRes);
    fsm = new FSM(mockResource, req, res);
    fsm.run();
    
    // self.callback(undefined, req, res, function(reply){});
  },
  'and result is correct': function (err, req, res, next) {
    // assert.notEqual(err, 'timeout');
    assert.notEqual(next, undefined, 'next is required');
    assert.notEqual(res, undefined, 'res is required');
    assert.notEqual(req, undefined, 'req is required');
    next(false);
    assert.equal(res.statusCode(), test.checkStatus);
  }
}

vows.describe('FSM').addBatch(tests).export(module);
