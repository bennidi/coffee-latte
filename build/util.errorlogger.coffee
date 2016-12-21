###
  Send error to notification center with gulp-notify
###

notify = require("gulp-notify");
utils = require 'util'

module.exports = ->

  args = Array.prototype.slice.call(arguments);
  console.log utils.inspect arguments
  notify.onError({
    title: "Compile Error",
    message: "<%= error.message %>"
  }).apply(this, args);

  # Keep gulp from hanging on this task
  this.emit 'end'
