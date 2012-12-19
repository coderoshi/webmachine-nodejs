_        = require('underscore')
http     = require('http')
url      = require('url')
util     = require('./util')
Fsm      = require('./fsm')
ResData  = require('./responseData')
ReqData  = require('./requestData')
Resource = require('./resource')

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
      if match = @match(urlForm)

        [resource, pathInfo] = match
        rd = new ReqData(req, urlForm, pathInfo)
        rs = new ResData(res)

        # TODO: cache this
        resource = new Resource(resource)

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
