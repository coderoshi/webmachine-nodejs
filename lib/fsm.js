var _ = require('underscore');

var __bind = function(fn, me){
  return function(){
    // return fn.apply(me, arguments);
    fn.apply(me, arguments);
  };
};

function FSM(resource, trace) {
  this.resource = resource;
  this.metadata = {};
  this.trace = trace;

  this.v3p11 = __bind(this.v3p11, this);
  this.v3p3 = __bind(this.v3p3, this);
  this.v3o20 = __bind(this.v3o20, this);
  this.v3o18b = __bind(this.v3o18b, this);
  this.v3o18 = __bind(this.v3o18, this);
  this.v3o16 = __bind(this.v3o16, this);
  this.v3o14 = __bind(this.v3o14, this);
  this.v3n16 = __bind(this.v3n16, this);
  this.v3n11 = __bind(this.v3n11, this);
  this.stage1Ok = __bind(this.stage1Ok, this);
  this.v3n5 = __bind(this.v3n5, this);
  this.v3m20b = __bind(this.v3m20b, this);
  this.v3m20 = __bind(this.v3m20, this);
  this.v3m16 = __bind(this.v3m16, this);
  this.v3m7 = __bind(this.v3m7, this);
  this.v3m5 = __bind(this.v3m5, this);
  this.v3l17 = __bind(this.v3l17, this);
  this.v3l15 = __bind(this.v3l15, this);
  this.v3l14 = __bind(this.v3l14, this);
  this.v3l13 = __bind(this.v3l13, this);
  this.v3l7 = __bind(this.v3l7, this);
  this.v3l5 = __bind(this.v3l5, this);
  this.v3k13 = __bind(this.v3k13, this);
  this.v3k7 = __bind(this.v3k7, this);
  this.v3k5 = __bind(this.v3k5, this);
  this.v3j18 = __bind(this.v3j18, this);
  this.v3i13 = __bind(this.v3i13, this);
  this.v3i12 = __bind(this.v3i12, this);
  this.v3i7 = __bind(this.v3i7, this);
  this.v3i4 = __bind(this.v3i4, this);
  this.v3h12 = __bind(this.v3h12, this);
  this.v3h11 = __bind(this.v3h11, this);
  this.v3h10 = __bind(this.v3h10, this);
  this.v3h7 = __bind(this.v3h7, this);
  this.v3g11 = __bind(this.v3g11, this);
  this.v3g9 = __bind(this.v3g9, this);
  this.v3g8 = __bind(this.v3g8, this);
  this.v3g7 = __bind(this.v3g7, this);
  this.v3f7 = __bind(this.v3f7, this);
  this.v3f6 = __bind(this.v3f6, this);
  this.v3e6 = __bind(this.v3e6, this);
  this.v3e5 = __bind(this.v3e5, this);
  this.v3d5 = __bind(this.v3d5, this);
  this.v3d4 = __bind(this.v3d4, this);
  this.v3c4 = __bind(this.v3c4, this);
  this.v3c3 = __bind(this.v3c3, this);
  this.v3b3 = __bind(this.v3b3, this);
  this.v3b4 = __bind(this.v3b4, this);
  this.v3b5 = __bind(this.v3b5, this);
  this.v3b6 = __bind(this.v3b6, this);
  this.v3b7 = __bind(this.v3b7, this);
  this.v3b8 = __bind(this.v3b8, this);
  this.v3b9 = __bind(this.v3b9, this);
  this.v3b10 = __bind(this.v3b10, this);
  this.v3b11 = __bind(this.v3b11, this);
  this.v3b12 = __bind(this.v3b12, this);
  this.v3b13b = __bind(this.v3b13b, this);
  this.v3b13 = __bind(this.v3b13, this);

  this.acceptHelper = __bind(this.acceptHelper, this);
  this.encodeBody = __bind(this.encodeBody, this);
  this.respond = __bind(this.respond, this);
  this.run = __bind(this.run, this);
}

