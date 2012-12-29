_ = require('underscore')

class Resource
  constructor: (config)->
    @route = config.route
    @config = config
    @knownMethods = ['GET']
    @authorization = {}
    _.extend(@, config)
  
  # TODO: make async versions available?
  knownMethodsSync: (req, res) -> ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE', 'CONNECT', 'OPTIONS']
  allowedMethodsSync: (req, res) -> ['GET', 'HEAD']
  charsetsProvidedSync: (req, res) -> {"utf-8" : (x) -> x}
  encodingsProvidedSync: (req, res) -> {"identity" : (x) -> x}
  contentTypesProvidedSync: (req, res) -> {"text/html" : 'toHtml'}
  contentTypesAcceptedSync: (req, res) -> {}
  variancesSync: (req, res) -> []
  optionsSync: (req, res) -> []
  
  ping: (req, res, next) -> next('pong')
  serviceAvailable: (req, res, next) -> next(true)
  resourceExists: (req, res, next) -> next(true)
  authRequired: (req, res, next) -> next(true)
  isAuthorized: (req, res, next) -> next(true)
  forbidden: (req, res, next) -> next(false)
  allowMissingPost: (req, res, next) -> next(false)
  malformedRequest: (req, res, next) -> next(false)
  uriTooLong: (req, res, next) -> next(false)
  knownContentType: (req, res, next) -> next(true)
  validContentHeaders: (req, res, next) -> next(true)
  validEntityLength: (req, res, next) -> next(true)
  deleteCompleted: (req, res, next) -> next(true)
  deleteResource: (req, res, next) -> next(false)
  postIsCreate: (req, res, next) -> next(false)
  processPost: (req, res, next) -> next(false)
  createPath: (req, res, next) -> next(null)
  baseUri: (req, res, next) -> next(null)
  languageAvailable: (req, res, next) -> next(true)
  isConflict: (req, res, next) -> next(false)
  multipleChoices: (req, res, next) -> next(false)
  previouslyExisted: (req, res, next) -> next(false)
  movedPermanently: (req, res, next) -> next(false)
  movedTemporarily: (req, res, next) -> next(false)
  finishRequest: (req, res, next) -> next(true)
  lastModified: (req, res, next) -> next(null)
  expires: (req, res, next) -> next(null)
  generateEtag: (req, res, next) -> next(null)

          
module.exports = Resource
