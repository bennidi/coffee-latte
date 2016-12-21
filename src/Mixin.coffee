_ = require 'lodash'
{AnnotationSupport} = require './AnnotationSupport.coffee'

###
  Add mixin functionality to a class. Every class that extends Mixin can use
  its include() method to specify other classes to be used as Mixins.
  This pattern supports a feature similar to multiple-inheritance.

  @example Define class with two Mixins

    class MixinOne
      # ... define instance and class methods/properties

    class MixinTwo extends Mixin
      @expects MixinOne # Requires MixinOne to be present when included

      # ... define instance and class methods/properties

    class Composite extends Mixin
      @with MixinOne, MixinTwo

    # ... use instance and class methods/properties of either mixin


  @see https://arcturo.github.io/library/coffeescript/03_classes.html
###
class Mixin extends AnnotationSupport

  moduleKeywords = [
    'with' # The primary method used to compose mixins
    '__mixinConstraints' # The constraints are evaluated when the mixin is included and do not need to be present in the final class
    '__super__' # Don't mess with coffeescripts class extension mechanism
    'classScopedArray' # Utility method for composition of mixins
    '__mixinConstructors' # Explicitly created and filled during mixin composition. Will be present in final class
    'annotate'
    'annotation'
    #'__annotations'
    'expects' # The method to define mixin constraints
    'constructor' # The constructor property (we do not override constructors)
  ]

  # Unused code: Idea was to only create intermediate superclasses when method conflicts exist
  overriddenMethods = (mixin, target) ->
    staticMethods =  _.intersection (key for key,value of mixin), (key for key,value of target)
    prototypeMethods = _.intersection (key for key,value of mixin.prototype), (key for key,value of target.prototype)
    conflicts = _.union staticMethods, prototypeMethods
    _.pullAll conflicts, moduleKeywords
    conflicts

  # The mixin constructor takes care of calling all included constructors (the constructors of all included mixins)
  # exactly once. The current implementation achieves isomorphism between Mixin declaration and constructor call hierarchies.
  constructor : (args...)->
    # Remember applied constructors to avoid multiple calls to the same constructor
    @_appliedConstructors ?= {}
    # If any mixins have been included, then this array exists
    if @['__mixinConstructors']
      for constructor in @['__mixinConstructors']
        if @_appliedConstructors[constructor.name] then continue
        else
          @_appliedConstructors[constructor.name] = true
          constructor.apply this, args

  # Define a constraints regarding expected available types (other mixins)
  @expects: (constraints...) ->
    for constraint in constraints
      _constraints = @classScopedArray '__mixinConstraints'
      # Functions are assumed to be constructor functions, aka class types
      switch
        when _.isFunction constraint then _constraints.push new TypeConstraint constraint.name
      # Type names can be passed as strings (whenever the type is not available)
        when constraint.constructor is String then _constraints.push new TypeConstraint constraint
        else _constraints.push constraint

  # Add @mixins... to this class. This will include all instance and static properties of the mixins into the calling
  # class. Included mixins override existing properties with their own. The calling class overrides the properties included
  # by mixins. Overridden methods are available using super.
  @with: (mixins...) ->
    for mixin in mixins
      # Sanity checks
      if not mixin then throw "Supplied mixin for class #{@name} was not found"
      if not _.isFunction mixin then throw "Supplied mixin for class #{@name} is invalid"
      # Make sure that super constructor is called such that all mixins are initialized
      superCall = "#{@name}.__super__.constructor."
      if @prototype.constructor.toString().indexOf(superCall) is -1
        throw "Missing call to super constructor in class #{@name}"

      mixinPrototype = mixin.prototype
      # Safe mixin constructor such that it will be called by the constructor of the current class
      classLocalConstructors = @classScopedArray('__mixinConstructors')
      classLocalConstructors.push mixinPrototype.constructor
      # If mixin extends Mixin
      if mixin::['__mixinConstructors']
        classLocalConstructors.push constr for constr in mixin::['__mixinConstructors']

      # Check mixin constraints potentially defined by included mixin
      # Can be done only after constructor has been added
      if mixin::['__mixinConstraints']
        for constraint in mixin::['__mixinConstraints']
          constraint.validate mixin, @

      # Make intermediate super class such that the class hierarchy reflects the included mixins
      # This allows access to overridden methods of mixin chain
      iSuper = _.extend {}, @__super__
      iSuper.constructor = @__super__.constructor
      @__super__ = iSuper

      # Copy static methods
      staticMethods = []
      for key, value of mixin when key not in moduleKeywords
        @[key] = value
        staticMethods.push key

      prototypeMethods = []
      # Copy instance methods to prototype and the new intermediate superclass.
      for methodName, funct of mixinPrototype when methodName not in moduleKeywords
        # Safe the imported methods from being lost when overwritten in subclass
        # => allows call to super within overriding method of class
        @__super__[methodName] = funct
        @prototype[methodName] = funct
        prototypeMethods.push methodName
    this


  # Type check for expected mixin
  # @nodoc
  class TypeConstraint

    constructor:(@name)->

    # check whether @target satisfies the type constraints of @mixin
    validate:(mixin,target) ->
      for constructor in target::['__mixinConstructors']
        if constructor.name is @name then return
      throw new Error "#{mixin.name} requires #{@name} but wasn't found in #{target.name}"

_mixins = (mixins...) ->
  class extends Mixin
    @with mixins...

module.exports =
  Mixin:Mixin
  mixins:_mixins