FSM.prototype.decisionTest = function(test, req, res, value, iftrue, iffalse) {
  var self = this;
  if (test != null) {
    switch (typeof test) {
      case 'function':
        test(req, res, function(testReply) {
          var headers = {};
          if (value === testReply) {
            self.d(req, res, iftrue, headers);
          } else if (typeof testReply === 'number') {
            self.respond(req, res, testReply, {});
          } else {
            self.d(req, res, iffalse, headers);
          }
        });
        break;
      default:
        if (test === value) {
          this.d(req, res, iftrue, headers);
        } else {
          this.d(req, res, iffalse, headers);
        }
    }
  } else {
    var headers = {};
    if (test === null && test === value || value) {
      this.d(req, res, iftrue, headers);
    } else {
      this.d(req, res, iffalse, headers);
    }
  }
};

FSM.prototype.d = function(req, res, reply, headers) {
  if (headers == null) headers = {};
  if (typeof reply === 'number') {
    this.respond(req, res, reply, {});
  } else if (typeof reply === 'function') {
    reply(req, res);
  } else {
    throw "Only numbers and functions are expected";
  }
};

FSM.prototype.errorResponse = function(req, res, message) {
  throw message;
};

FSM.prototype.respond = function(req, res, code, headers) {
  if (headers == null) headers = {};
  headers || (headers = {});
  res.headers = _.extend(res.headers, headers);
  switch (code) {
    case 404:
      res.res.writeHead(404, {
        'Content-Type': 'text/plain'
      });
      res.res.statusCode = 404;
      res.res.write('File Not Found');
      // return res.res.end();
      break;
    case 304:
      delete res.headers['Content-Type'];
      break;
    default:
      if(res.respBody()) {
        res.res.write(res.respBody());
      }
  }
  res.res.statusCode = code;
  // TODO: write head breaks chunked encoding?
  // Content-Length
  // res.res.writeHead(code, res.headers);
  if (this.resource.finishRequest != null) {
    this.resource.finishRequest(req, res);
  }
  return res.res.end();
};

FSM.prototype.getHeaderVal = function(req, field) {
  return this.unquoteHeader(req.getReqHeader(field));
};

FSM.prototype.chooseMediaType = function(provided, accept) {
  var requested,
    _this = this;
  requested = accept.split(/\s*,\s*/).map(function(mt) {
    return mt;
  });
  return _.find(provided, function(providedMT) {
    return _.find(requested, function(requestedMT) {
      return requestedMT === '*/*' || providedMT === requestedMT;
    });
  });
};

FSM.prototype.chooseCharset = function(req, res, charset) {
  var charsets, chosenCharset, provided;
  provided = this.resource.charsetsProvidedSync(req, res);
  if (_.isEmpty(provided)) {
    return 'utf-8';
  } else {
    charsets = _.keys(provided);
    if (chosenCharset = this.doChooseCharset(charsets, charset, 'utf-8')) {
      return this.metadata['Chosen-Charset'] = chosenCharset;
    }
  }
  return null;
};

FSM.prototype.doChooseCharset = function(charsets, charset, defaultEnc) {
  var accepted, acceptedCharsets, any_ok, choices, chosen, default_ok, default_priority, star_priority,
    _this = this;
  choices = _.map(charsets, function(s) {
    return s.toLowerCase();
  });
  acceptedCharsets = charset.split(/\s*,\s*/);
  accepted = acceptedCharsets.map(function(cs) {
    cs = cs.split(';');
    var ct = cs[0];
    var q =  cs[1];
    if(q) q = q.split('=')[1]
    if(q) q = parseFloat(q);
    q = q || 1.0;
    return [q, ct.toLowerCase()];
  });
  if (_.contains(acceptedCharsets, defaultEnc)) {
    default_priority = 1.0;
  } else {
    default_priority = 0.0;
  }
  if (_.contains(acceptedCharsets, '*')) {
    star_priority = 1.0;
  } else {
    star_priority = 0.0;
  }
  default_ok = (default_priority === null && star_priority !== 0.0) || default_priority;
  any_ok = star_priority && star_priority > 0.0;
  chosen = _.find(accepted, function(value) {
    var acceptable, priority;
    priority = value[0];
    acceptable = value[1];
    if (priority === 0.0) {
      choices = _.without(choices, acceptable);
      return false;
    } else {
      return _.contains(choices, acceptable);
    }
  });
  if (chosen && chosen[1]) {
    return chosen[1];
  } else if (any_ok && choices[0]) {
    return choices[0];
  } else if (default_ok && _.contains(choices, defaultEnc) && defaultEnc) {
    return defaultEnc;
  }
};

