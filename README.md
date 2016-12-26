# Latte: Advanced mixins for CoffeeScript

As CoffeeScript users we have been told many times that there is no support for mixins on the language level because it is so easy to implement them on top of native language concepts. Although I believe that native support for Mixins would be a lovely addition to CS, I also understand that it ain't gonna happen.

## Features

- Mixins are classes, no restrictions made
- Both prototype and class level properties take part in mixes
- Mixin consumers are classes that extend Mixin
- Mixins can extend Mixins
- Mixins can have constructors

```coffeescript

class AutoUUID
  constructor: -> @_id ?= randomId()

class Named extends Mixin
  constructor:(@name)->
  nickname: -> "nick#{@name}"
  @staticName:->"static#{@name}"

class NamedIdentifiable extends Mixin
  @with AutoUUID, Named
  
  constructor:-> super() # super call is required
  

instance = new NamedIdentifiable() 
expect(instance).to.have.property '_id'
expect(instance.nickname()).to.be 'nickundefined'


```



