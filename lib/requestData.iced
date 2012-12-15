
class ReqData
  constructor: (nodeReq, urlForm, pathInfo)->
    @req = nodeReq
    @url = urlForm
    @pathInfo = pathInfo
    @method = nodeReq.method
    @dispPath = null

  ## request functions

  # -> {integer(),integer()}  The HTTP version used by the client. Most often 1.1 .
  version: ()-> 
    '1.1'

  # -> string()  The IP address of the client.
  peer: ()->
    '0.0.0.0'

  # -> string() The “local” path of the resource URI; the part after any prefix
  # used in dispatch configuration. Of the three path accessors, this is the
  # one you usually want. This is also the one that will change after createPath
  # is called in your resource.
  dispPath: ()-> @url.pathname

  # -> string()  The path part of the URI – after the host and port, but not
  # including any query string.
  path: ()-> @url.pathname

  # -> string()  The entire path part of the URI, including any query string present.
  rawPath: ()-> @url.path

  # -> 'undefined', string() Looks up a binding as described in dispatch configuration.
  # -> any()  The dictionary of bindings as described in dispatch configuration.
  pathInfo: (field)-> if field then @pathInfo[field] else @pathInfo
  
  # -> list() This is a list of string() terms, the dispPath components split by “/”.
  pathTokens: ()-> @dispPath().split('/')

  # -> 'undefined', string()  Look up the value of an incoming request header.
  getReqHeader: (field)-> @reqHeaders()[field]

  # -> mochiheaders() The incoming HTTP headers. Generally, getReqHeader is more useful.
  # TODO: downcase?
  reqHeaders: ()-> @req.headers

  # TODO: it'd be nice to make this blocking. but, whatever
  # -> 'undefined', binary() The incoming request body, if any.
  # reqBody: ()->
  #   # parse the body
  #   body = ""
  #   console.log "waiting"
  #   @req.on "data", (chunk)->
  #     body += chunk.toString()
  #     console.log "chunk #{body}"
  #   await
  #     @req.on "end", defer()
  #   console.log "done"
  #   body

  # -> streambody() The incoming request body in streamed form, passing in a
  # callback function.
  # streamReqBody
  reqBody: (cb)->
    body = ""
    @req.on "data", (chunk)->
      body += chunk.toString()
    @req.on "end", ()->
      cb(body)

  # -> string() Look up the named value in the incoming request cookie header.
  getCookieValue: (string)->

  # -> string()  The raw value of the cookie header. Note that getCookieValue is
  # often more useful.
  reqCookie: ()->
    # TODO: parse this
    @getReqHeader('cookie')

  # -> 'undefined', string()  Given the name of a key, look up the corresponding
  # value in the query string.
  # -> string()  Given the name of a key and a default value if not present, look
  # up the corresponding value in the query string.
  getQsValue: (string, defaultValue)->
    if defaultValue
      @url.query[string] || defaultValue
    else
      @url.query[string]

  # -> [{string(), string()}]  The parsed query string, if any. Note that
  # getQsValue is often more useful.
  reqQs: ()-> @url.query

  # -> string()  Indicates the “height” above the requested URI that this resource
  # is dispatched from. Typical values are “.” , “..” , “../..” and so on.
  appRoot: ()->
    "."

module.exports = ReqData