FSM.prototype.chooseEncoding = function(req, res, encoding) {
  var provided = this.resource.encodingsProvidedSync(req, res);
  accepted_encoding = this.doChooseEncoding(provided, encoding);
  return this.metadata['accept-encoding'] = accepted_encoding;
};

FSM.prototype.doChooseEncoding = function(provided, encoding) {
  var accepted = encoding.split(/,\s*/);
  var match = _.isEmpty(provided);
  var accepted_encoding = null;
  if (match) accepted_encoding = accepted[0];
  var accept;
  while (!match && accepted.length) {
    accept = accepted.shift().split(/\s*;\s*/)[0].toLowerCase();
    match = (accept === "*") || (provided[accept] != null);
    if (match) accepted_encoding = accept;
  }
  // TODO: this is a lame catchall
  if(accepted_encoding === '*') {
    accepted_encoding = _.first(_.keys(provided));
  }
  return accepted_encoding;
};

FSM.prototype.variances = function(req, res) {
  var accept = this.resource.contentTypesProvidedSync(req, res).length > 1 ? ["Accept"] : [];
  var acceptEncoding = this.resource.encodingsProvidedSync(req, res).length > 1 ? ["Accept-Encoding"] : [];
  var acceptCharset = this.resource.charsetsProvidedSync(req, res).length > 1 ? ["Accept-Charset"] : [];
  return _.union(accept, acceptEncoding, acceptCharset, this.resource.variancesSync(req, res));
};

FSM.prototype.unquoteHeader = function(header) {
  if (header) {
    return header.replace(/^"(.*?)"$/, '$1');
  } else {
    return null;
  }
};

FSM.prototype.convertRequestDate = function(dateStr) {
  if (dateStr === null || dateStr === '') return null;
  var date = new Date(dateStr);
  if (isNaN(date.getTime())) date = null;
  return date;
};

FSM.prototype.encodeBody = function(req, res) {
  return null;
};

FSM.prototype.acceptHelper = function(req, res, next) {
  var ct = this.getHeaderVal(req, 'content-type') || "application/octet-stream";
  var mt = ct.split(';')[0];
  var contentTypesAccepted = this.resource.contentTypesAcceptedSync();
  var func = null;
  if (contentTypesAccepted != null) func = contentTypesAccepted[mt];
  if (func != null) {
    return func.apply(this.resource, [
      req, res, function(result) {
        return next(result);
      }
    ]);
  } else {
    return next(415);
  }
};


FSM.prototype.run = function(req, res) {
  this.v3b13(req, res);
};

FSM.prototype.tracePush = function(step) {
  if (this.trace != null) this.trace.push(step);
};

FSM.prototype.v3b13 = function(req, res) {
  this.tracePush('v3b13');
  this.decisionTest(this.resource.ping, req, res, 'pong', this.v3b13b, 503);
};

FSM.prototype.v3b13b = function(req, res) {
  this.tracePush('v3b13b');
  this.decisionTest(this.resource.serviceAvailable, req, res, true, this.v3b12, 503);
};

FSM.prototype.v3b12 = function(req, res) {
  var _this = this;
  this.tracePush('v3b12');
  this.decisionTest(function(req, res, next) {
    next(_.contains(_this.resource.knownMethodsSync(req, res), req.method));
  }, req, res, true, this.v3b11, 501);
};

FSM.prototype.v3b11 = function(req, res) {
  this.tracePush('v3b11');
  this.decisionTest(this.resource.uriTooLong, req, res, true, 414, this.v3b10);
};

FSM.prototype.v3b10 = function(req, res) {
  this.tracePush('v3b10');
  var self = this;
  this.decisionTest(function(req, res, next) {
    if (self.resource.allowedMethodsSync != null) {
      if (_.contains(self.resource.allowedMethodsSync(req, res), req.method)) {
        next(true);
      } else {
        res.headers["Allow"] = self.resource.allowedMethodsSync(req, res).join(", ");
        next(false);
      }
    } else {
      next(true);
    }
  }, req, res, true, this.v3b9, 405);
};

FSM.prototype.v3b9 = function(req, res) {
  this.tracePush('v3b9');
  this.decisionTest(this.resource.malformedRequest, req, res, true, 400, this.v3b8);
};

