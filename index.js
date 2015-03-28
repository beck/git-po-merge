'use strict'

var cp = require('child_process')
var fs = require('fs')
var path = require('path');

module.exports = function(ours, base, theirs, options) {
  options = options || {'silent': false};
  var args = [ours, base, theirs];
  options.silent && args.unshift('-s');
  var cpOpts = {stdio: [0, process.stdout, process.stderr]};
  cp.execFileSync(path.join(__dirname, 'merge.sh'), args, cpOpts);
};
