KEYS = {
  13: "RETURN",
  27: "ESC",
  38: "UP",
  40: "DOWN"
}

# Classes that inherit from EditableCollectionView
# must define one property:
#   resource
#
# Can optionally define
#   modelView - by default this is set to {Resource}View
#   template - by default this is set to #{resource}/index
#   viewPath - by default this is set to resource
#
class window.Neat.CollectionEditor extends Backbone.View
  templateOptions: {}
  useKeyboardToChangeRows: true
  cancelOnEsc: true
  saveOnEnter: true
  renderer: "Basic"
  rendererOptions: {}

  initialize: ->
    @keyDownHandlers = {}

    @viewPath = @viewPath ? @resource
    @singular = inflect.singularize(@resource) # e.g. "calendar"
    @modelView = @modelView ? (()=>
      viewName = inflect.camelize(@singular) + "View" # e.g. "CalendarView"
      @debug "expects viewName to be #{viewName}"
      window[viewName])() # e.g. window["CalendarView"]

    @debug "looking for template at #{"#{@viewPath}/index"}"
    @template = @template ? Neat.template["#{@viewPath}/index"]

    # For backwards-compatibility
    @rendererOptions.pageSize = @pageSize if @pageSize?

    rendererKlass = @renderer
    rendererKlass = Neat.Renderer[rendererKlass] if _.isString(rendererKlass)
    @_renderer = new rendererKlass(@, @collection, @rendererOptions)

    @_renderer.afterRender _.bind(@afterRender, @)

    $(@el).delegate '.editor', 'keydown', _.bind(@onKeyDown, @)

    if @cancelOnEsc
      @keyDownHandlers['ESC']    = -> @viewInEdit?.cancelEdit()

    if @saveOnEnter
      @keyDownHandlers['RETURN'] = -> @viewInEdit?.save()

    if @useKeyboardToChangeRows
      @keyDownHandlers['UP']     = -> @edit @prevView()
      @keyDownHandlers['DOWN']   = -> @edit @nextView()

    @viewInEdit = null
    @templateOptions = {}




  render: ->
    $el = $(@el)
    $el.html @template(@context())
    $el.cssHover '.neat-row.neat-interactive'
    @$ul = $(@el).find("##{@resource}")

    @_renderer.renderTo @$ul
    @

  context: ->
    collection: @collection

  afterRender: ->
    @

  buildViewFor: (model) ->
    self = @
    view = @constructModelView
      resource: @resource
      viewPath: @viewPath
      model: model
      templateOptions: @templateOptions
    view.bind 'edit:begin', -> self.beforeEdit.call(self, @)
    view.bind 'edit:end', -> self.afterEdit.call(self, @)
    view

  constructModelView: (options) ->
    viewClass = @modelView
    viewClass = viewClass(options.model) if _.isFunction(viewClass) and !(viewClass.prototype instanceof Neat.ModelEditor)
    new viewClass(options)


  beforeEdit: (view)->
    if @viewInEdit and @viewInEdit isnt view
      @debug "cancelling edit for ##{$(@viewInEdit.el).attr('id')} (#{@indexOfViewInEdit()})"
      @viewInEdit.cancelEdit()
    @viewInEdit = view
    @debug "beginning edit for ##{$(@viewInEdit.el).attr('id')} (#{@indexOfViewInEdit()})"

  afterEdit: (view)->
    @viewInEdit = null if @viewInEdit == view



  onKeyDown: (e)->
    keyName = @identifyKey(e.keyCode)
    handler = @keyDownHandlers[keyName]
    if handler && !@ignoreKeyEventsForTarget(e.target)
      e.preventDefault()
      handler.apply(@)

  identifyKey: (code)->
    KEYS[code]

  ignoreKeyEventsForTarget: (target)->
    # i.e. return true if target is in a dropdown control like Chosen
    false



  nextView: ->
    @_renderer.views[@indexOfViewInEdit() + 1]

  prevView: ->
    @_renderer.views[@indexOfViewInEdit() - 1]

  indexOfViewInEdit: ->
    _.indexOf @_renderer.views, @viewInEdit

  edit: (view)->
    if view instanceof Backbone.Model
      view = @_renderer.findViewForModel(view)
    if view
      @viewInEdit?.save()
      view.edit()
      @viewInEdit = view

  cancelEdit: ->
    @viewInEdit?.cancelEdit()


  debug: (o...)->
    @log(o...) if Neat.debug

  log: (o...)->
    Neat.logger.log "[#{@viewPath}] ", o...
