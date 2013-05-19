# Webmachine NodeJS [![travis](https://secure.travis-ci.org/coderoshi/webmachine-nodejs.png)](http://travis-ci.org/coderoshi/webmachine-nodejs)

This is a Webmachine toolkit for NodeJS, inspired by the original Erlang [Webmachine](https://github.com/basho/webmachine/wiki) and [Ruby port](https://github.com/seancribbs/webmachine-ruby). Thanks also to Nodemachine for some test scenarios.

## Usage

The easiest way to get started is to include `webmachine` npm project into `package.json`.

```json
{
  "name": "wmtest",
  "version": "0.0.1",
  "dependencies": {
    "webmachine" : "~>0.0.3"
  }
}
```

From there, create a webmachine resource. The same functions that can be overridden in other webmachine implementations can be done here, the only difference is that the function names are a JavaScripty camel case style, rather than underscore seperated.

Here is a simple app that adds a root (`"/"`) resource to the service running on port `3000`. You can add as many resources as you need. Routes can be an array, and also conform to Sinatra rules (eg. `/users/:uid`).

```javascript
var wm = require('webmachine');

var root = {
  route: "/",
  toHtml: function(req, res, next) {
    next("<html><h1>Hello World</h1></html>");
  }
};
wm.add(root);
wm.start(3000, '0.0.0.0');
```

If you run into issues, you can trace the output. It will present a list of steps taken to arrive at the given response.

```
wm.trace(true);
```

The output might not make a lot of sense without this chart, the steps are the decision points.

<a href="https://raw.github.com/wiki/basho/webmachine/images/http-headers-status-v3.png">
<img src='https://raw.github.com/wiki/basho/webmachine/images/http-headers-status-v3.png' width=550 align=center>
</a>
