_ = require('underscore');

function Resource(config) {
  this.route = config.route;
  this.config = config;
  this.knownMethods = ['GET'];
  this.authorization = {};
  _.extend(this, config);
}

Resource.prototype.knownMethodsSync = function(req, res) {
  return ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE', 'CONNECT', 'OPTIONS'];
};

Resource.prototype.allowedMethodsSync = function(req, res) {
  return ['GET', 'HEAD'];
};

Resource.prototype.charsetsProvidedSync = function(req, res) {
  return {
    "utf-8": function(x) {
      return x;
    }
  };
};

Resource.prototype.encodingsProvidedSync = function(req, res) {
  return {
    "identity": function(x) {
      return x;
    }
  };
};

Resource.prototype.contentTypesProvidedSync = function(req, res) {
  return {
    "text/html": 'toHtml'
  };
};

Resource.prototype.contentTypesAcceptedSync = function(req, res) {
  return {};
};

Resource.prototype.variancesSync = function(req, res) {
  return [];
};

Resource.prototype.optionsSync = function(req, res) {
  return [];
};

Resource.prototype.ping = function(req, res, next) {
  return next('pong');
};

Resource.prototype.serviceAvailable = function(req, res, next) {
  return next(true);
};

Resource.prototype.resourceExists = function(req, res, next) {
  return next(true);
};

Resource.prototype.authRequired = function(req, res, next) {
  return next(true);
};

Resource.prototype.isAuthorized = function(req, res, next) {
  return next(true);
};

Resource.prototype.forbidden = function(req, res, next) {
  return next(false);
};

Resource.prototype.allowMissingPost = function(req, res, next) {
  return next(false);
};

Resource.prototype.malformedRequest = function(req, res, next) {
  return next(false);
};

Resource.prototype.uriTooLong = function(req, res, next) {
  return next(false);
};

Resource.prototype.knownContentType = function(req, res, next) {
  return next(true);
};

Resource.prototype.validContentHeaders = function(req, res, next) {
  return next(true);
};

Resource.prototype.validEntityLength = function(req, res, next) {
  return next(true);
};

Resource.prototype.deleteCompleted = function(req, res, next) {
  return next(true);
};

Resource.prototype.deleteResource = function(req, res, next) {
  return next(false);
};

Resource.prototype.postIsCreate = function(req, res, next) {
  return next(false);
};

Resource.prototype.processPost = function(req, res, next) {
  return next(false);
};

Resource.prototype.createPath = function(req, res, next) {
  return next(null);
};

Resource.prototype.baseUri = function(req, res, next) {
  return next(null);
};

Resource.prototype.languageAvailable = function(req, res, next) {
  return next(true);
};

Resource.prototype.isConflict = function(req, res, next) {
  return next(false);
};

Resource.prototype.multipleChoices = function(req, res, next) {
  return next(false);
};

Resource.prototype.previouslyExisted = function(req, res, next) {
  return next(false);
};

Resource.prototype.movedPermanently = function(req, res, next) {
  return next(false);
};

Resource.prototype.movedTemporarily = function(req, res, next) {
  return next(false);
};

Resource.prototype.finishRequest = function(req, res) {
  return true;
};

Resource.prototype.lastModified = function(req, res, next) {
  return next(null);
};

Resource.prototype.expires = function(req, res, next) {
  return next(null);
};

Resource.prototype.generateEtag = function(req, res, next) {
  return next(null);
};

module.exports = Resource;
