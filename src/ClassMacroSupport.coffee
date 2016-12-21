_ = require 'lodash'

###

  Add support for class local storage objects and arrays. Allows to maintain per class
  metadata. The configuration mechanism is accessible on class level.
  The configured metadata is available on the class prototype, i.e. instance level & class level.


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

  @postProcessor:(name, func)->
    @classScopedArray('__classPostProcessors').push {name,func}

  @applyPostProcessors:->
    clazz = @
    for postprocessor in @classScopedArray('__classPostProcessors')
      log.debug? "Applying postProcessor #{postprocessor.name} to class #{clazz::classname or clazz.name}}"
      result = postprocessor.func.apply clazz, null
      clazz = result
    log.debug? "Class processing result: #{obj.print clazz}"
    clazz


module.exports = ClassMacroSupport