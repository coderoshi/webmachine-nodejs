
class ResData
  constructor: (nodeRes)->
    @res = nodeRes
    @headers = {}

  isRedirect: ()-> 

  appendToResponseBody: (body)->

  # -> string()  Look up the current value of an outgoing request header.
  getRespHeader: (string)->
    @res.getHeader(string)

  statusCode: ()->
    @res.statusCode

  # -> bool() the last value passed to doRedirect, false otherwise – if true,
  # then some responses will be 303 instead of 2xx where applicable
  respRedirect: ()->

  # -> mochiheaders()  The outgoing HTTP headers. Generally, getRespHeader is
  # more useful.
  respHeaders: ()->

  # -> 'undefined', binary()  The outgoing response body, if one has been set.
  # Usually, appendToResponseBody is the best way to set this.
  respBody: ()->

  hasResponseBody: ()-> 

  ## Request Modification Functions

  # rd() Given a header name and value, set an outgoing request header to that value.
  setRespHeader: (string, value) ->

  # rd()  Append the given value to the body of the outgoing response.
  appendToResponseBody: (binary) -> 

  # rd()  see respRedirect; this sets that value.
  doRedirect: (bool) ->

  # rd()  The dispPath is the only path that can be changed during a request. This function will do so.
  setDispPath: (string) ->

  # rd() Replace the incoming request body with this for the rest of the processing.
  setReqBody: (binary) ->

  # rd()  Set the outgoing response body to this value.
  setRespBody: (binary) ->

  # rd()  Use this streamed body to produce the outgoing response body on demand.
  setRespBody: (streambody) ->

  # rd()  Given a list of two-tuples of {headername,value}, set those outgoing response headers.
  setRespHeaders: (headername, value) -> 

  # rd() Remove the named outgoing response header.
  removeRespHeader: (string) ->

module.exports = ResData
