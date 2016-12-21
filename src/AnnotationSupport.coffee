ClassMacroSupport = require './ClassMacroSupport.coffee'

class AnnotationSupport extends ClassMacroSupport

  @annotate:(annotation) ->
    annotations = @classScopedObject '__annotations'
    annotations[annotation.name] = annotation

  @annotation:(name) ->
    annotations = @classScopedObject '__annotations'
    annotations[name]

# @todo Maybe the nested meta object is unnecessary
class Annotation

  constructor:(@name='unnamed', @meta={})->

  properties:->@meta

module.exports = {
  AnnotationSupport
  Annotation
}