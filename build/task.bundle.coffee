###
  browserify task
   ---------------
   Bundle javascripty things with browserify!

   If the watch task is running, this uses watchify instead
   of browserify for faster bundling using caching.

###

browserify = require('browserify');
_ = require 'lodash'
bundleLogger = require('./util.bundlelogger');
errorLogger = require('./util.errorlogger');
gulp = require('gulp');
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
source = require('vinyl-source-stream');
buffer = require 'vinyl-buffer'

bundle = ->
  dest = './'

  bundler = browserify
  # Specify the entry point of your app
    entries   :['src/index.coffee']
    extensions:['.coffee']

  bundle = ->
    # Log when bundling starts
    bundleLogger.start();

    bundler
    .bundle()
    # Report compile errors
    .on 'error', errorLogger
    # Use vinyl-source-stream to make the
    # stream gulp compatible. Specifiy the
    # desired output filename here.
    .pipe source 'index.js'
    .pipe buffer()
    # Specify the output destination
    .pipe gulp.dest dest
    # Log when bundling completes!
    .on 'end', bundleLogger.end

  bundle()

bundle.description = "Build caramel bundle"

gulp.task "build", bundle