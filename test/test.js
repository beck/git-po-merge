'use strict';
var assert = require('assert');
var path = require('path');
var fs = require('fs');

var pomerge = require('../index')

describe('merging', function() {

  var ourPo;
  before(function() {
    ourPo = fs.readFileSync(path.join(__dirname, 'fixture', 'ours.po'));
  });

  it('has a test', function() {
    //TODO: write some real tests
    var ours = path.join(__dirname, 'fixture', 'ours.po');
    var base = path.join(__dirname, 'fixture', 'base.po');
    var theirs = path.join(__dirname, 'fixture', 'theirs.po');
    pomerge(ours, base, theirs, {silent: true});
    assert.ok(true);
  });

});
