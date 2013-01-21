var 
  _ = require('underscore'),
  http = require('http'),
  url = require('url'),
  util = require('./util'),
  Fsm = require('./fsm'),
  ResData = require('./responseData'),
  ReqData = require('./requestData'),
  Resource = require('./resource');

var Webmachine;
Webmachine = (function() {

  function Webmachine() {
    this.resources = [];
  }

  Webmachine.prototype.add = function(resource) {
    resource.routeRe = util.pathRegexp(resource.route, (resource.routeReKeys = []), false, false);
    return this.resources.push(resource);
  };

  Webmachine.prototype.start = function(port, ipaddr) {
    var _this = this;
    this.server = http.createServer(function(req, res) {
      var fsm, match, pathInfo, rd, resource, rs, urlForm;
      urlForm = url.parse(req.url, true);
      if (match = _this.match(urlForm)) {
        resource = match[0], pathInfo = match[1];
        rd = new ReqData(req, urlForm, pathInfo);
        rs = new ResData(res);
        resource = new Resource(resource);
        fsm = new Fsm(resource);
        return fsm.run(rd, rs);
      } else {
        res.writeHead(404, {
          'Content-Type': 'text/plain'
        });
        res.write('File Not Found');
        return res.end();
      }
    });
    return this.server.listen(port, ipaddr);
  };

  Webmachine.prototype.match = function(urlForm) {
    var i, key, keys, m, pathInfo, r, resource, val, _i, _j, _len, _ref, _ref1;
    pathInfo = {};
    r = null;
    _ref = this.resources;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      resource = _ref[_i];
      keys = resource.routeReKeys;
      m = resource.routeRe.exec(urlForm.pathname);
      if (!m) continue;
      for (i = _j = 1, _ref1 = m.length; 1 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 1 <= _ref1 ? ++_j : --_j) {
        key = keys[i - 1];
        val = 'string' === typeof m[i] ? decodeURIComponent(m[i]) : m[i];
        pathInfo[key.name] = val;
      }
      r = resource;
      break;
    }
    if (r) {
      return [r, pathInfo];
    } else {
      return null;
    }
  };

  return Webmachine;

})();

module.exports = new Webmachine();
