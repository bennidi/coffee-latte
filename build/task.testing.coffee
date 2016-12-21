gulp = require('gulp');

mocha = require 'gulp-mocha'
util = require 'gulp-util'
#cache = require 'gulp-memory-cache'


# This task will run all tests (*.spec.(coffee|es6))
e2eRun = ->
  gulp.src ['./src/**/*.spec.coffee']#, since: cache.lastMtime 'code'
  #.pipe cache 'code'
  .pipe mocha reporter:'spec'
  .on 'error', util.log
e2eRun.description = "Run e2e tests"
gulp.task 'test', e2eRun