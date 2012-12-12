class Resource
  constructor: (config)->
    @route = config.route
    @config = config
    @known_methods = ['GET']


  # service_available: function(req, res, next) ->
  #   next(200) unless @config?service_available

  # finish_request: function(req, res, next) ->
  #   next(false) unless @config?service_available
