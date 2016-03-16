class window.Neat.BasicCollectionRenderer

  constructor: (@view, @collection, @options) ->
    @collection.bind 'reset',   @_collectionHasBeenReset, @
    @collection.bind 'sort',    @_collectionHasBeenSorted, @
    @collection.bind 'add',     @_modelHasBeenAddedToCollection, @
    @collection.bind 'remove',  @_modelHasBeenRemovedFromCollection, @
    @views = []

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
    @delayedRerender = new Lail.DelayedAction(_.bind(@_modelHasBeenChanged, @), delay: 500)
    @collection.bind 'change', =>
      @delayedRerender.trigger() if @view.sortedBy

  renderTo: (@$ul) ->
    @_render()

  findViewForModel: (model)->
    _.find @views, (view)-> view.model.cid is model.cid



  _render: ->
    # Doesn't need to render anything else like pagination controls on the view
    # Just needs the @$ul that it should render views to
    @_renderVisibleModels()

  _renderVisibleModels: ->
    alt = false
    @$ul.empty()
    @views = []

    for model in @_visibleModels()
      $el = @_appendViewFor(model)
      $el.toggleClass 'alt', !(alt = !alt) if @view.alternateRows
    @

  _visibleModels: ->
    @collection.toArray()

  _appendViewFor: (model) ->
    view = @view.buildViewFor(model)
    @views.push(view)

    $el = $(view.render().el)
    @$ul.append $el
    $el

  _collectionHasBeenReset: ->
    @render()

  _collectionHasBeenSorted: ->
    @render()

  _modelHasBeenAddedToCollection: ->
    @render()

  _modelHasBeenRemovedFromCollection: ->
    @render()

  _modelHasBeenChanged: ->
    @render()
