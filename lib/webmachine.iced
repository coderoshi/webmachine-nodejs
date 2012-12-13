_    = require('underscore')
http = require('http')
url  = require('url')
util = require('./util')
Fsm  = require('./fsm')
ResData = require('./response_data')
ReqData = require('./request_data')

class Webmachine
  constructor: ()->
    @resources = []

  # add resource to the route tree
  add: (resource)->
    resource.route_re = util.pathRegexp(
      resource.route
      (resource.route_re_keys = [])
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
        resource.known_methods = ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE', 'CONNECT', 'OPTIONS']
        resource.allowed_methods_sync ||= (req, res) -> ['GET', 'HEAD']
        resource.charsets_provided_sync ||= (req, res) -> {"iso-8859-1" : (x) -> x}
        resource.encodings_provided_sync ||= (req, res) -> {"identity" : (x) -> x}

        # TODO: change these to syncs?
        resource.content_types_provided ||= (req, res) -> {"text/html" : 'to_html'}
        resource.content_types_accepted ||= (req, res) -> []
        resource.options ||= (req, res) -> []
        resource.forbidden ||= (req, res, next) -> next(false)

        resource.allow_missing_post ||= (req, res, next) -> next(false)
        resource.malformed_request ||= (req, res, next) -> next(false)
        resource.uri_too_long ||= (req, res, next) -> next(false)
        resource.delete_resource ||= (req, res, next) -> next(false)
        resource.post_is_create ||= (req, res, next) -> next(false)
        resource.process_post ||= (req, res, next) -> next(false)
        resource.is_conflict ||= (req, res, next) -> next(false)
        resource.multiple_choices ||= (req, res, next) -> next(false)
        resource.previously_existed ||= (req, res, next) -> next(false)
        resource.moved_permanently ||= (req, res, next) -> next(false)
        resource.moved_temporarily ||= (req, res, next) -> next(false)

        fsm = new Fsm(resource, rd, rs)
        fsm.run()
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
      keys = resource.route_re_keys
      # console.log keys
      m = resource.route_re.exec(urlForm.pathname)

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
# resource_exists = (req, context) ->
#   {}
# # true  X true, false
# service_available = (req, context) ->
#   ""
# # true  X true, AuthHead  If this returns anything other than true, the response will be 401 Unauthorized. The AuthHead return value will be used as the value in the WWW-Authenticate header
# is_authorized = (req, context) ->
#   {}
# # X true, false
# forbidden = (req, context) ->
#   {}
# # X true, false If the resource accepts POST requests to nonexistent resources, then this should return true.
# allow_missing_post = (req, context) ->
#   {}
# # X true, false
# malformed_request = (req, context) ->
#   {}
# # X true, false
# uri_too_long = (req, context) ->
#   {}
# # X true, false
# known_content_type = (req, context) ->
#   {}
# # X true, false
# valid_content_headers = (req, context) ->
#   {}
# # X true, false
# valid_entity_length = (req, context) ->
#   {}
# # [Header]  If the OPTIONS method is supported and is used, the return value of this function is expected to be a list of pairs representing header names and values that should appear in the response.
# options = (req, context) ->
#   {}
# # [Method]  If a Method not in this list is requested, then a 405 Method Not Allowed will be sent. Note that these are all-caps and are atoms. (single-quoted)
# no callback here :(
# allowed_methods_sync
# allowed_methods = (req, context) ->
#   {}
# # X true, false This is called when a DELETE request should be enacted, and should return true if the deletion succeeded.
# delete_resource = (req, context) ->
#   {}
# # X true, false This is only called after a successful delete_resource call, and should return false if the deletion was accepted but cannot yet be guaranteed to have finished.
# delete_completed = (req, context) ->
#   {}
# # true, false If POST requests should be treated as a request to put content into a (potentially new) resource as opposed to being a generic submission for processing, then this function should return true. If it does return true, then create_path will be called and the rest of the request will be treated much like a PUT to the Path entry returned by that call.
# post_is_create = (req, context) ->
#   {}
# # Path  This will be called on a POST request if post_is_create returns true. It is an error for this function to not produce a Path if post_is_create returns true. The Path returned should be a valid URI part following the dispatcher prefix. That Path will replace the previous one in the return value of wrq:disp_path = (req) for all subsequent resource function calls in the course of this request.
# create_path = (req, context) ->
#   {}
# # X true, false If post_is_create returns false, then this will be called to process any POST requests. If it succeeds, it should return true.
# process_post = (req, context) ->
#   {}
# # [{"text/html", to_html}]    [{Mediatype, Handler}]  This should return a list of pairs where each pair is of the form {Mediatype, Handler} where Mediatype is a string of content-type format and the Handler is an atom naming the function which can provide a resource representation in that media type. Content negotiation is driven by this return value. For example, if a client request includes an Accept header with a value that does not appear as a first element in any of the return tuples, then a 406 Not Acceptable will be sent.
# content_types_provided = (req, context) ->
#   {}
# # []    [{Mediatype, Handler}]  This is used similarly to content_types_provided, except that it is for incoming resource representations – for example, PUT requests. Handler functions usually want to use wrq:req_body = (req) to access the incoming request body.
# content_types_accepted = (req, context) ->
#   {}
# # no_charset    no_charset, [{Charset, CharsetConverter}] If this is anything other than the atom no_charset, it must be a list of pairs where each pair is of the form {Charset, Converter} where Charset is a string naming a charset and Converter is a callable function in the resource which will be called on the produced body in a GET and ensure that it is in Charset.
# charsets_provided_sync
# charsets_provided = (req, context) ->
#   {}
# # [{"identity", fun(X) -> X end}]   [{Encoding, Encoder}] This must be a list of pairs where in each pair Encoding is a string naming a valid content encoding and Encoder is a callable function in the resource which will be called on the produced body in a GET and ensure that it is so encoded. One useful setting is to have the function check on method, and on GET requests return [{"identity", fun(X) -> X end}, {"gzip", fun(X) -> zlib:gzip(X) end}] as this is all that is needed to support gzip content encoding.
# encodings_provided_sync
# encodings_provided = (req, context) ->
#   {}
# # []    [HeaderName]  If this function is implemented, it should return a list of strings with header names that should be included in a given response’s Vary header. The standard conneg headers (Accept, Accept-Encoding, Accept-Charset, Accept-Language) do not need to be specified here as Webmachine will add the correct elements of those automatically depending on resource behavior.
# variances_sync
# variances = (req, context) ->
#   {}
# # false   true, false If this returns true, the client will receive a 409 Conflict.
# is_conflict = (req, context) ->
#   {}
# # false X true, false If this returns true, then it is assumed that multiple representations of the response are possible and a single one cannot be automatically chosen, so a 300 Multiple Choices will be sent instead of a 200.
# multiple_choices = (req, context) ->
#   {}
# # false X true, false 
# previously_existed = (req, context) ->
#   {}
# # false X {true, MovedURI}, false 
# moved_permanently = (req, context) ->
#   {}
# # false X {true, MovedURI}, false 
# moved_temporarily = (req, context) ->
#   {}
# # undefined   undefined, {{YYYY,MM,DD}, {Hour,Min,Sec}} 
# last_modified = (req, context) ->
#   {}
# # undefined   undefined, {{YYYY,MM,DD}, {Hour,Min,Sec}} 
# expires = (req, context) ->
#   {}
# # undefined   undefined, ETag If this returns a value, it will be used as the value of the ETag header and for comparison in conditional requests.
# generate_etag = (req, context) ->
#   {}
# # true    true, false This function, if exported, is called just before the final response is constructed and sent. The Result is ignored, so any effect of this function must be by returning a modified req.
# finish_request = (req, context) ->
#   {}
# # body-producing function named as a Handler by content_types_provided    X Body  The Body should be either an iolist() or {stream,streambody()}
# # POST-processing function named as a Handler by content_types_accepted   X true  