FSM.prototype.v3b8 = function(req, res) {
  this.tracePush('v3b8');
  var self = this;
  this.decisionTest(function(req, res, next) {
    if (self.resource.isAuthorized != null) {
      self.resource.isAuthorized(req, res, function(reply) {
        switch (typeof reply) {
          case 'string':
            res.headers['WWW-Authenticate'] = reply;
            next(401);
            break;
          case 'number':
          case 'boolean':
            next(reply);
            break;
        }
      });
    } else {
      next(true);
    }
  }, req, res, true, this.v3b7, 401);
};

FSM.prototype.v3b7 = function(req, res) {
  this.tracePush('v3b7');
  this.decisionTest(this.resource.forbidden, req, res, true, 403, this.v3b6);
};

FSM.prototype.v3b6 = function(req, res) {
  this.tracePush('v3b6');
  this.decisionTest(this.resource.validContentHeaders, req, res, true, this.v3b5, 501);
};

FSM.prototype.v3b5 = function(req, res) {
  this.tracePush('v3b5');
  this.decisionTest(this.resource.knownContentType, req, res, true, this.v3b4, 415);
};

FSM.prototype.v3b4 = function(req, res) {
  this.tracePush('v3b4');
  this.decisionTest(this.resource.validEntityLength, req, res, true, this.v3b3, 413);
};

FSM.prototype.v3b3 = function(req, res) {
  this.tracePush('v3b3');
  var self = this;
  this.decisionTest(function(req, res, next) {
    if (req.method === 'OPTIONS') {
      var hdrs = self.resource.optionsSync(req, res);
      self.respond(req, res, 200, hdrs);
    } else {
      next(false);
    }
  }, req, res, true, 200, this.v3c3);
};

FSM.prototype.v3c3 = function(req, res) {
  this.tracePush('v3c3');
  var self = this;
  this.decisionTest(function(req, res, next) {
    var accept = self.getHeaderVal(req, 'accept');
    if (!accept) {
      self.metadata['Content-Type'] = _.first(_.keys(self.resource.contentTypesProvidedSync(req, res)));
      next(true);
    } else {
      next(false);
    }
  }, req, res, true, this.v3d4, this.v3c4);
};

FSM.prototype.v3c4 = function(req, res) {
  this.tracePush('v3c4');
  var self = this;
  this.decisionTest(function(req, res, next) {
    var chosenType, types;
    types = _.keys(self.resource.contentTypesProvidedSync(req, res));
    chosenType = self.chooseMediaType(types, self.getHeaderVal(req, 'accept'));
    if (chosenType) {
      self.metadata['Content-Type'] = chosenType;
      next(true);
    } else {
      next(406);
    }
  }, req, res, true, this.v3d4, 406);
};

FSM.prototype.v3d4 = function(req, res) {
  this.tracePush('v3d4');
  this.decisionTest(this.getHeaderVal(req, "accept-language"), req, res, null, this.v3e5, this.v3d5);
};

FSM.prototype.v3d5 = function(req, res) {
  this.tracePush('v3d5');
  this.decisionTest(this.resource.languageAvailable, req, res, true, this.v3e5, 406);
};

FSM.prototype.v3e5 = function(req, res) {
  this.tracePush('v3e5');
  if (this.getHeaderVal(req, "accept-charset")) {
    this.d(req, res, this.v3e6);
  } else {
    this.decisionTest(this.chooseCharset(req, res, "*"), req, res, null, 406, this.v3f6);
  }
};

FSM.prototype.v3e6 = function(req, res) {
  this.tracePush('v3e6');
  this.decisionTest(this.chooseCharset(req, res, this.getHeaderVal(req, "accept-charset")), req, res, null, 406, this.v3f6);
};

FSM.prototype.v3f6 = function(req, res) {
  this.tracePush('v3f6');
  var chosenType = this.metadata['Content-Type'];
  var chosenCharset = this.metadata['Charset']
  if (chosenCharset) {
    chosenType.params['charset'] = chosenCharset;
  }
  res.headers['Content-Type'] = chosenType;
  if (!this.getHeaderVal(req, "accept-encoding")) {
    this.decisionTest(this.chooseEncoding(req, res, "identity;q=1.0,*;q=0.5"), req, res, null, 406, this.v3g7);
  } else {
    this.d(req, res, this.v3f7);
  }
};

FSM.prototype.v3f7 = function(req, res) {
  this.tracePush('v3f7');
  this.decisionTest(this.chooseEncoding(req, res, this.getHeaderVal(req, "accept-encoding")), req, res, null, 406, this.v3g7);
};

