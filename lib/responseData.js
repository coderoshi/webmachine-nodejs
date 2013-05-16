
function ResData(nodeRes) {
  this.res = nodeRes;
  this.redirect = false;
  this.headers = {};
  this.body = null;
  this.dispPath = null;
  this.reqBody = false;
}

ResData.prototype.getRespHeader = function(string) {
  return this.headers[string] || null;
};

ResData.prototype.statusCode = function() {
  return this.res.statusCode;
};

ResData.prototype.respRedirect = function() {
  return this.redirect;
};

ResData.prototype.respHeaders = function() {
  return this.headers;
};

ResData.prototype.respBody = function() {
  return this.body;
};

ResData.prototype.hasResponseBody = function() {
  return this.body !== null;
};

ResData.prototype.setRespHeader = function(string, value) {
  this.headers[string] = value;
};

ResData.prototype.appendToResponseBody = function(body) {
  if (this.body === null) this.body = "";
  return this.body += body;
};

ResData.prototype.doRedirect = function(bool) {
  this.redirect = bool;
};

ResData.prototype.setDispPath = function(string) {
  this.dispPath = string;
};

ResData.prototype.setReqBody = function(binary) {
  this.reqBody = binary;
};

ResData.prototype.setRespBody = function(body) {
  this.body = body;
};

ResData.prototype.setRespHeaders = function(headername, value) {
  this.headers[headername] = value;
};

ResData.prototype.removeRespHeader = function(string) {
  delete this.headers[headername];
};

module.exports = ResData;
