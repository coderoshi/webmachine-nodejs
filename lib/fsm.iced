_    = require('underscore')
Flow = require('./flow')

# FSM/Flow seperation inspired by Ruby implementation
class FSM

  constructor: (resource, request, response)->
    @resource = resource
    @request = request
    @response = response
    @metadata = {}

  run: ()->
    state = 'v3b13'
    flow = new Flow(@resource)
    flow[state].call(flow, @request, @response)

module.exports = FSM
