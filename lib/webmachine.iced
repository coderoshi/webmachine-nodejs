_    = require('underscore')
http = require('http')
url  = require('url')
util = require('./util')
Fsm  = require('./fsm')
ResData = require('./responseData')
ReqData = require('./requestData')

class Webmachine
  constructor: ()->
    @resources = []

  # add resource to the route tree
  add: (resource)->
    resource.routeRe = util.pathRegexp(
      resource.route
      (resource.routeReKeys = [])
      false  # options.sensitive
      false  # options.strict
    )
    @resources.push resource

  start: (port, ipaddr)->
    @server = http.createServer (req, res)=>
      urlForm = url.parse(req.url, true)
      # console.log urlForm
      # console.log @match(urlForm)
      if match = @match(urlForm)

        [resource, pathInfo] = match
        rd = new ReqData(req, urlForm, pathInfo)
        rs = new ResData(res)

        # TODO: wrap resource inside a Resource
        resource.authorization = {}
        resource.knownMethodsSync ||= (req, res) -> ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE', 'CONNECT', 'OPTIONS']
        resource.allowedMethodsSync ||= (req, res) -> ['GET', 'HEAD']
        resource.charsetsProvidedSync ||= (req, res) -> {"iso-8859-1" : (x) -> x}
        resource.encodingsProvidedSync ||= (req, res) -> {"identity" : (x) -> x}
        resource.contentTypesProvidedSync ||= (req, res) -> {"text/html" : 'toHtml'}
        resource.contentTypesAcceptedSync ||= (req, res) -> []

        # TODO: change these to syncs?
        resource.options ||= (req, res) -> []
        resource.forbidden ||= (req, res, next) -> next(false)

        resource.allowMissingPost ||= (req, res, next) -> next(false)
        resource.malformedRequest ||= (req, res, next) -> next(false)
        resource.uriTooLong ||= (req, res, next) -> next(false)
        resource.deleteResource ||= (req, res, next) -> next(false)
        resource.postIsCreate ||= (req, res, next) -> next(false)
        resource.processPost ||= (req, res, next) -> next(false)
        resource.isConflict ||= (req, res, next) -> next(false)
        resource.multipleChoices ||= (req, res, next) -> next(false)
        resource.previouslyExisted ||= (req, res, next) -> next(false)
        resource.movedPermanently ||= (req, res, next) -> next(false)
        resource.movedTemporarily ||= (req, res, next) -> next(false)

        fsm = new Fsm(resource)
        fsm.run(rd, rs)
      else
        res.writeHead(404, {'Content-Type': 'text/plain'})
        res.write('File Not Found')
        res.end()
    @server.listen(port, ipaddr)

  # TODO: extract into a Dispatcher
  match: (urlForm)->
    pathInfo = {}
    r = null
    for resource in @resources
      keys = resource.routeReKeys
      # console.log keys
      m = resource.routeRe.exec(urlForm.pathname)

      continue unless m

      for i in [1...m.length]
        key = keys[i - 1]
        val = if 'string' == typeof(m[i]) then decodeURIComponent(m[i]) else m[i]
        pathInfo[key.name] = val
      r = resource
      break

    if r
      [r, pathInfo]
    else
      null


module.exports = new Webmachine()



