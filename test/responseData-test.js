var vows    = require('vows'),
    assert  = require('assert'),
    net     = require('net'),
    http    = require('http'),
    ResData = require('../lib/responseData');

vows.describe('Server').addBatch({
  'create a valid ResData': {
    topic: function () {
      nodeRes = {
        statusCode: 200,
      };
      resData = new ResData(nodeRes);
      resData.setRespHeader('Location', '/tmp');
      resData.setRespBody('data');
      resData.doRedirect(true);
      resData.setDispPath('/tmp');
      resData.setReqBody(true);
      this.callback(undefined, resData);
    },
    'and fields exist': function (err, resData) {
      assert.equal(err, undefined);
      assert(resData.headers);
      assert(resData.res);
    },
    'and respHeaders': function (err, resData) {
      assert(resData.respHeaders());
      assert.equal(resData.respHeaders()['Location'], '/tmp');
    },
    'and getRespHeader': function (err, resData) {
      assert.equal(resData.getRespHeader('Location'), '/tmp');
      assert.equal(resData.getRespHeader('derp'), null);
    },
    'and respRedirect': function (err, resData) {
      assert.equal(resData.respRedirect(), true);
    },
    'and dispPath': function (err, resData) {
      assert.equal(resData.dispPath, '/tmp');
    },
    'and reqBody': function (err, resData) {
      assert.equal(resData.reqBody, true);
    },
    'and statusCode': function (err, resData) {
      assert.equal(resData.statusCode(), 200);
    }
  }
}).export(module);
