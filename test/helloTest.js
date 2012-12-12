var iced = require('iced-coffee-script');
var wm = require('../lib/webmachine');

root = {
  // route: "/:derp/z/:herp",
  route: "/:derp",
  // routeGuard: function(req){return true;},
  // routeArgs: [],
  service_available: function(req, res, next) {
    // console.log(req.path_info('derp'));
    // console.log(req.get_qs_value('das'));
    // console.log(req.stream_req_body());
    // req.req.on('data', function(c){
    //   console.log(""+c);
    //   next(false);
    // });
    req.req_body(function(body){
      // console.log(""+body);
      res.res.write('service_available')
      next(true);
    });
    // next();
    // next(false);
  }
  // , uri_too_long: function(req, res, next) {
  //   next(false);
  // }
  // , is_authorized: function(req, res, next) {
  //   next(true);
  // }
};

wm.add(root);
// webmachine.add({route: "/:derp/y"});
// webmachine.add({route: "/xxx"});
// webmachine.add({route: "/"});
wm.start(3000, '127.0.0.1');
