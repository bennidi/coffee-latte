_ = require 'lodash'

###

  Allows to maintain per class metadata using class local objects and arrays.
  The configured metadata is available on the class prototype and class level.


  @see http://www.lucaongaro.eu/blog/2013/03/03/non-primitive-properties-coffeescript-inheritance-and-class-macros/
  @see AnnotationSupport
###
class ClassMacroSupport

  # Define an array to contain internal information about mixin class
  # @nodoc
  @classScopedArray:(name) ->
    @::[name] ?= []
    @::[name] = @::[name][..] unless @::hasOwnProperty name
    @::[name]

  # Define an object to contain internal information about mixin class
  # @nodoc
  @classScopedObject:(name) ->
    @::[name] ?= {}
    @::[name] = _.extend {}, @::[name] unless @::hasOwnProperty name
    @::[name]


module.exports = ClassMacroSupport
