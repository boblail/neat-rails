class window.Neat.BasicCollectionRenderer

  constructor: (@view, @collection, @options) ->
    @collection.bind 'reset',   @_collectionHasBeenReset, @
    @collection.bind 'sort',    @_collectionHasBeenSorted, @
    @collection.bind 'add',     @_modelHasBeenAddedToCollection, @
    @collection.bind 'remove',  @_modelHasBeenRemovedFromCollection, @
    @views = []

  renderTo: (@$ul) ->
    @_render()

  findViewForModel: (model)->
    _.find @views, (view)-> view.model.cid is model.cid



  _render: ->
    # Doesn't need to render anything else like pagination controls on the view
    # Just needs the @$ul that it should render views to
    @_renderVisibleModels()

  _renderVisibleModels: ->
    @$ul.empty()
    @views = []

    for model in @_visibleModels()
      @_appendViewFor(model)
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
