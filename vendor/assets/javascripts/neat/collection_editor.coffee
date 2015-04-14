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
  sortedBy: 'name'
  sortOrder: 'asc'
  sortAliases: {}
  templateOptions: {}
  pageSize: 30
  useKeyboardToChangeRows: true
  cancelOnEsc: true
  saveOnEnter: true
  keyDownHandlers: {}
  
  initialize: ->
    @viewPath = @viewPath ? @resource
    @singular = inflect.singularize(@resource) # e.g. "calendar"
    @modelView = @modelView ? (()=>
      viewName = inflect.camelize(@singular) + "View" # e.g. "CalendarView"
      @debug "expects viewName to be #{viewName}"
      window[viewName])() # e.g. window["CalendarView"]
    
    @debug "looking for template at #{"#{@viewPath}/index"}"
    @template = @template ? Neat.template["#{@viewPath}/index"]
    
    @paginator = new window.Lail.PaginatedList [],
      page_size: if window.Neat.forPrint then Infinity else @pageSize
      always_show: false
    @paginator.onPageChange _.bind(@renderPage, @)
    
    @collection.bind 'reset',   @__reset, @
    @collection.bind 'add',     @__add, @
    @collection.bind 'remove',  @__remove, @
    
    # We need to rerender the page if a model's attributes
    # have changed just in case this would affect how the
    # models are sorted.
    #
    # !todo: perhaps we can be smarter here and only listen
    # for changes to the attribute the view is sorted on.
    #
    # We don't want to redraw the page every time a model
    # has changed. If an old transaction is deleted, a very
    # large number of more recent transactions' running
    # balances could be updated very rapidly. Redrawing the
    # page will slow things down dramatically.
    #
    # Instead, redraw the page 500ms after a model has changed.
    #
    # This allows us to wait for activity to die down
    # and to redraw the page when it's more likely the system
    # has settled into new state.
    #
    @delayedRerender = new Lail.DelayedAction(_.bind(@rerenderPage, @), delay: 500)
    @collection.bind 'change', =>
      @delayedRerender.trigger() if @sortedBy
    
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
    
    @views = []
    @viewInEdit = null
    @templateOptions = {}
  
  repaginate: ->
    @rerenderPage(1)
  
  rerenderPage: (page)->
    page = @paginator.getCurrentPage() unless _.isNumber(page)
    sortField = @sortField(@sortedBy)
    items = @collection.sortBy (model)->
      val = model.get(sortField) || ''
      if _.isString(val) then val.toLowerCase() else val
    items.reverse() if @sortOrder == 'desc'
    @paginator.init items, page
  
  
  render: ->
    $el = $(@el)
    $el.html @template(@context())
    $el.cssHover '.neat-row.neat-interactive'
    
    @afterRender()
    
    @updateSortStyle() if @sortedBy
    
    @paginator.renderPaginationIn($el.find('.pagination'))
    @repaginate()
    @
  
  context: ->
    collection: @collection
  
  afterRender: ->
    @
  
  renderPage: ->
    alt = false
    $ul = $(@el).find("##{@resource}").empty() # e.g. $('#calendars')
    @views = []
    self = @
    
    $(@el).find('.extended-pagination').html(@paginator.renderExtendedPagination())
    
    for model in @paginator.getCurrentSet()
      view = new @modelView # e.g. window.CalendarView
        resource: @resource
        viewPath: @viewPath
        model: model
        templateOptions: @templateOptions
      view.bind 'edit:begin', -> self.beforeEdit.call(self, @)
      view.bind 'edit:end', -> self.afterEdit.call(self, @)
      
      @views.push(view)
      
      $el = $(view.render().el)
      $el.toggleClass 'alt', !(alt = !alt)
      $ul.append $el
    @
  
  
  
  beforeEdit: (view)->
    if @viewInEdit
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
    @repaginate()
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
    @views[@indexOfViewInEdit() + 1]
  
  prevView: ->
    @views[@indexOfViewInEdit() - 1]
  
  indexOfViewInEdit: ->
    _.indexOf @views, @viewInEdit
  
  edit: (view)->
    if view
      @viewInEdit?.save()
      view.edit()
      @viewInEdit = view
  
  cancelEdit: ->
    @viewInEdit?.cancelEdit()
  
  
  
  __reset: ->
    @render()
  
  __add: ->
    @rerenderPage()
  
  __remove: ->
    @rerenderPage()
  
  
  
  debug: (o...)->
    @log(o...) if Neat.debug
  
  log: (o...)->
    Neat.logger.log "[#{@viewPath}] ", o...
