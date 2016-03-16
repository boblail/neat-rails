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
  sortOrder: 'asc'
  sortAliases: {}
  templateOptions: {}
  useKeyboardToChangeRows: true
  cancelOnEsc: true
  saveOnEnter: true
  alternateRows: true
  renderer: Neat.PaginatedCollectionRenderer
  rendererOptions:
    pageSize: 30

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
    @_renderer = new @renderer(@, @collection, @rendererOptions)

    # If the view's headers are 'a' tags, this view will try
    # to sort the collection using the header tags.
    $(@el).delegate '.header a', 'click', _.bind(@sort, @)
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

    @afterRender()

    @updateSortStyle() if @sortedBy

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



  sort: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    sortBy = $(e.target).closest('a').attr('class').substring(@singular.length + 1)
    @log "sort by #{sortBy} [#{@sortField(sortBy)}]"
    if @sortedBy == sortBy
      @sortOrder = if @sortOrder == 'asc' then 'desc' else 'asc'
    else
      @removeSortStyle @sortedBy
      @sortedBy = sortBy
    @collection.trigger "sort"
    @updateSortStyle()
    false

  removeSortStyle: (field)->

  updateSortStyle: ()->
    @removeSortStyle @sortedBy

  getHeader: (field)->
    $(@el).find(".header > .#{@singular}-#{field}")

  sortField: (field)->
    @sortAliases[field] ? field



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
