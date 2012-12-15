_    = require('underscore')

class FSM
  constructor: (resource)->
    @resource = resource
    # TODO: Ruby had a good idea, but actually use this if you can do it async
    @metadata = {}

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
      if value
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
        res.headers.delete('Content-Type')
        # TODO: add caching headers
    res.res.statusCode = code
    # res.res.writeHead(code, {})
    # TODO: ensure content length
    @resource.finishRequest(req, res) if @resource.finishRequest?
    res.res.end()

  getHeaderVal: (req, field)->
    @unquoteHeader(req.getReqHeader(field))

  # TODO: impl
  chooseMediaType: (types, mt)->
    null

  # TODO: also allow async charsetsProvided?
  chooseCharset: (req, res, charset)->
    provided = @resource.charsetsProvidedSync(req, res)
    if provided?.length?
      charsets = _.keys(provided)
      if chosenCharset = doChooseCharset(charsets, charset)
        @metadata['Chosen-Charset'] = chosenCharset
    else
      null

  # TODO: implement choosing the proper charset
  doChooseCharset: (charsets, charset) ->
    _.first(charsets)

  # TODO: implement choose encoding
  chooseEncoding: (req, res, encoding)->
    null

  variances: (req, res)->
    accept = if @resource.contentTypesProvidedSync(req, res).length > 1 then ["Accept"] else []
    acceptEncoding = if @resource.encodingsProvidedSync(req, res).length > 1 then ["Accept-Encoding"] else []
    acceptCharset = if @resource.charsetsProvidedSync(req, res).length > 1 then ["Accept-Charset"] else []
    _.union(accept, acceptEncoding, acceptCharset, @resource.variancesSync(req, res))

  unquoteHeader: (header)->
    header && header.replace(/^"(.*?)"$/, '$1')

  convertRequestDate: (dateStr)->
    return null if dateStr == null || dateStr == ''
    date = new Date(dateStr)
    date = null if isNaN(date.getTime())

  # TODO: encode this body
  encodeBody: (req, res) =>
    null

  run: (req, res) =>
    @v3b13(req, res)

  # "Service Available: Pong"
  v3b13: (req, res) =>
    # console.log @v3b13b
    @decisionTest(@resource.ping, req, res, 'pong', @v3b13b, 503)

  # "Service Available"
  v3b13b: (req, res) =>
    # console.log @resource
    @decisionTest(@resource.serviceAvailable, req, res, true, @v3b12, 503)

  # "Known method?"
  v3b12: (req, res) =>
    @decisionTest(
      (req, res, next) =>
        # console.log req.method
        # console.log _.contains(@resource.knownMethodsSync(req, res))
        next(_.contains(@resource.knownMethodsSync(req, res), req.method))
    , req, res, true, @v3b11, 501)

  # "URI too long?"
  v3b11: (req, res) =>
    @decisionTest(@resource.uriTooLong, req, res, true, 414, @v3b10)

  # "Method allowed?"
  v3b10: (req, res) =>
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
    @decisionTest(@resource.malformedRequest, req, res, true, 400, @v3b8)

  # "Authorized?"
  v3b8: (req, res) =>
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
    @decisionTest(@resource.forbidden, req, res, true, 403, @v3b6)

  # "Okay Content-* Headers?"
  v3b6: (req, res) =>
    @decisionTest(@resource.validContentHeaders, req, res, true, @v3b5, 501)
  
  # "Known Content-Type?"
  v3b5: (req, res) =>
    @decisionTest(@resource.knownContentType, req, res, true, @v3b4, 415)

  # "Req Entity Too Large?"
  v3b4: (req, res) =>
    @decisionTest(@resource.validEntityLength, req, res, true, @v3b3, 413)

  # "OPTIONS?"
  v3b3: (req, res) =>
    @decisionTest(
      (req, res, next)=>
        if req.method == 'OPTIONS'
          # TODO: how to get the options in?
          hdrs = @resource.options(req, res)
          @respond(req, res, 200, hdrs)
          # next(200)
        else
          next(@v3c3)
    , req, res, true, 200, @v3c3)

  # Accept exists?
  v3c3: (req, res) =>
    @decisionTest(
      (req, res, next)=>
        unless accept = @getHeaderVal(req, 'accept')
          # TODO:  = MediaType.parse(@resource.contentTypesProvidedSync()[0][0])
          @metadata['Content-Type'] = _.first(_.keys(@resource.contentTypesProvidedSync()))
          next(@v3d4)
        else
          next(@v3c4)
    , req, res, true, @v3d4, @v3c4)

  # Acceptable media type available?
  v3c4: (req, res) =>
    @decisionTest(
      (req, res, next)=>
        types = _.keys(@resource.contentTypesProvidedSync())
        chosenType = @chooseMediaType(types, @getHeaderVal(req, 'accept'))
        unless chosenType
          next(406)
        else
          @metadata['Content-Type'] = chosenType
          next(@v3d4)
    , req, res, true, @v3d4, 406)

  # Accept-Language exists?
  v3d4: (req, res) =>
    # TODO: ruby impl has more complexity than erlang... why?
    @decisionTest(@getHeaderVal(req, "accept-language"), req, res, null, @v3e5, @v3d5)

  # Acceptable Language available? # WMACH-46 (do this as proper conneg)
  v3d5: (req, res) =>
    @decisionTest(@resource.languageAvailable, req, res, true, @v3e5, 406)

  # Accept-Charset exists?
  v3e5: (req, res) =>
    if @chooseCharset(req, res, @getHeaderVal(req, "accept-charset"))
      @d(req, res, @v3e6)
    else
      @decisionTest(@chooseCharset(req, res, "*"), req, res, null, 406, @v3f6)

  # Acceptable Charset available?
  v3e6: (req, res) =>
    @decisionTest(@chooseCharset(req, res, @getHeaderVal(req, "accept-charset")), req, res, null, 406, @v3f6)

  # Accept-Encoding exists?
  # (also, set content-type header here, now that charset is chosen)
  v3f6: (req, res) =>
    chosenType = @metadata['Content-Type']
    chosenType.params['charset'] = chosenCharset if chosenCharset = @metadata['Charset']
    res.headers['Content-Type'] = chosenType
    unless @getHeaderVal(req, "accept-encoding")
      @decisionTest(@chooseEncoding(req, res, "identity;q=1.0,*;q=0.5"), req, res, null, 406, @v3g7)
    else
      @d(req, res, @v3f7)

  # Acceptable encoding available?
  v3f7: (req, res) =>
    @decisionTest(@chooseEncoding(req, res, @getHeaderVal(req, "accept-encoding")), req, res, null, 406, @v3g7)

  # "@resource exists?"
  v3g7: (req, res) =>
    # this is the first place after all conneg, so set Vary here
    variences = @variences()
    res.headers['Vary'] = variances.join(", ") if variances?.length > 0
    @decisionTest(@resource.resourceExists, req, res, true, @v3g8, @v3h7)
    # case variances() of
    #     [] -> nop;
    #     Variances ->
    #         wrcall({setRespHeader, "Vary", string:join(Variances, ", ")})
    # @decisionTest(@resource.@resourceExists(), req, res, true, @v3g8, v3h7);

  # "If-Match exists?"
  v3g8: (req, res) =>
    @decisionTest(@getHeaderVal(req, "if-match"), req, res, null, @v3h10, @v3g9)
  
  # "If-Match: * exists"
  v3g9: (req, res) =>
    @decisionTest(@getHeaderVal(req, "if-match"), req, res, '*', @v3h10, @v3g11)
  
  # "ETag in If-Match"
  v3g11: (req, res) =>
    requestEtags = @getHeaderVal(req, "if-match").split(/\s*,\s*/).map((etag) => @unquoteHeader(etag))
    @decisionTest(
      (req, res, next)=>
        @resource.generateEtag req, res, (reply)=>
          next(_.contains(requestEtags, reply))
    , req, res, true, @v3h10, 412)

  # "If-Match exists"
  # (note: need to reflect this change at in next version of diagram)
  v3h7: (req, res) =>
    @decisionTest(@getHeaderVal(req, "if-match"), req, res, null, @v3i7, 412)
  
  # "If-unmodified-since exists?"
  v3h10: (req, res) =>
    @decisionTest(@getHeaderVal(req, "if-unmodified-since"), req, res, null ,@v3i12, @v3h11)
  
  # "I-UM-S is valid date?"
  v3h11: (req, res) =>
    @metadata['If-Unmodified-Since'] = date = @getHeaderVal(req, "if-unmodified-since")
    @decisionTest(@convertRequestDate(date), req, res, null, @v3i12, @v3h12)

  # "Last-Modified > I-UM-S?"
  v3h12: (req, res) =>
    reqDate = @convertRequestDate(@getHeaderVal(req, "if-unmodified-since"))
    @decisionTest(
      (req, res, next) =>
        # lastModified should next(date)
        @resource.lastModified reg, res, (reply)->
          if typeof(reply) == 'object'
            next(reply > reqDate)
          else if typeof(reply) == 'boolean'
            # if next(true), assume this means continue
            next(!reply)
          else
            next(reply)
    , req, res, true, 412, @v3i12)

  # "Moved permanently? (apply PUT to different URI)"
  v3i4: (req, res) =>
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
    @decisionTest(req.method, req, res, 'PUT', @v3i4, @v3k7)
  
  # "If-none-match exists?"
  v3i12: (req, res) =>
    @decisionTest(@getHeaderVal(req, "if-none-match"), req, res, null, @v3l13, @v3i13)

  # "If-None-Match: * exists?"
  v3i13: (req, res) =>
    @decisionTest(@getHeaderVal(req, "if-none-match"), req, res, "*", @v3j18, @v3k13)

  # GET or HEAD?
  v3j18: (req, res) =>
    @decisionTest((req.method == 'GET' || req.method == 'HEAD'), req, res, true, 304, 412)
  
  # "Moved permanently?"
  v3k5: (req, res) =>
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
    @decisionTest(@resource.previouslyExisted, req, res, true, @v3k5, @v3l7)

  # "Etag in if-none-match?"
  v3k13: (req, res) =>
    requestEtags = @getHeaderVal(req, "if-none-match").split(/\s*,\s*/).map((etag) => @unquoteHeader(etag))
    @decisionTest(
      (req, res, next)=>
        @resource.generateEtag req, res, (reply)=>
          next(_.contains(requestEtags, reply))
    , req, res, true, @v3j18, @v3l13)

  # "Moved temporarily?"
  v3l5: (req, res) =>
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
    @decisionTest(req.method, req, res, 'POST', @v3m7, 404)

  # "IMS exists?"
  v3l13: (req, res) =>
    @decisionTest(@getHeaderVal(req, "if-modified-since"), req, res, null, @v3m16, @v3l14)

  # "IMS is valid date?"
  v3l14: (req, res) => 
    @metadata['If-Unmodified-Since'] = date = @getHeaderVal(req, "if-modified-since")
    @decisionTest(@convertRequestDate(date), req, res, null, @v3m16, @v3l15)

  # "IMS > Now?"
  v3l15: (req, res) =>
    reqDate = @convertRequestDate(@getHeaderVal(req, "if-modified-since"))
    @decisionTest(
      (req, res, next) -> next(reqDate > new Date())
    , req, res, true, @v3m16, @v3l17)


  # "Last-Modified > IMS?"
  v3l17: (req, res) =>
    imsDate = @convertRequestDate(@getHeaderVal(req, "if-modified-since"))
    @decisionTest(
      (req, res, next) =>
        # lastModified should next(date)
        @resource.lastModified reg, res, (reply)->
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
    @decisionTest(req.method, req, res, 'POST', @v3n5, 410)

  # "Server allows POST to missing @resource?"
  v3m7: (req, res) =>
    @decisionTest(@resource.allowMissingPost, req, res, true, @v3n11, 404)
  
  # "DELETE?"
  v3m16: (req, res) =>
    @decisionTest(req.method, req, res, 'DELETE', @v3m20, @v3n16)

  # DELETE enacted immediately?
  # Also where DELETE is forced.
  v3m20: (req, res) =>
    @decisionTest(@resource.deleteResource, req, res, true, @v3m20b, 500)
  
  v3m20b: (req, res) =>
    @decisionTest(@resource.deleteCompleted, req, res, true, @v3o20, 202)
  
  # "Server allows POST to missing @resource?"
  v3n5: (req, res) =>
    @decisionTest(@resource.allowMissingPost, req, res, true, @v3n11, 410)

  stage1Ok: (req, res) =>
    if res.isRedirect()
      if res.headers['Location']
        @respond(req, res, 303)
      else
        @errorResponse('Response had doRedirect but no Location')
    else
      @d(req, res, @v3p11)


  # "Redirect?"
  v3n11: (req, res) =>
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
    @decisionTest(req.method, req, res, 'POST', @v3n11, @v3o16)

  # Conflict?
  v3o14: (req, res) =>
    @resource.isConflict req, res, (isConflict)=>
      if isConflict
        @respond(409)
      else
        result = acceptHelper()
        if typeof(res) == 'number'
          @respond(result)
        else
          @d(@v3p11)

  # "PUT?"
  v3o16: (req, res) =>
    @decisionTest(req.method, req, res, 'PUT', @v3o14, @v3o18)

  # Multiple representations?
  # (also where body generation for GET and HEAD is done)
  v3o18: (req, res) =>
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
        
            @resource.contentTypesProvidedSync req, res, (contentTypesProvided) =>

              contentTypes = _.pairs(contentTypesProvided)
              contentType = @metadata['Content-Type']
              matchingCt = _.find(contentTypes, (ct) => contentType == ct[0])
              
              # call the content type handler
              @resource[matchingCt[1]].apply @resource, [req, res, (result) =>
                if typeof(result) == 'number'
                  @respond(result)
                else
                  res.body = result
                  @encodeBody(req, res)
                  @d(@v3o18b)
              ]
    else
      @d(@v3o18b)

  v3o18b: (req, res) =>
    @decisionTest(@resource.multipleChoices, req, res, true, 300, 200)
  
  # Response includes an entity?
  v3o20: (req, res) =>
    @decisionTest(req.hasResponseBody(), req, res, true, @v3o18, 204)

  # Conflict?
  v3p3: (req, res) =>
    @resource.isConflict req, res, (isConflict)=>
      if isConflict
        @respond(409)
      else
        result = acceptHelper()
        if typeof(res) == 'number'
          @respond(result)
        else
          @d(@v3p11)

  # New @resource?  (at this point boils down to "has location header")
  v3p11: (req, res) =>
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
