'use strict'

var cp = require('child_process')
var fs = require('fs')
var path = require('path');

module.exports = function(ours, base, theirs) {
  var args = [ours, base, theirs];
  var opts = {stdio: [0, process.stdout, process.stderr]};
  cp.execFileSync(path.join(__dirname, 'merge.sh'), args, opts);
};
