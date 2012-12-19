_    = require('underscore')

class FSM
  constructor: (resource, trace)->
    @resource = resource
    # TODO: Ruby had a good idea, but actually use this if you can do it async
    @metadata = {}
    @trace = trace

  # Handles standard decisions where halting is allowed
  decisionTest: (test, req, res, value, iftrue, iffalse) ->
    if test?
      switch typeof(test)
        when 'function'
          test(req, res, (testReply)=>
            headers = {}
            if value == testReply
              @d(req, res, iftrue, headers)
            else if typeof(testReply) == 'number'
              @respond(req, res, testReply, {})
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
      # deal with null matches and true values
      if test == null && test == value || value
        @d(req, res, iftrue, headers)
      else
        @d(req, res, iffalse, headers)

  d: (req, res, reply, headers={}) ->
    # console.log "number #{reply}"
    if typeof(reply) == 'number'
      @respond(req, res, reply, {})
    else if typeof(reply) == 'function'
      reply(req, res)
    else
      throw "Only numbers and functions are expected"

  errorResponse: (req, res, message)->
    throw message

  respond: (req, res, code, headers={}) =>
    headers ||= {}
    res.headers = _.extend(res.headers, headers)
    switch code
      when 404
        res.res.writeHead(404, {'Content-Type': 'text/plain'})
        res.res.write('File Not Found')
      when 304
        delete res.headers['Content-Type']
        # TODO: add caching headers
    res.res.statusCode = code
    # res.res.writeHead(code, {})
    # TODO: ensure content length
    @resource.finishRequest(req, res) if @resource.finishRequest?
    res.res.end()

  getHeaderVal: (req, field)->
    @unquoteHeader(req.getReqHeader(field))

  chooseMediaType: (provided, accept)->
    # TODO: better handle bad media types
    # TODO: order by q=qvalue
    requested = accept.split(/\s*,\s*/).map((mt)=> mt)
    # provided = provided.map((mt)=> @parse_media_type(mt))
    _.find provided, (providedMT)->
      _.find requested, (requestedMT)->
        requestedMT == '*/*' || providedMT == requestedMT

  # chooseCharset: (req, res, accepted)->
  #   accepted = accepted.split(/\s*,\s*/)
  #   provided = @resource.charsetsProvidedSync(req, res)
  #   match = (provided.length == 0)
  #   @metadata['Chosen-Charset'] = accepted[0] if match
  #   # TODO: sort using q values
  #   while !match && accepted.length
  #     accept = accepted.shift().split(/\s*;\s*/)[0].toLowerCase()
  #     match = (accept == "*" || provided.indexOf(accept) > -1)
  #     @metadata['Chosen-Charset'] = accept if match
  #   [match, @metadata['Chosen-Charset']]

  # TODO: also allow async charsetsProvided?
  chooseCharset: (req, res, charset)->
    provided = @resource.charsetsProvidedSync(req, res)
    # if charsetsProvided is set to empty, force a default
    if _.isEmpty(provided)
      return 'utf-8'
    else
      charsets = _.keys(provided)
      if chosenCharset = @doChooseCharset(charsets, charset, 'utf-8')
        return @metadata['Chosen-Charset'] = chosenCharset
    return null

  # TODO: implement choosing the proper charset
  doChooseCharset: (charsets, charset, defaultEnc) ->
    choices = _.map(charsets, (s)->s.toLowerCase())
    acceptedCharsets = charset.split(/\s*,\s*/)
    # TODO: should this be pushed?
    # acceptedCharsets.push defaultEnc
    # TODO: sort by priority
    accepted = acceptedCharsets.map((mt)=> [1.0, mt])
    # console.log accepted
    # TODO: actually use priority
    if _.contains(acceptedCharsets, defaultEnc)
      default_priority = 1.0 #accepted.priority_of(defaultEnc)
    else
      default_priority = 0.0
    if _.contains(acceptedCharsets, '*')
      star_priority = 1.0
    else
      star_priority = 0.0 #accepted.priority_of("*")
    # console.log accepted
    default_ok = (default_priority == null && star_priority != 0.0) || default_priority
    any_ok = star_priority && star_priority > 0.0
    # assumed to be sorted by priority
    chosen = _.find accepted, (value)->
      priority = value[0]
      acceptable = value[1]
      if priority == 0.0
        choices = _.without(choices, acceptable.toLowerCase())
        false
      else
        _.contains(choices, acceptable.toLowerCase())

    # Use the matching one, Or first if "*", Or default
    if chosen && _.last(chosen)
      _.last(chosen)
    else if any_ok && _.first(choices)
      _.first(choices)
    else if default_ok && _.contains(choices, defaultEnc) && defaultEnc
      defaultEnc

    # if charset == '*'
    #   _.first(charsets)
    # else
    #   _.find(charsets, (cs)-> cs == charset)

  # TODO: implement choose encoding
  chooseEncoding: (req, res, encoding)->
    "identity"

  variances: (req, res)->
    accept = if @resource.contentTypesProvidedSync(req, res).length > 1 then ["Accept"] else []
    acceptEncoding = if @resource.encodingsProvidedSync(req, res).length > 1 then ["Accept-Encoding"] else []
    acceptCharset = if @resource.charsetsProvidedSync(req, res).length > 1 then ["Accept-Charset"] else []
    _.union(accept, acceptEncoding, acceptCharset, @resource.variancesSync(req, res))

  unquoteHeader: (header)->
    if header then header.replace(/^"(.*?)"$/, '$1') else null

  convertRequestDate: (dateStr)->
    return null if dateStr == null || dateStr == ''
    date = new Date(dateStr)
    date = null if isNaN(date.getTime())

  # TODO: encode this body
  encodeBody: (req, res) =>
    null

  run: (req, res) =>
    @v3b13(req, res)

  tracePush: (step)->
    @trace.push(step) if @trace?

  # "Service Available: Pong"
  v3b13: (req, res) =>
    @tracePush 'v3b13'
    @decisionTest(@resource.ping, req, res, 'pong', @v3b13b, 503)

  # "Service Available"
  v3b13b: (req, res) =>
    @tracePush 'v3b13b'
    @decisionTest(@resource.serviceAvailable, req, res, true, @v3b12, 503)

  # "Known method?"
  v3b12: (req, res) =>
    @tracePush 'v3b12'
    @decisionTest(
      (req, res, next) =>
        # console.log req.method
        # console.log _.contains(@resource.knownMethodsSync(req, res))
        next(_.contains(@resource.knownMethodsSync(req, res), req.method))
    , req, res, true, @v3b11, 501)

  # "URI too long?"
  v3b11: (req, res) =>
    @tracePush 'v3b11'
    @decisionTest(@resource.uriTooLong, req, res, true, 414, @v3b10)

  # "Method allowed?"
  v3b10: (req, res) =>
    @tracePush 'v3b10'
    # console.log @resource.allowedMethodsSync?
    @decisionTest(
      (req, res, next) =>
        if @resource.allowedMethodsSync?
          if _.contains(@resource.allowedMethodsSync(req, res), req.method)
            next(true)
          else
            res.headers["Allow"] = @resource.allowedMethodsSync(req, res).join(", ")
            next(false)
        else
          # TODO: filter through a list of defaults?
          next(true)
    , req, res, true, @v3b9, 405)

  # "Malformed?"
  v3b9: (req, res) =>
    @tracePush 'v3b9'
    @decisionTest(@resource.malformedRequest, req, res, true, 400, @v3b8)

  # "Authorized?"
  v3b8: (req, res) =>
    @tracePush 'v3b8'
    @decisionTest(
      (req, res, next) =>
        if @resource.isAuthorized?
          @resource.isAuthorized(req, res, (reply)=>
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
    , req, res, true, @v3b7, 401)

  # "Forbidden?"
  v3b7: (req, res) =>
    @tracePush 'v3b7'
    @decisionTest(@resource.forbidden, req, res, true, 403, @v3b6)

  # "Okay Content-* Headers?"
  v3b6: (req, res) =>
    @tracePush 'v3b6'
    @decisionTest(@resource.validContentHeaders, req, res, true, @v3b5, 501)
  
  # "Known Content-Type?"
  v3b5: (req, res) =>
    @tracePush 'v3b5'
    @decisionTest(@resource.knownContentType, req, res, true, @v3b4, 415)

  # "Req Entity Too Large?"
  v3b4: (req, res) =>
    @tracePush 'v3b4'
    @decisionTest(@resource.validEntityLength, req, res, true, @v3b3, 413)

  # "OPTIONS?"
  v3b3: (req, res) =>
    @tracePush 'v3b3'
    @decisionTest(
      (req, res, next)=>
        if req.method == 'OPTIONS'
          # TODO: how to get the options in?
          hdrs = @resource.optionsSync(req, res)
          @respond(req, res, 200, hdrs)
          # next(200)
        else
          next(false)
    , req, res, true, 200, @v3c3)

  # Accept exists?
  v3c3: (req, res) =>
    @tracePush 'v3c3'
    @decisionTest(
      (req, res, next)=>
        unless accept = @getHeaderVal(req, 'accept')
          # TODO: @parse_media_type(_.first(_.keys(@resource.contentTypesProvidedSync(req, res))))
          @metadata['Content-Type'] = _.first(_.keys(@resource.contentTypesProvidedSync(req, res)))
          next(true)
        else
          next(false)
    , req, res, true, @v3d4, @v3c4)

  # Acceptable media type available?
  v3c4: (req, res) =>
    @tracePush 'v3c4'
    @decisionTest(
      (req, res, next)=>
        types = _.keys(@resource.contentTypesProvidedSync(req, res))
        chosenType = @chooseMediaType(types, @getHeaderVal(req, 'accept'))
        if chosenType
          @metadata['Content-Type'] = chosenType
          next(true)
        else
          next(406)
    , req, res, true, @v3d4, 406)

  # Accept-Language exists?
  v3d4: (req, res) =>
    @tracePush 'v3d4'
    # TODO: ruby impl has more complexity than erlang... why?
    @decisionTest(@getHeaderVal(req, "accept-language"), req, res, null, @v3e5, @v3d5)

  # Acceptable Language available? # WMACH-46 (do this as proper conneg)
  v3d5: (req, res) =>
    @tracePush 'v3d5'
    @decisionTest(@resource.languageAvailable, req, res, true, @v3e5, 406)

  # Accept-Charset exists?
  v3e5: (req, res) =>
    @tracePush 'v3e5'
    # console.log @chooseCharset(req, res, @getHeaderVal(req, "accept-charset"))
    # if @chooseCharset(req, res, @getHeaderVal(req, "accept-charset"))
    if @getHeaderVal(req, "accept-charset")
      @d(req, res, @v3e6)
    else
      # console.log @chooseCharset(req, res, "*")
      @decisionTest(@chooseCharset(req, res, "*"), req, res, null, 406, @v3f6)

  # Acceptable Charset available?
  v3e6: (req, res) =>
    @tracePush 'v3e6'
    @decisionTest(@chooseCharset(req, res, @getHeaderVal(req, "accept-charset")), req, res, null, 406, @v3f6)

  # Accept-Encoding exists?
  # (also, set content-type header here, now that charset is chosen)
  v3f6: (req, res) =>
    @tracePush 'v3f6'
    chosenType = @metadata['Content-Type']
    chosenType.params['charset'] = chosenCharset if chosenCharset = @metadata['Charset']
    res.headers['Content-Type'] = chosenType
    unless @getHeaderVal(req, "accept-encoding")
      @decisionTest(@chooseEncoding(req, res, "identity;q=1.0,*;q=0.5"), req, res, null, 406, @v3g7)
    else
      @d(req, res, @v3f7)

  # Acceptable encoding available?
  v3f7: (req, res) =>
    @tracePush 'v3f7'
    @decisionTest(@chooseEncoding(req, res, @getHeaderVal(req, "accept-encoding")), req, res, null, 406, @v3g7)

  # "@resource exists?"
  v3g7: (req, res) =>
    @tracePush 'v3g7'
    # this is the first place after all conneg, so set Vary here
    variances = @variances()
    res.headers['Vary'] = variances.join(", ") if variances?.length > 0
    @decisionTest(@resource.resourceExists, req, res, true, @v3g8, @v3h7)

  # "If-Match exists?"
  v3g8: (req, res) =>
    @tracePush 'v3g8'
    @decisionTest(@getHeaderVal(req, "if-match"), req, res, null, @v3h10, @v3g9)
  
  # "If-Match: * exists"
  v3g9: (req, res) =>
    @tracePush 'v3g9'
    @decisionTest(@getHeaderVal(req, "if-match"), req, res, '*', @v3h10, @v3g11)
  
  # "ETag in If-Match"
  v3g11: (req, res) =>
    @tracePush 'v3g11'
    requestEtags = @getHeaderVal(req, "if-match").split(/\s*,\s*/).map((etag) => @unquoteHeader(etag))
    @decisionTest(
      (req, res, next)=>
        @resource.generateEtag req, res, (reply)=>
          next(_.contains(requestEtags, reply))
    , req, res, true, @v3h10, 412)

  # "If-Match exists"
  # (note: need to reflect this change at in next version of diagram)
  v3h7: (req, res) =>
    @tracePush 'v3h7'
    @decisionTest(@getHeaderVal(req, "if-match"), req, res, null, @v3i7, 412)
  
  # "If-unmodified-since exists?"
  v3h10: (req, res) =>
    @tracePush 'v3h10'
    @decisionTest(@getHeaderVal(req, "if-unmodified-since"), req, res, null ,@v3i12, @v3h11)
  
  # "I-UM-S is valid date?"
  v3h11: (req, res) =>
    @tracePush 'v3h11'
    @metadata['If-Unmodified-Since'] = date = @getHeaderVal(req, "if-unmodified-since")
    @decisionTest(@convertRequestDate(date), req, res, null, @v3i12, @v3h12)

  # "Last-Modified > I-UM-S?"
  v3h12: (req, res) =>
    @tracePush 'v3h12'
    reqDate = @convertRequestDate(@getHeaderVal(req, "if-unmodified-since"))
    @decisionTest(
      (req, res, next) =>
        # lastModified should next(date)
        @resource.lastModified req, res, (reply)->
          if typeof(reply) == 'object'
            next(reply > reqDate)
          else if typeof(reply) == 'boolean'
            # if next(true), assume this means continue
            next(!reply)
          else if null
            next(false)
          else
            next(reply)
    , req, res, true, 412, @v3i12)

  # "Moved permanently? (apply PUT to different URI)"
  v3i4: (req, res) =>
    @tracePush 'v3i4'
    @decisionTest(
      (req, res, next)=>
        @resource.movedPermanently req, res, (reply)=>
          switch typeof(reply)
            when 'string'
              response.headers["Location"] = reply
              next(301)
            # when 'number'
            #   next(reply)
            else
              next(reply)
    , req, res, true, 301, @v3p3)

  # PUT?
  v3i7: (req, res) =>
    @tracePush 'v3i7'
    @decisionTest(req.method, req, res, 'PUT', @v3i4, @v3k7)
  
  # "If-none-match exists?"
  v3i12: (req, res) =>
    @tracePush 'v3i12'
    @decisionTest(@getHeaderVal(req, "if-none-match"), req, res, null, @v3l13, @v3i13)

  # "If-None-Match: * exists?"
  v3i13: (req, res) =>
    @tracePush 'v3i13'
    @decisionTest(@getHeaderVal(req, "if-none-match"), req, res, "*", @v3j18, @v3k13)

  # GET or HEAD?
  v3j18: (req, res) =>
    @tracePush 'v3j18'
    @decisionTest((req.method == 'GET' || req.method == 'HEAD'), req, res, true, 304, 412)
  
  # "Moved permanently?"
  v3k5: (req, res) =>
    @tracePush 'v3k5'
    @decisionTest(
      (req, res, next)=>
        @resource.movedPermanently req, res, (reply)=>
          switch typeof(reply)
            when 'string'
              res.headers["Location"] = reply
              next(301)
            # when 'number'
            #   next(reply)
            else
              next(reply)
    , req, res, true, 301, @v3l5)

  # "Previously existed?"
  v3k7: (req, res) =>
    @tracePush 'v3k7'
    @decisionTest(@resource.previouslyExisted, req, res, true, @v3k5, @v3l7)

  # "Etag in if-none-match?"
  v3k13: (req, res) =>
    @tracePush 'v3k13'
    requestEtags = @getHeaderVal(req, "if-none-match").split(/\s*,\s*/).map((etag) => @unquoteHeader(etag))
    @decisionTest(
      (req, res, next)=>
        @resource.generateEtag req, res, (reply)=>
          next(_.contains(requestEtags, reply))
    , req, res, true, @v3j18, @v3l13)

  # "Moved temporarily?"
  v3l5: (req, res) =>
    @tracePush 'v3l5'
    @decisionTest(
      (req, res, next)=>
        @resource.movedTemporarily req, res, (reply)=>
          switch typeof(reply)
            when 'string'
              res.headers["Location"] = reply
              next(307)
            else
              next(reply)
    , req, res, true, 301, @v3m5)

  # "POST?"
  v3l7: (req, res) =>
    @tracePush 'v3l7'
    @decisionTest(req.method, req, res, 'POST', @v3m7, 404)

  # "IMS exists?"
  v3l13: (req, res) =>
    @tracePush 'v3l13'
    @decisionTest(@getHeaderVal(req, "if-modified-since"), req, res, null, @v3m16, @v3l14)

  # "IMS is valid date?"
  v3l14: (req, res) =>
    @tracePush 'v3l14' 
    @metadata['If-Unmodified-Since'] = date = @getHeaderVal(req, "if-modified-since")
    @decisionTest(@convertRequestDate(date), req, res, null, @v3m16, @v3l15)

  # "IMS > Now?"
  v3l15: (req, res) =>
    @tracePush 'v3l15'
    reqDate = @convertRequestDate(@getHeaderVal(req, "if-modified-since"))
    @decisionTest(
      (req, res, next) -> next(reqDate > new Date())
    , req, res, true, @v3m16, @v3l17)


  # "Last-Modified > IMS?"
  v3l17: (req, res) =>
    @tracePush 'v3l17'
    imsDate = @convertRequestDate(@getHeaderVal(req, "if-modified-since"))
    @decisionTest(
      (req, res, next) =>
        # lastModified should next(date)
        @resource.lastModified req, res, (reply)->
          if typeof(reply) == 'object'
            next(reply > imsDate)
          else if typeof(reply) == 'boolean'
            # if next(true), assume this means continue
            next(!reply)
          else
            next(reply)
    , req, res, true, @v3m16, 304)

  
  # "POST?"
  v3m5: (req, res) =>
    @tracePush 'v3m5'
    @decisionTest(req.method, req, res, 'POST', @v3n5, 410)

  # "Server allows POST to missing @resource?"
  v3m7: (req, res) =>
    @tracePush 'v3m7'
    @decisionTest(@resource.allowMissingPost, req, res, true, @v3n11, 404)
  
  # "DELETE?"
  v3m16: (req, res) =>
    @tracePush 'v3m16'
    @decisionTest(req.method, req, res, 'DELETE', @v3m20, @v3n16)

  # DELETE enacted immediately?
  # Also where DELETE is forced.
  v3m20: (req, res) =>
    @tracePush 'v3m20'
    @decisionTest(@resource.deleteResource, req, res, true, @v3m20b, 500)
  
  v3m20b: (req, res) =>
    @tracePush 'v3m20b'
    @decisionTest(@resource.deleteCompleted, req, res, true, @v3o20, 202)
  
  # "Server allows POST to missing @resource?"
  v3n5: (req, res) =>
    @tracePush 'v3n5'
    @decisionTest(@resource.allowMissingPost, req, res, true, @v3n11, 410)

  stage1Ok: (req, res) =>
    @tracePush 'stage1Ok'
    if res.isRedirect()
      if res.headers['Location']
        @respond(req, res, 303)
      else
        @errorResponse('Response had doRedirect but no Location')
    else
      @d(req, res, @v3p11)


  # "Redirect?"
  v3n11: (req, res) =>
    @tracePush 'v3n11'
    @resource.postIsCreate req, res, (postIsCreate)=>
      if postIsCreate
        @resource.createPath req, res, (uri)=>
          if uri
            @resource.baseUri req, res, (baseUri)=>
              baseUri = @resource.baseUri() || req.baseUri()
              req.dispPath = baseUri + '/' + uri
              res.headers['Location'] = req.dispPath
              result = acceptHelper()
              if typeof(result) == 'number'
                @respond(result)
              else
                @stage1Ok(req, res)
          else
            @errorResponse('postIsCreate w/o createPath')
      else
        @resource.processPost req, res, (processedPost)=>
          if typeof(processedPost)
            @respond(processedPost)
          else if processedPost
            # TODO: encodeBodyIfSet()
            @stage1Ok(req, res)
          else
            @errorResponse(processedPost)

  # "POST?"
  v3n16: (req, res) =>
    @tracePush 'v3n16'
    @decisionTest(req.method, req, res, 'POST', @v3n11, @v3o16)

  # Conflict?
  v3o14: (req, res) =>
    @tracePush 'v3o14'
    @resource.isConflict req, res, (isConflict)=>
      if isConflict
        @respond(409)
      else
        result = acceptHelper()
        if typeof(res) == 'number'
          @respond(result)
        else
          @d(req, res, @v3p11)

  # "PUT?"
  v3o16: (req, res) =>
    @tracePush 'v3o16'
    @decisionTest(req.method, req, res, 'PUT', @v3o14, @v3o18)

  # Multiple representations?
  # (also where body generation for GET and HEAD is done)
  v3o18: (req, res) =>
    @tracePush 'v3o18'
    if req.method == 'GET' || req.method == 'HEAD'
      # TODO: call these async
      @resource.generateEtag req, res, (etag) =>
        res.header["ETag"] = "\"#{etag}\"" if etag

        @resource.lastModified req, res, (lastModified) =>
          res.header["Last-Modified"] = new Date(lastModified) if lastModified
          # httpdUtil:rfc1123Date(calendar:universalTimeToLocalTime(LM))

          @resource.expires req, res, (expires) =>
            res.header["Expires"] = new Date(expires) if expires
            # httpdUtil:rfc1123Date(calendar:universalTimeToLocalTime(Exp))})
        
            contentTypes = @resource.contentTypesProvidedSync(req, res)
            contentType = @metadata['Content-Type']
            matchingCt = contentTypes[contentType]

            # call the content type handler
            @resource[matchingCt].apply @resource, [req, res, (result) =>
              if typeof(result) == 'number'
                @respond(req, res, result)
              else
                res.body = result
                @encodeBody(req, res)
                @d(req, res, @v3o18b)
            ]
    else
      console.log 'd'
      @d(req, res, @v3o18b)

  v3o18b: (req, res) =>
    @tracePush 'v3o18b'
    @decisionTest(@resource.multipleChoices, req, res, true, 300, 200)
  
  # Response includes an entity?
  v3o20: (req, res) =>
    @tracePush 'v3o20'
    @decisionTest(req.hasResponseBody(), req, res, true, @v3o18, 204)

  # Conflict?
  v3p3: (req, res) =>
    @tracePush 'v3p3'
    @resource.isConflict req, res, (isConflict)=>
      if isConflict
        @respond(409)
      else
        result = acceptHelper()
        if typeof(res) == 'number'
          @respond(result)
        else
          @d(req, res, @v3p11)

  # New @resource?  (at this point boils down to "has location header")
  v3p11: (req, res) =>
    @tracePush 'v3p11'
    @decisionTest(@getHeaderVal(req, 'location'), req, res, null, @v3o20, 201)

  acceptHelper: () ->
    null
    # CT = case getHeaderVal("Content-Type") of
    #          undefined -> "application/octet-stream";
    #          Other -> Other
    #      end,
    # {MT, MParams} = webmachineUtil:mediaTypeToDetail(CT),
    # wrcall({setMetadata, 'mediaparams', MParams}),
    # case [Fun || {Type,Fun} <-
    #                  resourceCall(contentTypesAcceptedSync), MT =:= Type] of
    #     [] -> {respond,415};
    #     AcceptedContentList ->
    #         F = hd(AcceptedContentList),
    #         case resourceCall(F) of
    #             true ->
    #                 encodeBodyIfSet(),
    #                 true;
    #             Result -> Result
    #         end
    # end.


module.exports = FSM
