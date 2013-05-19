var _         = require('underscore'),
    vows      = require('vows'),
    assert    = require('assert'),
    Resource  = require('../lib/resource'),
    Fsm       = require('../lib/fsm');

vows.describe('FSM Encoding').addBatch({
  'given all encodings': {
    topic: function () {
      root = {
        route: '/'
      };
      var resource = new Resource(root);
      var fsm = new Fsm(resource);
      var identityFunc = function(x){ return x; };
      var provided = {"deflate":identityFunc,"identity":identityFunc};
      var acceptencoding = '*';
      var encoding = fsm.doChooseEncoding(provided, acceptencoding);
      this.callback(true, encoding);
    },
    'default to identity': function (passed, charset) {
      assert.equal(charset, 'identity');
    }
  },
  'given identity encoding': {
    topic: function () {
      root = {
        route: '/'
      };
      var resource = new Resource(root);
      var fsm = new Fsm(resource);
      var identityFunc = function(x){ return x; };
      var provided = {"deflate":identityFunc,"identity":identityFunc};
      var acceptencoding = 'identity';
      var encoding = fsm.doChooseEncoding(provided, acceptencoding);
      this.callback(true, encoding);
    },
    'choose identity': function (passed, charset) {
      assert.equal(charset, 'identity');
    }
  },
  'given deflate encoding': {
    topic: function () {
      root = {
        route: '/'
      };
      var resource = new Resource(root);
      var fsm = new Fsm(resource);
      var identityFunc = function(x){ return x; };
      var provided = {"deflate":identityFunc,"identity":identityFunc};
      var acceptencoding = 'deflate';
      var encoding = fsm.doChooseEncoding(provided, acceptencoding);
      this.callback(true, encoding);
    },
    'choose deflate': function (passed, charset) {
      assert.equal(charset, 'deflate');
    }
  },
  'given no valid encoding': {
    topic: function () {
      root = {
        route: '/'
      };
      var resource = new Resource(root);
      var fsm = new Fsm(resource);
      var identityFunc = function(x){ return x; };
      var provided = {"identity":identityFunc};
      var acceptencoding = 'derp';
      var encoding = fsm.doChooseEncoding(provided, acceptencoding);
      this.callback(true, encoding);
    },
    'choose null': function (passed, charset) {
      assert.equal(charset, null);
    }
  }
  // check that * works against a lower q match
}).export(module);