FSM.prototype.v3g7 = function(req, res) {
  this.tracePush('v3g7');
  var variances = this.variances();
  if ((variances != null ? variances.length : void 0) > 0) {
    res.headers['Vary'] = variances.join(", ");
  }
  this.decisionTest(this.resource.resourceExists, req, res, true, this.v3g8, this.v3h7);
};

FSM.prototype.v3g8 = function(req, res) {
  this.tracePush('v3g8');
  this.decisionTest(this.getHeaderVal(req, "if-match"), req, res, null, this.v3h10, this.v3g9);
};

FSM.prototype.v3g9 = function(req, res) {
  this.tracePush('v3g9');
  this.decisionTest(this.getHeaderVal(req, "if-match"), req, res, '*', this.v3h10, this.v3g11);
};

FSM.prototype.v3g11 = function(req, res) {
  this.tracePush('v3g11');
  var self = this;
  var requestEtags = this.getHeaderVal(req, "if-match").split(/\s*,\s*/).map(function(etag) {
    return self.unquoteHeader(etag);
  });
  this.decisionTest(function(req, res, next) {
    self.resource.generateEtag(req, res, function(reply) {
      next(_.contains(requestEtags, reply));
    });
  }, req, res, true, this.v3h10, 412);
};

FSM.prototype.v3h7 = function(req, res) {
  this.tracePush('v3h7');
  this.decisionTest(this.getHeaderVal(req, "if-match"), req, res, null, this.v3i7, 412);
};

FSM.prototype.v3h10 = function(req, res) {
  this.tracePush('v3h10');
  this.decisionTest(this.getHeaderVal(req, "if-unmodified-since"), req, res, null, this.v3i12, this.v3h11);
};

FSM.prototype.v3h11 = function(req, res) {
  this.tracePush('v3h11');
  var date = this.getHeaderVal(req, "if-unmodified-since");
  this.metadata['If-Unmodified-Since'] = date;
  this.decisionTest(this.convertRequestDate(date), req, res, null, this.v3i12, this.v3h12);
};

FSM.prototype.v3h12 = function(req, res) {
  this.tracePush('v3h12');
  var self = this;
  var reqDate = this.convertRequestDate(this.getHeaderVal(req, "if-unmodified-since"));
  this.decisionTest(function(req, res, next) {
    self.resource.lastModified(req, res, function(reply) {
      if (typeof reply === 'object') {
        next(reply > reqDate);
      } else if (typeof reply === 'boolean') {
        next(!reply);
      } else if (null) {
        next(false);
      } else {
        next(reply);
      }
    });
  }, req, res, true, 412, this.v3i12);
};

FSM.prototype.v3i4 = function(req, res) {
  this.tracePush('v3i4');
  var self = this;
  this.decisionTest(function(req, res, next) {
    self.resource.movedPermanently(req, res, function(reply) {
      switch (typeof reply) {
        case 'string':
          res.headers["Location"] = reply;
          next(301);
          break;
        default:
          next(reply);
      }
    });
  }, req, res, true, 301, this.v3p3);
};

FSM.prototype.v3i7 = function(req, res) {
  this.tracePush('v3i7');
  this.decisionTest(req.method, req, res, 'PUT', this.v3i4, this.v3k7);
};

FSM.prototype.v3i12 = function(req, res) {
  this.tracePush('v3i12');
  this.decisionTest(this.getHeaderVal(req, "if-none-match"), req, res, null, this.v3l13, this.v3i13);
};

FSM.prototype.v3i13 = function(req, res) {
  this.tracePush('v3i13');
  this.decisionTest(this.getHeaderVal(req, "if-none-match"), req, res, "*", this.v3j18, this.v3k13);
};

FSM.prototype.v3j18 = function(req, res) {
  this.tracePush('v3j18');
  this.decisionTest(req.method === 'GET' || req.method === 'HEAD', req, res, true, 304, 412);
};

FSM.prototype.v3k5 = function(req, res) {
  this.tracePush('v3k5');
  var self = this;
  this.decisionTest(function(req, res, next) {
    self.resource.movedPermanently(req, res, function(reply) {
      switch (typeof reply) {
        case 'string':
          res.headers["Location"] = reply;
          next(301);
          break;
        default:
          next(reply);
      }
    });
  }, req, res, true, 301, this.v3l5);
};

