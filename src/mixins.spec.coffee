require("must/register")
expect = require 'must'

{Mixin, mixins} = require './index.coffee'


randomId = (length=8) ->
  # Taken from: https://coffeescript-cookbook.github.io/chapters/strings/generating-a-unique-id
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

describe 'Mixin', ->

  describe 'composition', ->

    class UUIDentifiable
      id: -> @_id ?= randomId()

    class AutoUUID
      uuid: -> @_id ?= randomId()

    class Named extends Mixin
      constructor:(@name)->
      nickname: -> "nick#{@name}"
      @staticName:->"static#{@name}"

    class TestClass extends Mixin
      @with UUIDentifiable
      @with AutoUUID
      @with Named

      constructor: (name) ->
        super name

      @staticMethod:->"static#{@name}"
      uuid:->super() # override leaves imported method accessible via super

    class TestSubClass extends TestClass


      @staticName:->"Overwritten#{@name}"
      nickname: -> "Overwritten#{super()}"


    describe 'method and property inclusion', ->

      it 'works for instance (prototype) and static (class) properties', ->
        testclass = new TestClass()
        expect(testclass.id().length).to.equal 8
        expect(testclass.id()).to.be testclass.id() # repeatably return the same value
        expect(testclass._id).to.be testclass.id() # from the underlying variable
        expect(testclass.uuid()).to.be testclass.id() # and used by the two different methods
        expect(testclass.name).to.be.undefined()
        expect(testclass.nickname()).to.be "nickundefined"
        testclass.name = "testclass"
        expect(testclass.nickname()).to.be "nicktestclass"
        expect(TestClass.staticName()).to.be "staticTestClass"

      it 'preserves semantics of per instance variables (no accidently shared state between instances)', ->
        testclass = new TestClass()
        testclass2 = new TestClass("testclass2")
        expect(testclass.id()).not.to.be testclass2.id()
        expect(testclass.uuid).to.be testclass2.uuid # methods are the same
        expect(testclass.uuid()).not.to.be testclass2.uuid() # values produced are not (both instances have own copy of variables)
        expect(testclass2.name).to.be "testclass2"
        expect(testclass2.nickname()).to.be "nicktestclass2"
        testclass2.name = "renamed"
        expect(testclass2.nickname()).to.be "nickrenamed"
        expect(TestClass.staticName()).to.be "staticTestClass"

      it 'supports method overriding for instance and static methods', ->
        testclass = new TestSubClass "testsub"
        expect(testclass.id().length).to.equal 8
        expect(testclass.id()).to.be testclass.id() # repeatably return the same value
        expect(testclass.name).to.be "testsub"
        expect(testclass.nickname()).to.be "Overwrittennicktestsub"
        expect(TestSubClass.staticName()).to.be "OverwrittenTestSubClass"


    it 'allows to compose of composed mixins',->
      class AutoId
        constructor:-> @_id= randomId()

      class MixinOne extends Mixin
        @with AutoId

        render:->"rendered:MixinOne"

      class MixinTwo extends Mixin
        @with AutoId
        @with Named

        render:-> "rendered:MixinTwo"+super()

      class CompositeMixins extends Mixin
        @with MixinOne, MixinTwo

        constructor:(properties) -> super properties

      class CompositeMixinSubclass extends CompositeMixins

        constructor: (properties) -> super properties

      class MixedSuperclass extends mixins AutoId, MixinOne, MixinTwo

      composite = new CompositeMixins 'named-composite-module'
      expect(composite.name).to.be 'named-composite-module'
      compisiteSub = new CompositeMixinSubclass 'composite-subclass'
      expect(compisiteSub.name).to.be 'composite-subclass'
      mixedSuper = new MixedSuperclass 'mixed-super'
      expect(mixedSuper.name).to.be 'mixed-super'


    it 'supports type validation:throws an error if required type is not found', ->
      validationError = null
      try
        class Love

        class Child extends Mixin
          @expects Love

        class Parent extends Mixin
          #@with Love #People need love but this test will fail if love is given to child
          @with Child
      catch err
      # Construction of Parent fails with error
        validationError = err
      expect(validationError).not.to.be.null()
      expect(validationError.toString().indexOf "requires Love").not.to.be -1


  describe 'super bindings', ->

    class Named
      constructor:(@name)->
      fullname:->@name

    class Person extends Named

      fullname:-> "Person #{super()}"

    class PersonAndPosition extends Mixin
      @with Person
      constructor: (name, @position) -> super name
      fullname: -> "#{super()} in position of #{@position}"

    describe 'of subclass mixed into Mixin bind to their former super class', ->

      it 'when using @with', ->
        Captain = new PersonAndPosition 'Fitz Roy', 'Captain'
        expect(Captain.fullname()).to.be 'Person Fitz Roy in position of Captain'

      it 'when using extends mixins', ->
        class PersonAndPositionMixedSuper extends mixins Person
          constructor: (name, @position) -> super name
          fullname: -> "#{super()} in position of #{@position}"

        Captain = new PersonAndPositionMixedSuper 'Fitz Roy', 'Captain'
        expect(Captain.fullname()).to.be 'Person Fitz Roy in position of Captain'

      it 'when using coffeescript class extensions', ->
        class PersonAndPositionExtendsSuper extends PersonAndPosition
          fullname:->super()
        Captain = new PersonAndPositionExtendsSuper 'Fitz Roy', 'Captain'
        expect(Captain.fullname()).to.be 'Person Fitz Roy in position of Captain'

  describe 'constructor hierarchies', ->

    trackedConstructorCalls = 0
    calledConstructors = []

    class TrackedConstructor

      constructor: ->
        trackedConstructorCalls++
        calledConstructors.push 'TrackedConstructor'

    class TrackedOne extends TrackedConstructor

      constructor: ->
        super()
        calledConstructors.push 'TrackedOne'

    class TrackedTwo extends TrackedConstructor

      constructor: ->
        super()
        calledConstructors.push 'TrackedTwo'

    class Third extends Mixin
      constructor:->calledConstructors.push 'Third'

    class TestClass extends Mixin
      @with TrackedOne
      @with TrackedTwo
      @with Third

      constructor: (name) ->
        super name
        calledConstructors.push 'TestClass'


    it 'are called in order of mixin inclusion (isomorphism between definition and execution)', ->
      trackedConstructorCalls = 0
      calledConstructors = []
      testClass = new TestClass()
      expect(trackedConstructorCalls).to.be 2 # TrackedOne and TrackedTwo
      expect(calledConstructors).to.eql ['TrackedConstructor', 'TrackedOne', 'TrackedConstructor', 'TrackedTwo', 'Third', 'TestClass']




