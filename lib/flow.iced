_    = require('underscore')

class Flow
  constructor: (resource)->
    @resource = resource
    # TODO: Ruby had a good idea, but actually use this if you can do it async
    @metadata = {}

  # Handles standard decisions where halting is allowed
  decision_test: (test, req, res, value, iftrue, iffalse) ->
    if test?
      switch typeof(test)
        when 'function'
          test(req, res, (test_reply)=>
            headers = {}
            if value == test_reply
              @d(req, res, iftrue, headers)
            else if typeof(test_reply) == 'number'
              @respond(req, res, test_reply, {})
            else
              @d(req, res, iffalse, headers)
          )
        else
          if test == value
            @d(req, res, iftrue, headers)
          else
            @d(req, res, iffalse, headers)
    else
      headers = {}
      if value
        @d(req, res, iftrue, headers)
      else
        @d(req, res, iffalse, headers)

  d: (req, res, reply, headers={}) ->
    console.log reply
    if typeof(reply) == 'number'
      @respond(req, res, reply, {})
    else
      @[reply].apply(@, [req, res])

  error_response: (req, res, message)->
    throw message

  respond: (req, res, code, headers={}) ->
    headers ||= {}
    res.headers = _.extend(res.headers, headers)
    switch code
      when 404
        res.res.writeHead(404, {'Content-Type': 'text/plain'})
        res.res.write('File Not Found')
      when 304
        res.headers.delete('Content-Type')
        # TODO: add caching headers
    res.res.statusCode = code
    # res.res.writeHead(code, {})
    # TODO: ensure content length
    @resource.finish_request(req, res) if @resource.finish_request?
    res.res.end()

  get_header_val: (req, field)->
    @unquote_header(req.get_req_header(field))

  # TODO: impl
  choose_media_type: (types, mt)->
    null

  # TODO: also allow async charsets_provided?
  choose_charset: (req, res, charset)->
    provided = @resource.charsets_provided_sync(req, res)
    if provided?.length?
      charsets = _.keys(provided)
      if chosen_charset = do_choose_charset(charsets, charset)
        @metadata['Chosen-Charset'] = chosen_charset
    else
      null

  # TODO: implement choosing the proper charset
  do_choose_charset: (charsets, charset) ->
    _.first(charsets)

  # TODO: implement choose encoding
  choose_encoding: (req, res, encoding)->
    null

  variances: (req, res)->
    accept = if @resource.content_types_provided(req, res).length > 1 then ["Accept"] else []
    accept_encoding = if @resource.encodings_provided_sync(req, res).length > 1 then ["Accept-Encoding"] else []
    accept_charset = if @resource.charsets_provided_sync(req, res).length > 1 then ["Accept-Charset"] else []
    _.union(accept, accept_encoding, accept_charset, @resource.variances_sync(req, res))

  unquote_header: (header)->
    header.replace(/^"(.*?)"$/, '$1')

  convert_request_date: (date_str)->
    return null if date_str == null || date_str == ''
    date = new Date(date_str)
    date = null if isNaN(date.getTime())

  # TODO: encode this body
  encode_body: (req, res) ->
    null

  # "Service Available: Pong"
  v3b13: (req, res) ->
    @decision_test(@resource.ping, req, res, 'pong', 'v3b13b', 503)

  # "Service Available"
  v3b13b: (req, res) ->
    @decision_test(@resource.service_available, req, res, true, 'v3b12', 503)

  # "Known method?"
  v3b12: (req, res) ->
    @decision_test(
      (req, res, next) =>
        next(_.contains(@resource.known_methods, req.method))
    , req, res, true, 'v3b11', 501)

  # "URI too long?"
  v3b11: (req, res) ->
    @decision_test(@resource.uri_too_long, req, res, true, 414, 'v3b10')

  # "Method allowed?"
  v3b10: (req, res) ->
    @decision_test(
      (req, res, next) =>
        if @resource.allowed_methods_sync?
          if _.contains(@resource.allowed_methods_sync(req, res), req.method)
            next(true)
          else
            res.headers["Allow"] = @resource.allowed_methods_sync(req, res).join(", ")
            next(false)
        else
          # TODO: filter through a list of defaults?
          next(true)
    , req, res, true, 'v3b9', 405)

  # "Malformed?"
  v3b9: (req, res) ->
    @decision_test(@resource.malformed_request, req, res, true, 400, 'v3b8')

  # "Authorized?"
  v3b8: (req, res) ->
    @decision_test(
      (req, res, next) =>
        if @resource.is_authorized?
          @resource.is_authorized(req, res, (reply)=>
            switch typeof(reply)
              when 'string'
                res.headers['WWW-Authenticate'] = reply
                next(401)
              when 'number', 'boolean'
                next(reply)
              # when 'boolean'
              #   next(reply)
              # else
              #   next(reply)
          )
        else
          # TODO: extract into defaults?
          next(true)
    , req, res, true, 'v3b7', 401)

  # "Forbidden?"
  v3b7: (req, res) ->
    @decision_test(@resource.forbidden, req, res, true, 403, 'v3b6')

  # "Okay Content-* Headers?"
  v3b6: (req, res) ->
    @decision_test(@resource.valid_content_headers, req, res, true, 'v3b5', 501)
  
  # "Known Content-Type?"
  v3b5: (req, res) ->
    @decision_test(@resource.known_content_type, req, res, true, 'v3b4', 415)

  # "Req Entity Too Large?"
  v3b4: (req, res) ->
    @decision_test(@resource.valid_entity_length, req, res, true, 'v3b3', 413)

  # "OPTIONS?"
  v3b3: (req, res) ->
    @decision_test(
      (req, res, next)=>
        if req.method == 'OPTIONS'
          # TODO: how to get the options in?
          hdrs = @resource.options(req, res)
          @respond(req, res, 200, hdrs)
          # next(200)
        else
          next('v3c3')
    , req, res, true, 200, 'v3c3')

  # Accept exists?
  v3c3: (req, res) ->
    @decision_test(
      (req, res, next)=>
        unless accept = @get_header_val(req, 'accept')
          # TODO:  = MediaType.parse(@resource.content_types_provided()[0][0])
          @metadata['Content-Type'] = _.first(_.keys(@resource.content_types_provided()))
          next('v3d4')
        else
          next('v3c4')
    , req, res, true, 'v3d4', 'v3c4')

  # Acceptable media type available?
  v3c4: (req, res) ->
    @decision_test(
      (req, res, next)=>
        types = _.keys(@resource.content_types_provided())
        chosen_type = @choose_media_type(types, @get_header_val(req, 'accept'))
        unless chosen_type
          next(406)
        else
          @metadata['Content-Type'] = chosen_type
          next('v3d4')
    , req, res, true, 'v3d4', 406)

  # Accept-Language exists?
  v3d4: (req, res) ->
    # TODO: ruby impl has more complexity than erlang... why?
    @decision_test(@get_header_val(req, "accept-language"), req, res, null, 'v3e5', 'v3d5')

  # Acceptable Language available? # WMACH-46 (do this as proper conneg)
  v3d5: (req, res) ->
    @decision_test(@resource.language_available, req, res, true, 'v3e5', 406)

  # Accept-Charset exists?
  v3e5: (req, res) ->
    if @choose_charset(req, res, @get_header_val(req, "accept-charset"))
      @d(req, res, 'v3e6')
    else
      @decision_test(@choose_charset(req, res, "*"), req, res, null, 406, 'v3f6')

  # Acceptable Charset available?
  v3e6: (req, res) ->
    @decision_test(@choose_charset(req, res, @get_header_val(req, "accept-charset")), req, res, null, 406, 'v3f6')

  # Accept-Encoding exists?
  # (also, set content-type header here, now that charset is chosen)
  v3f6: (req, res) ->
    chosen_type = @metadata['Content-Type']
    chosen_type.params['charset'] = chosen_charset if chosen_charset = @metadata['Charset']
    res.headers['Content-Type'] = chosen_type
    unless @get_header_val(req, "accept-encoding")
      @decision_test(@choose_encoding(req, res, "identity;q=1.0,*;q=0.5"), req, res, null, 406, 'v3g7')
    else
      @d(req, res, 'v3f7')

  # Acceptable encoding available?
  v3f7: (req, res) ->
    @decision_test(@choose_encoding(req, res, @get_header_val(req, "accept-encoding")), req, res, null, 406, 'v3g7')

  # "@resource exists?"
  v3g7: (req, res) ->
    # this is the first place after all conneg, so set Vary here
    variences = @variences()
    res.headers['Vary'] = variances.join(", ") if variances?.length > 0
    @decision_test(@resource.resource_exists, req, res, true, 'v3g8', 'v3h7')
    # case variances() of
    #     [] -> nop;
    #     Variances ->
    #         wrcall({set_resp_header, "Vary", string:join(Variances, ", ")})
    # @decision_test(@resource.@resource_exists(), req, res, true, 'v3g8', v3h7);

  # "If-Match exists?"
  v3g8: (req, res) ->
    @decision_test(@get_header_val(req, "if-match"), req, res, null, 'v3h10', 'v3g9')
  
  # "If-Match: * exists"
  v3g9: (req, res) ->
    @decision_test(@get_header_val(req, "if-match"), req, res, '*', 'v3h10', 'v3g11')
  
  # "ETag in If-Match"
  v3g11: (req, res) ->
    request_etags = @get_header_val(req, "if-match").split(/\s*,\s*/).map((etag) => @unquote_header(etag))
    @decision_test(
      (req, res, next)=>
        @resource.generate_etag req, res, (reply)=>
          next(_.contains(request_etags, reply))
    , req, res, true, 'v3h10', 412)

  # "If-Match exists"
  # (note: need to reflect this change at in next version of diagram)
  v3h7: (req, res) ->
    @decision_test(@get_header_val(req, "if-match"), req, res, null, 'v3i7', 412)
  
  # "If-unmodified-since exists?"
  v3h10: (req, res) ->
    @decision_test(@get_header_val(req, "if-unmodified-since"), req, res, null ,'v3i12', 'v3h11')
  
  # "I-UM-S is valid date?"
  v3h11: (req, res) ->
    @metadata['If-Unmodified-Since'] = date = @get_header_val(req, "if-unmodified-since")
    @decision_test(@convert_request_date(date), req, res, null, 'v3i12', 'v3h12')

  # "Last-Modified > I-UM-S?"
  v3h12: (req, res) ->
    req_date = @convert_request_date(@get_header_val(req, "if-unmodified-since"))
    @decision_test(
      (req, res, next) =>
        # last_modified should next(date)
        @resource.last_modified reg, res, (reply)->
          if typeof(reply) == 'object'
            next(reply > req_date)
          else if typeof(reply) == 'boolean'
            # if next(true), assume this means continue
            next(!reply)
          else
            next(reply)
    , req, res, true, 412, 'v3i12')

  # "Moved permanently? (apply PUT to different URI)"
  v3i4: (req, res) ->
    @decision_test(
      (req, res, next)=>
        @resource.moved_permanently req, res, (reply)=>
          switch typeof(reply)
            when 'string'
              response.headers["Location"] = reply
              next(301)
            # when 'number'
            #   next(reply)
            else
              next(reply)
    , req, res, true, 301, 'v3p3')

  # PUT?
  v3i7: (req, res) ->
    @decision_test(req.method, req, res, 'PUT', 'v3i4', 'v3k7')
  
  # "If-none-match exists?"
  v3i12: (req, res) ->
    @decision_test(@get_header_val(req, "if-none-match"), req, res, null, 'v3l13', 'v3i13')

  # "If-None-Match: * exists?"
  v3i13: (req, res) ->
    @decision_test(@get_header_val(req, "if-none-match"), req, res, "*", 'v3j18', 'v3k13')

  # GET or HEAD?
  v3j18: (req, res) ->
    @decision_test((req.method == 'GET' || req.method == 'HEAD'), req, res, true, 304, 412)
  
  # "Moved permanently?"
  v3k5: (req, res) ->
    @decision_test(
      (req, res, next)=>
        @resource.moved_permanently req, res, (reply)=>
          switch typeof(reply)
            when 'string'
              res.headers["Location"] = reply
              next(301)
            # when 'number'
            #   next(reply)
            else
              next(reply)
    , req, res, true, 301, 'v3l5')

  # "Previously existed?"
  v3k7: (req, res) ->
    @decision_test(@resource.previously_existed, req, res, true, 'v3k5', 'v3l7')

  # "Etag in if-none-match?"
  v3k13: (req, res) ->
    request_etags = @get_header_val(req, "if-none-match").split(/\s*,\s*/).map((etag) => @unquote_header(etag))
    @decision_test(
      (req, res, next)=>
        @resource.generate_etag req, res, (reply)=>
          next(_.contains(request_etags, reply))
    , req, res, true, 'v3j18', 'v3l13')

  # "Moved temporarily?"
  v3l5: (req, res) ->
    @decision_test(
      (req, res, next)=>
        @resource.moved_temporarily req, res, (reply)=>
          switch typeof(reply)
            when 'string'
              res.headers["Location"] = reply
              next(307)
            else
              next(reply)
    , req, res, true, 301, 'v3m5')

  # "POST?"
  v3l7: (req, res) ->
    @decision_test(req.method, req, res, 'POST', 'v3m7', 404)

  # "IMS exists?"
  v3l13: (req, res) ->
    @decision_test(@get_header_val(req, "if-modified-since"), req, res, null, 'v3m16', 'v3l14')

  # "IMS is valid date?"
  v3l14: (req, res) -> 
    @metadata['If-Unmodified-Since'] = date = @get_header_val(req, "if-modified-since")
    @decision_test(@convert_request_date(date), req, res, null, 'v3m16', 'v3l15')

  # "IMS > Now?"
  v3l15: (req, res) ->
    req_date = @convert_request_date(@get_header_val(req, "if-modified-since"))
    @decision_test(
      (req, res, next) -> next(req_date > new Date())
    , req, res, true, 'v3m16', 'v3l17')


  # "Last-Modified > IMS?"
  v3l17: (req, res) ->
    ims_date = @convert_request_date(@get_header_val(req, "if-modified-since"))
    @decision_test(
      (req, res, next) =>
        # last_modified should next(date)
        @resource.last_modified reg, res, (reply)->
          if typeof(reply) == 'object'
            next(reply > ims_date)
          else if typeof(reply) == 'boolean'
            # if next(true), assume this means continue
            next(!reply)
          else
            next(reply)
    , req, res, true, 'v3m16', 304)

  
  # "POST?"
  v3m5: (req, res) ->
    @decision_test(req.method, req, res, 'POST', 'v3n5', 410)

  # "Server allows POST to missing @resource?"
  v3m7: (req, res) ->
    @decision_test(@resource.allow_missing_post, req, res, true, 'v3n11', 404)
  
  # "DELETE?"
  v3m16: (req, res) ->
    @decision_test(req.method, req, res, 'DELETE', 'v3m20', 'v3n16')

  # DELETE enacted immediately?
  # Also where DELETE is forced.
  v3m20: (req, res) ->
    @decision_test(@resource.delete_resource, req, res, true, 'v3m20b', 500)
  
  v3m20b: (req, res) ->
    @decision_test(@resource.delete_completed, req, res, true, 'v3o20', 202)
  
  # "Server allows POST to missing @resource?"
  v3n5: (req, res) ->
    @decision_test(@resource.allow_missing_post, req, res, true, 'v3n11', 410)

  stage1_ok: (req, res) ->
    if res.is_redirect()
      if res.headers['Location']
        @respond(req, res, 303)
      else
        @error_response('Response had do_redirect but no Location')
    else
      @d(req, res, 'v3p11')


  # "Redirect?"
  v3n11: (req, res) ->
    @resource.post_is_create req, res, (post_is_create)=>
      if post_is_create
        @resource.create_path req, res, (uri)=>
          if uri
            @resource.base_uri req, res, (base_uri)=>
              base_uri = @resource.base_uri() || req.base_uri()
              req.disp_path = base_uri + '/' + uri
              res.headers['Location'] = req.disp_path
              result = accept_helper()
              if typeof(result) == 'number'
                @respond(result)
              else
                @stage1_ok(req, res)
          else
            @error_response('post_is_create w/o create_path')
      else
        @resource.process_post req, res, (processed_post)=>
          if typeof(processed_post)
            @respond(processed_post)
          else if processed_post
            # TODO: encode_body_if_set()
            @stage1_ok(req, res)
          else
            @error_response(processed_post)

  # "POST?"
  v3n16: (req, res) ->
    @decision_test(req.method, req, res, 'POST', 'v3n11', 'v3o16')

  # Conflict?
  v3o14: (req, res) ->
    @resource.is_conflict req, res, (is_conflict)=>
      if is_conflict
        @respond(409)
      else
        result = accept_helper()
        if typeof(res) == 'number'
          @respond(result)
        else
          @d('v3p11')

  # "PUT?"
  v3o16: (req, res) ->
    @decision_test(req.method, req, res, 'PUT', 'v3o14', 'v3o18')

  # Multiple representations?
  # (also where body generation for GET and HEAD is done)
  v3o18: (req, res) ->
    if req.method == 'GET' || req.method == 'HEAD'
      # TODO: call these async
      @resource.generate_etag req, res, (etag) =>
        res.header["ETag"] = "\"#{etag}\"" if etag

        @resource.last_modified req, res, (last_modified) =>
          res.header["Last-Modified"] = new Date(last_modified) if last_modified
          # httpd_util:rfc1123_date(calendar:universal_time_to_local_time(LM))

          @resource.expires req, res, (expires) =>
            res.header["Expires"] = new Date(expires) if expires
            # httpd_util:rfc1123_date(calendar:universal_time_to_local_time(Exp))})
        
            @resource.content_types_provided req, res, (content_types_provided) =>

              content_types = _.pairs(content_types_provided)
              content_type = @metadata['Content-Type']
              matching_ct = _.find(content_types, (ct) => content_type == ct[0])
              
              # call the content type handler
              @resource[matching_ct[1]].apply @resource, [req, res, (result) =>
                if typeof(result) == 'number'
                  @respond(result)
                else
                  res.body = result
                  @encode_body(req, res)
                  @d('v3o18b')
              ]
    else
      @d('v3o18b')

  v3o18b: (req, res) ->
    @decision_test(@resource.multiple_choices, req, res, true, 300, 200)
  
  # Response includes an entity?
  v3o20: (req, res) ->
    @decision_test(req.has_response_body(), req, res, true, 'v3o18', 204)

  # Conflict?
  v3p3: (req, res) ->
    @resource.is_conflict req, res, (is_conflict)=>
      if is_conflict
        @respond(409)
      else
        result = accept_helper()
        if typeof(res) == 'number'
          @respond(result)
        else
          @d('v3p11')

  # New @resource?  (at this point boils down to "has location header")
  v3p11: (req, res) ->
    @decision_test(@get_header_val(req, 'location'), req, res, null, 'v3o20', 201)

  accept_helper: () ->
    null
    # CT = case get_header_val("Content-Type") of
    #          undefined -> "application/octet-stream";
    #          Other -> Other
    #      end,
    # {MT, MParams} = webmachine_util:media_type_to_detail(CT),
    # wrcall({set_metadata, 'mediaparams', MParams}),
    # case [Fun || {Type,Fun} <-
    #                  resource_call(content_types_accepted), MT =:= Type] of
    #     [] -> {respond,415};
    #     AcceptedContentList ->
    #         F = hd(AcceptedContentList),
    #         case resource_call(F) of
    #             true ->
    #                 encode_body_if_set(),
    #                 true;
    #             Result -> Result
    #         end
    # end.


module.exports = Flow