FSM.prototype.v3k7 = function(req, res) {
  this.tracePush('v3k7');
  this.decisionTest(this.resource.previouslyExisted, req, res, true, this.v3k5, this.v3l7);
};

FSM.prototype.v3k13 = function(req, res) {
  this.tracePush('v3k13');
  var self = this;
  var requestEtags = this.getHeaderVal(req, "if-none-match").split(/\s*,\s*/).map(function(etag) {
    return self.unquoteHeader(etag);
  });
  this.decisionTest(function(req, res, next) {
    self.resource.generateEtag(req, res, function(reply) {
      next(_.contains(requestEtags, reply));
    });
  }, req, res, true, this.v3j18, this.v3l13);
};

FSM.prototype.v3l5 = function(req, res) {
  this.tracePush('v3l5');
  var self = this;
  this.decisionTest(function(req, res, next) {
    self.resource.movedTemporarily(req, res, function(reply) {
      switch (typeof reply) {
        case 'string':
          res.headers["Location"] = reply;
          next(307);
          break;
        default:
          next(reply);
      }
    });
  }, req, res, true, 307, this.v3m5);
};

FSM.prototype.v3l7 = function(req, res) {
  this.tracePush('v3l7');
  this.decisionTest(req.method, req, res, 'POST', this.v3m7, 404);
};

FSM.prototype.v3l13 = function(req, res) {
  this.tracePush('v3l13');
  this.decisionTest(this.getHeaderVal(req, "if-modified-since"), req, res, null, this.v3m16, this.v3l14);
};

FSM.prototype.v3l14 = function(req, res) {
  this.tracePush('v3l14');
  var date = this.getHeaderVal(req, "if-modified-since")
  this.metadata['If-Unmodified-Since'] = date;
  this.decisionTest(this.convertRequestDate(date), req, res, null, this.v3m16, this.v3l15);
};

FSM.prototype.v3l15 = function(req, res) {
  this.tracePush('v3l15');
  var reqDate = this.convertRequestDate(this.getHeaderVal(req, "if-modified-since"));
  this.decisionTest(function(req, res, next) {
    next(reqDate > new Date());
  }, req, res, true, this.v3m16, this.v3l17);
};

FSM.prototype.v3l17 = function(req, res) {
  this.tracePush('v3l17');
  var self = this;
  var imsDate = this.convertRequestDate(this.getHeaderVal(req, "if-modified-since"));
  this.decisionTest(function(req, res, next) {
    self.resource.lastModified(req, res, function(reply) {
      if (typeof reply === 'object') {
        next(reply > imsDate);
      } else if (typeof reply === 'boolean') {
        next(!reply);
      } else {
        next(reply);
      }
    });
  }, req, res, true, this.v3m16, 304);
};

FSM.prototype.v3m5 = function(req, res) {
  this.tracePush('v3m5');
  this.decisionTest(req.method, req, res, 'POST', this.v3n5, 410);
};

FSM.prototype.v3m7 = function(req, res) {
  this.tracePush('v3m7');
  this.decisionTest(this.resource.allowMissingPost, req, res, true, this.v3n11, 404);
};

FSM.prototype.v3m16 = function(req, res) {
  this.tracePush('v3m16');
  this.decisionTest(req.method, req, res, 'DELETE', this.v3m20, this.v3n16);
};

FSM.prototype.v3m20 = function(req, res) {
  this.tracePush('v3m20');
  this.decisionTest(this.resource.deleteResource, req, res, true, this.v3m20b, 500);
};

FSM.prototype.v3m20b = function(req, res) {
  this.tracePush('v3m20b');
  this.decisionTest(this.resource.deleteCompleted, req, res, true, this.v3o20, 202);
};

FSM.prototype.v3n5 = function(req, res) {
  this.tracePush('v3n5');
  this.decisionTest(this.resource.allowMissingPost, req, res, true, this.v3n11, 410);
};

FSM.prototype.stage1Ok = function(req, res) {
  if (res.respRedirect()) {
    if (res.headers['Location']) {
      this.respond(req, res, 303);
    } else {
      this.errorResponse('Response had doRedirect but no Location');
    }
  } else {
    this.d(req, res, this.v3p11);
  }
};

