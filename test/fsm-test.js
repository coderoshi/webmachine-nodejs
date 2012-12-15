var vows      = require('vows'),
    assert    = require('assert'),
    net       = require('net'),
    http      = require('http'),
    url       = require('url'),
    scenarios = require("./scenarios.js"),
    iced      = require('iced-coffee-script'),
    ResData   = require('../lib/responseData'),
    ReqData   = require('../lib/requestData'),
    FSM       = require('../lib/fsm'),
    wm        = require('../lib/webmachine');

var port = 9000;
var baseUrl = '127.0.0.1';

function buildTest(test) {
  return {
    topic: function () {
      var self = this;

      mockNodeReq = {
        method: test.method
      };
      mockNodeRes = {
        end: function(){
          // console.log('done');
        }
      };
      mockResource = {
        route: "/",
        serviceAvailable: function(req, res, next) {
          if(typeof(test.appConfig.serviceAvailable) == 'undefined') {
            next(true);
          } else {
            next(test.appConfig.serviceAvailable);
          }
        },
        knownMethodsSync: function(req, res) {
          if(typeof(test.appConfig.knownMethodsSync) == 'undefined') {
            return ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE', 'CONNECT', 'OPTIONS'];
          } else {
            return test.appConfig.knownMethodsSync;
          }
        },
        finishRequest: function(req, res) {
          self.callback(undefined, req, res);
        },
      };

      req = new ReqData(mockNodeReq, url.parse('/', true), {});
      res = new ResData(mockNodeRes);
      fsm = new FSM(mockResource);
      fsm.run(req, res);
    },
    'and result is correct': function (err, req, res) {
      assert.notEqual(res, undefined, 'res is required');
      assert.notEqual(req, undefined, 'req is required');
      assert.equal(res.statusCode(), test.checkStatus);
    }
  };
}

tests = {};

for(var i=0; i < scenarios.length; i++) {
  test = scenarios[i];
  tests[test.name] = buildTest(test);
}

vows.describe('FSM').addBatch(tests).export(module);
