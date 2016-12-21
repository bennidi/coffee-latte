# The master build file aggregates all separate build files


# Require all tasks in gulp/tasks, including subfolders
require './build/task.testing'
require './build/task.bundle'

# Dependencies for main build

chalk = require 'chalk'
gulp = require 'gulp'

buildIntro = """

#################################################
      Welcome to carameld build system
#################################################

Run: #{ chalk.magenta 'gulp --tasks'} for a list of available build tasks
"""

showHelp = ->
	console.log buildIntro
showHelp.description = 'Show help'

gulp.task 'default', showHelp


