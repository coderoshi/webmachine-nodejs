
class Resource
  constructor: (config)->
    @route = config.route
    @config = config
    @knownMethods = ['GET']


  # serviceAvailable: function(req, res, next) ->
  #   next(200) unless @config?serviceAvailable

  # finishRequest: function(req, res, next) ->
  #   next(false) unless @config?serviceAvailable
