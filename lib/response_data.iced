
class ResData
  constructor: (nodeRes)->
    @res = nodeRes
    @headers = {}

  is_redirect: ()-> 

  append_to_response_body: (body)->

  # -> string()  Look up the current value of an outgoing request header.
  get_resp_header: (string)->
    @res.getHeader(string)

  # -> bool() the last value passed to do_redirect, false otherwise – if true,
  # then some responses will be 303 instead of 2xx where applicable
  resp_redirect: ()->

  # -> mochiheaders()  The outgoing HTTP headers. Generally, get_resp_header is
  # more useful.
  resp_headers: ()->

  # -> 'undefined', binary()  The outgoing response body, if one has been set.
  # Usually, append_to_response_body is the best way to set this.
  resp_body: ()->

  has_response_body: ()-> 

  ## Request Modification Functions

  # rd() Given a header name and value, set an outgoing request header to that value.
  set_resp_header: (string, value) ->

  # rd()  Append the given value to the body of the outgoing response.
  append_to_response_body: (binary) -> 

  # rd()  see resp_redirect; this sets that value.
  do_redirect: (bool) ->

  # rd()  The disp_path is the only path that can be changed during a request. This function will do so.
  set_disp_path: (string) ->

  # rd() Replace the incoming request body with this for the rest of the processing.
  set_req_body: (binary) ->

  # rd()  Set the outgoing response body to this value.
  set_resp_body: (binary) ->

  # rd()  Use this streamed body to produce the outgoing response body on demand.
  set_resp_body: (streambody) ->

  # rd()  Given a list of two-tuples of {headername,value}, set those outgoing response headers.
  set_resp_headers: (headername, value) -> 

  # rd() Remove the named outgoing response header.
  remove_resp_header: (string) ->

module.exports = ResData
