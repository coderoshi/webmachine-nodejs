var _         = require('underscore'),
    vows      = require('vows'),
    assert    = require('assert'),
    Resource  = require('../lib/resource'),
    Fsm       = require('../lib/fsm');



vows.describe('FSM Charset').addBatch({
  'given a charset': {
    topic: function () {
      root = {
        route: '/'
      };
      var resource = new Resource(root);
      var fsm = new Fsm(resource);
      var potentials = ["utf-8"];
      var acceptcharset = 'ISO-8859-1,utf-8;q=0.7,*;q=0.3';
      var defaultEnc = "utf-8";
      var charset = fsm.doChooseCharset(potentials, acceptcharset, defaultEnc);
      this.callback(true, charset);
    },
    'default to utf8': function (passed, charset) {
      assert.equal(charset, 'utf-8');
    }
  }
  // define a ISO-8859-1 function, choose that
  // check that * works against a lower q match
}).export(module);