# decision = (req, context) ->
#   {}
# # Default Halt  Allowed Description
# # true  X true, false Returning non-true values will result in 404 Not Found.
# resourceExists = (req, context) ->
#   {}
# # true  X true, false
# serviceAvailable = (req, context) ->
#   ""
# # true  X true, AuthHead  If this returns anything other than true, the response will be 401 Unauthorized. The AuthHead return value will be used as the value in the WWW-Authenticate header
# isAuthorized = (req, context) ->
#   {}
# # X true, false
# forbidden = (req, context) ->
#   {}
# # X true, false If the resource accepts POST requests to nonexistent resources, then this should return true.
# allowMissingPost = (req, context) ->
#   {}
# # X true, false
# malformedRequest = (req, context) ->
#   {}
# # X true, false
# uriTooLong = (req, context) ->
#   {}
# # X true, false
# knownContentType = (req, context) ->
#   {}
# # X true, false
# validContentHeaders = (req, context) ->
#   {}
# # X true, false
# validEntityLength = (req, context) ->
#   {}
# # [Header]  If the OPTIONS method is supported and is used, the return value of this function is expected to be a list of pairs representing header names and values that should appear in the response.
# options = (req, context) ->
#   {}
# # [Method]  If a Method not in this list is requested, then a 405 Method Not Allowed will be sent. Note that these are all-caps and are atoms. (single-quoted)
# no callback here :(
# allowedMethodsSync
# allowedMethods = (req, context) ->
#   {}
# # X true, false This is called when a DELETE request should be enacted, and should return true if the deletion succeeded.
# deleteResource = (req, context) ->
#   {}
# # X true, false This is only called after a successful deleteResource call, and should return false if the deletion was accepted but cannot yet be guaranteed to have finished.
# deleteCompleted = (req, context) ->
#   {}
# # true, false If POST requests should be treated as a request to put content into a (potentially new) resource as opposed to being a generic submission for processing, then this function should return true. If it does return true, then createPath will be called and the rest of the request will be treated much like a PUT to the Path entry returned by that call.
# postIsCreate = (req, context) ->
#   {}
# # Path  This will be called on a POST request if postIsCreate returns true. It is an error for this function to not produce a Path if postIsCreate returns true. The Path returned should be a valid URI part following the dispatcher prefix. That Path will replace the previous one in the return value of wrq:dispPath = (req) for all subsequent resource function calls in the course of this request.
# createPath = (req, context) ->
#   {}
# # X true, false If postIsCreate returns false, then this will be called to process any POST requests. If it succeeds, it should return true.
# processPost = (req, context) ->
#   {}
# # [{"text/html", toHtml}]    [{Mediatype, Handler}]  This should return a list of pairs where each pair is of the form {Mediatype, Handler} where Mediatype is a string of content-type format and the Handler is an atom naming the function which can provide a resource representation in that media type. Content negotiation is driven by this return value. For example, if a client request includes an Accept header with a value that does not appear as a first element in any of the return tuples, then a 406 Not Acceptable will be sent.
# contentTypesProvided = (req, context) ->
#   {}
# # []    [{Mediatype, Handler}]  This is used similarly to contentTypesProvided, except that it is for incoming resource representations – for example, PUT requests. Handler functions usually want to use wrq:reqBody = (req) to access the incoming request body.
# contentTypesAccepted = (req, context) ->
#   {}
# # noCharset    noCharset, [{Charset, CharsetConverter}] If this is anything other than the atom noCharset, it must be a list of pairs where each pair is of the form {Charset, Converter} where Charset is a string naming a charset and Converter is a callable function in the resource which will be called on the produced body in a GET and ensure that it is in Charset.
# charsetsProvidedSync
# charsetsProvided = (req, context) ->
#   {}
# # [{"identity", fun(X) -> X end}]   [{Encoding, Encoder}] This must be a list of pairs where in each pair Encoding is a string naming a valid content encoding and Encoder is a callable function in the resource which will be called on the produced body in a GET and ensure that it is so encoded. One useful setting is to have the function check on method, and on GET requests return [{"identity", fun(X) -> X end}, {"gzip", fun(X) -> zlib:gzip(X) end}] as this is all that is needed to support gzip content encoding.
# encodingsProvidedSync
# encodingsProvided = (req, context) ->
#   {}
# # []    [HeaderName]  If this function is implemented, it should return a list of strings with header names that should be included in a given response’s Vary header. The standard conneg headers (Accept, Accept-Encoding, Accept-Charset, Accept-Language) do not need to be specified here as Webmachine will add the correct elements of those automatically depending on resource behavior.
# variancesSync
# variances = (req, context) ->
#   {}
# # false   true, false If this returns true, the client will receive a 409 Conflict.
# isConflict = (req, context) ->
#   {}
# # false X true, false If this returns true, then it is assumed that multiple representations of the response are possible and a single one cannot be automatically chosen, so a 300 Multiple Choices will be sent instead of a 200.
# multipleChoices = (req, context) ->
#   {}
# # false X true, false 
# previouslyExisted = (req, context) ->
#   {}
# # false X {true, MovedURI}, false 
# movedPermanently = (req, context) ->
#   {}
# # false X {true, MovedURI}, false 
# movedTemporarily = (req, context) ->
#   {}
# # undefined   undefined, {{YYYY,MM,DD}, {Hour,Min,Sec}} 
# lastModified = (req, context) ->
#   {}
# # undefined   undefined, {{YYYY,MM,DD}, {Hour,Min,Sec}} 
# expires = (req, context) ->
#   {}
# # undefined   undefined, ETag If this returns a value, it will be used as the value of the ETag header and for comparison in conditional requests.
# generateEtag = (req, context) ->
#   {}
# # true    true, false This function, if exported, is called just before the final response is constructed and sent. The Result is ignored, so any effect of this function must be by returning a modified req.
# finishRequest = (req, context) ->
#   {}
# # body-producing function named as a Handler by contentTypesProvided    X Body  The Body should be either an iolist() or {stream,streambody()}
# # POST-processing function named as a Handler by contentTypesAccepted   X true
