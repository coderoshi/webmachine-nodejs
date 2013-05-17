var _         = require('underscore'),
    jsc       = require('./jscheck'),
    vows      = require('vows'),
    assert    = require('assert'),
    Resource  = require('../lib/resource');

var JSC = jsc.JSC;

vows.describe('JS Quickcheck').addBatch({
  'given random values': {
    topic: function () {
      var self = this;

      JSC.clear();

      // JSC.detail(4);
      // JSC.on_report(function(str) {
      //   console.log(str);
      // });

      JSC.on_result(function(result) {
        self.callback(result.pass, result.fail);
      });

      JSC.test("Test nothing at all", function(verdict, password, maxScore) {
        return verdict(9 < password.length);
      }, [
        JSC.string(JSC.integer(10, 20), JSC.character('a', 'z')),
        JSC.literal(26)
      ]);

    },
    'receive zero failues': function (passed, failed) {
      assert.equal(failed, 0);
    }
  }
}).export(module);

