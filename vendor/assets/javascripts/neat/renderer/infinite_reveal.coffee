class window.Neat.Renderer.InfiniteReveal extends window.Neat.Renderer.Basic

  constructor: (@view, @collection, @options) ->
    super
    @scrollHandler = new Neat.ScrollHandler(@options)
    @scrollHandler.on "scroll", _.bind(@_windowHasBeenScrolled, @)

    @sensitivity = @options.sensitivity ? 5
    @pageSize = @options.pageSize ? 50



  _render: ->
    @_setMaxItems @pageSize
    super

  _visibleModels: ->
    @collection.models[0...@maxItems]

  _loadMore: ->
    Neat.logger.log "[Neat.Renderer.InfiniteReveal] loading..."
    @_setMaxItems @maxItems + @pageSize
    @_renderVisibleModels()
    @_thereIsMore()

  _thereIsMore: ->
    @collection.length > @maxItems



  _setMaxItems: (value) ->
    @maxItems = Math.min value, @collection.length

  _windowHasBeenScrolled: (e) ->
    return unless @_thereIsMore()
    return unless Math.abs(e.distanceFromBottom) <= @sensitivity
    return unless @view.$el.is(':visible')
    @_loadMore()
