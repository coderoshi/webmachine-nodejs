var _         = require('underscore'),
    vows      = require('vows'),
    assert    = require('assert'),
    net       = require('net'),
    http      = require('http'),
    url       = require('url'),
    scenarios = require("./scenarios.js"),
    iced      = require('iced-coffee-script'),
    Resource  = require('../lib/resource'),
    ResData   = require('../lib/responseData'),
    ReqData   = require('../lib/requestData'),
    FSM       = require('../lib/fsm'),
    wm        = require('../lib/webmachine');

var port = 9000;
var baseUrl = '127.0.0.1';

var test = _.find(scenarios, function(val){
  return val.name == process.env.TEST;
});

function buildTest(test) {
  return {
    topic: function () {
      var self = this;

      headers = {}
      _.each(test.headers, function(value, header){
        headers[header.toLowerCase()] = value;
      });
      var mockNodeReq = {
        method: test.method,
        headers: headers
      };
      var mockNodeRes = {
        end: function(){
          // console.log('done');
        },
        writeHead: function(code, header){
          this.statusCode = code;
          this.header = header;
        },
        setHeader: function(field, header){
          if(!this.header) {
            this.header = {};
          }
          this.header[field] = header;
        },
        write: function(data) {
          this.body = data;
        }
      };
      var mockResource = {
        route: "/",
        finishRequest: function(req, res) {
          self.callback(undefined, req, res);
        },
        toHtml: function(req, res, next) {
          next("<html/>");
        }
      }
      _.each(test.appConfig, function(val, key){
        if(!mockResource[key]) {
          // functions are called straight-up
          if(typeof(val) === 'function') {
            mockResource[key] = val;
          // synchs should return values
          } else if(key.match(/Sync$/)) {
            mockResource[key] = function(req, res) {
              return val;
            };
          // everything else is a callback result
          } else {
            mockResource[key] = function(req, res, next) {
              next(val);
            };
          }
        }
      });
      var resource = new Resource(mockResource);

      var req = new ReqData(mockNodeReq, url.parse('/', true), {});
      var res = new ResData(mockNodeRes);
      res.trace = [];
      var fsm = new FSM(resource, res.trace);
      fsm.run(req, res);
    },
    'and is correct': function (err, req, res) {
      assert.notEqual(res, undefined, 'res is required');
      assert.notEqual(req, undefined, 'req is required');
      // TODO: Use path
      // TODO: Check headers
      // assert.equal(res.statusCode(), test.checkStatus);
      assert.deepEqual(res.trace, test.checkStack);
    }
  };
}

function runTests(testName) {
  var tests = {};
  if(testName) {
    var test = _.find(scenarios, function(val){
      return val.name == testName;
    });
    tests[test.name] = buildTest(test);
  }
  else {
    for(var i=0; i < scenarios.length; i++) {
      test = scenarios[i];
      tests[test.name] = buildTest(test);
    }
  }
  vows.describe('FSM').addBatch(tests).export(module);
}

runTests(process.env.TEST);