FSM.prototype.v3n11 = function(req, res) {
  this.tracePush('v3n11');
  var self = this;
  this.resource.postIsCreate(req, res, function(postIsCreate) {
    if (postIsCreate) {
      self.resource.createPath(req, res, function(uri) {
        if (uri) {
          self.resource.baseUri(req, res, function(baseUri) {
            var dispPath;
            baseUri || (baseUri = req.baseUri());
            dispPath = baseUri + '/' + uri;
            res.setRespHeader('Location', dispPath);
            self.acceptHelper(req, res, function(result) {
              if (typeof result === 'number') {
                self.respond(req, res, result);
              } else {
                self.stage1Ok(req, res);
              }
            });
          });
        } else {
          self.errorResponse('postIsCreate w/o createPath');
        }
      });
    } else {
      self.resource.processPost(req, res, function(processedPost) {
        if (typeof processedPost === 'number') {
          self.respond(req, res, processedPost);
        } else if (processedPost) {
          self.stage1Ok(req, res);
        } else {
          self.errorResponse(processedPost);
        }
      });
    }
  });
};

FSM.prototype.v3n16 = function(req, res) {
  this.tracePush('v3n16');
  this.decisionTest(req.method, req, res, 'POST', this.v3n11, this.v3o16);
};

FSM.prototype.v3o14 = function(req, res) {
  this.tracePush('v3o14');
  var self = this;
  this.resource.isConflict(req, res, function(isConflict) {
    if (isConflict) {
      self.respond(req, res, 409);
    } else {
      self.acceptHelper(req, res, function(result) {
        if (typeof res === 'number') {
          self.respond(req, res, result);
        } else {
          self.d(req, res, self.v3p11);
        }
      });
    }
  });
};

FSM.prototype.v3o16 = function(req, res) {
  this.tracePush('v3o16');
  this.decisionTest(req.method, req, res, 'PUT', this.v3o14, this.v3o18);
};

FSM.prototype.v3o18 = function(req, res) {
  this.tracePush('v3o18');
  var self = this;
  if (req.method === 'GET' || req.method === 'HEAD') {
    this.resource.generateEtag(req, res, function(etag) {
      if (etag) res.headers["ETag"] = "\"" + etag + "\"";
      self.resource.lastModified(req, res, function(lastModified) {
        if (lastModified) {
          res.headers["Last-Modified"] = new Date(lastModified);
        }
        self.resource.expires(req, res, function(expires) {
          var contentType, contentTypes, matchingCt;
          if (expires) res.headers["Expires"] = new Date(expires);
          contentTypes = self.resource.contentTypesProvidedSync(req, res);
          contentType = self.metadata['Content-Type'];
          matchingCt = contentTypes[contentType];
          matchingRes = self.resource[matchingCt]
          if(!matchingRes) {
            throw("Expected function "+matchingCt+" for given content-type: "+contentType);
          }
          matchingRes.apply(self.resource, [
            req, res, function(result) {
              if (typeof result === 'number') {
                self.respond(req, res, result);
              // TODO: seems useful to do } else if (typeof result === 'boolean') {
              } else {
                res.body = result;
                self.encodeBody(req, res);
                self.d(req, res, self.v3o18b);
              }
            }
          ]);
        });
      });
    });
  } else {
    this.d(req, res, this.v3o18b);
  }
};

FSM.prototype.v3o18b = function(req, res) {
  this.tracePush('v3o18b');
  this.decisionTest(this.resource.multipleChoices, req, res, true, 300, 200);
};

FSM.prototype.v3o20 = function(req, res) {
  this.tracePush('v3o20');
  this.decisionTest(res.hasResponseBody(), req, res, true, this.v3o18, 204);
};

FSM.prototype.v3p3 = function(req, res) {
  this.tracePush('v3p3');
  var self = this;
  this.resource.isConflict(req, res, function(isConflict) {
    if (isConflict) {
      self.respond(req, res, 409);
    } else {
      self.acceptHelper(req, res, function(result) {
        if (typeof res === 'number') {
          self.respond(req, res, result);
        } else {
          self.d(req, res, self.v3p11);
        }
      });
    }
  });
};

FSM.prototype.v3p11 = function(req, res) {
  this.tracePush('v3p11');
  this.decisionTest(res.getRespHeader('Location'), req, res, null, this.v3o20, 201);
};

module.exports = FSM;
