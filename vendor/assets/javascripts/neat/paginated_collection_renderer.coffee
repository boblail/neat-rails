class window.Neat.PaginatedCollectionRenderer

  constructor: (@view, @collection, @options) ->

    @paginator = new window.Lail.PaginatedList [],
      page_size: if window.Neat.forPrint then Infinity else @options.pageSize
      always_show: false
    @paginator.onPageChange _.bind(@renderPage, @)

    @collection.bind 'reset',   @__reset, @
    @collection.bind 'add',     @__added, @
    @collection.bind 'remove',  @__removed, @
    @collection.bind 'sort',    @__sorted, @

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
      @delayedRerender.trigger() if @view.sortedBy

    @views = []



  renderTo: (@$ul) ->
    @paginator.renderPaginationIn(@view.$el.find('.pagination'))
    @repaginate()

  repaginate: ->
    @rerenderPage(1)

  rerenderPage: (page)->
    page = @paginator.getCurrentPage() unless _.isNumber(page)
    if @view.sortedBy
      sortField = @view.sortField(@view.sortedBy)
      items = @collection.sortBy (model)->
        val = model.get(sortField) || ''
        if _.isString(val) then val.toLowerCase() else val
      items.reverse() if @view.sortOrder == 'desc'
    else
      items = @collection.toArray()
    @paginator.init items, page

  renderPage: ->
    alt = false
    @$ul.empty() # we're replacing the visible page
    @views = []

    @view.$el.find('.extended-pagination').html(@paginator.renderExtendedPagination())

    for model in @paginator.getCurrentSet()
      $el = @appendViewFor(model)
      $el.toggleClass 'alt', !(alt = !alt) if @view.alternateRows
    @

  appendViewFor: (model) ->
    view = @view.buildViewFor(model)
    @views.push(view)

    $el = $(view.render().el)
    @$ul.append $el
    $el



  findViewForModel: (model)->
    _.find @views, (view)-> view.model.cid is model.cid



  __reset: ->
    @render()

  __added: ->
    @rerenderPage()

  __removed: ->
    @rerenderPage()

  __sorted: ->
    @repaginate()
