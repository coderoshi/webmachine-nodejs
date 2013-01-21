function ReqData(nodeReq, urlForm, pathInfo) {
  this.req = nodeReq;
  this.url = urlForm;
  this.pathInfo = pathInfo;
  this.method = nodeReq.method;
  this.dispPath = null;
}

ReqData.prototype.baseUri = function() {
  return "" + this.url.protocol + "//" + this.url.host;
};

ReqData.prototype.version = function() {
  return '1.1';
};

ReqData.prototype.peer = function() {
  return '0.0.0.0';
};

ReqData.prototype.dispPath = function() {
  return this.url.pathname;
};

ReqData.prototype.path = function() {
  return this.url.pathname;
};

ReqData.prototype.rawPath = function() {
  return this.url.path;
};

ReqData.prototype.pathInfo = function(field) {
  if (field) {
    return this.pathInfo[field];
  } else {
    return this.pathInfo;
  }
};

ReqData.prototype.pathTokens = function() {
  return this.dispPath().split('/');
};

ReqData.prototype.getReqHeader = function(field) {
  return this.reqHeaders()[field];
};

ReqData.prototype.reqHeaders = function() {
  return this.req.headers;
};

ReqData.prototype.reqBody = function(cb) {
  var body = "";
  this.req.on("data", function(chunk) {
    body += chunk.toString();
  });
  this.req.on("end", function() {
    cb(body);
  });
};

ReqData.prototype.getCookieValue = function(string) {};

ReqData.prototype.reqCookie = function() {
  return this.getReqHeader('cookie');
};

ReqData.prototype.getQsValue = function(string, defaultValue) {
  if (defaultValue) {
    return this.url.query[string] || defaultValue;
  } else {
    return this.url.query[string];
  }
};

ReqData.prototype.reqQs = function() {
  return this.url.query;
};

ReqData.prototype.appRoot = function() {
  return ".";
};

module.exports = ReqData;
