'use strict';
var assert = require('assert');
var path = require('path');
var fs = require('fs');

var pomerge = require('../index');

function isDir(p) {
  return fs.statSync(path.join(__dirname, p)).isDirectory();
}

function getTestDirs() {
  return fs.readdirSync(__dirname).filter(isDir);
}

describe('git-po-merge', function() {

  var restore = [];
  var save = function(files) {
    var safeFile = function(f) {
      restore.push({path:f, content: fs.readFileSync(f).toString()});
    };
    files.map(safeFile);
  };
  afterEach(function() {
    var restoreFile = function (f) {
      fs.writeFileSync(f.path, f.content);
    };
    restore.map(restoreFile);
  });

  getTestDirs().map(function(dir) {

    it(dir, function() {
      var ours = path.join(__dirname, dir, 'ours.po');
      var base = path.join(__dirname, dir, 'base.po');
      var theirs = path.join(__dirname, dir, 'theirs.po');
      var expected = path.join(__dirname, dir, 'expected.po');

      save([ours, base, theirs]);

      var shouldFail = dir.indexOf('fail') > 0;
      var failed = false;
      try {
        pomerge(ours, base, theirs, {silent: true});
      } catch(e) {
        failed = true;
      }
      var merged = fs.readFileSync(ours).toString();
      expected = fs.readFileSync(expected).toString();

      assert.equal(shouldFail, failed);
      assert.equal(merged, expected);

    });

  });

});
