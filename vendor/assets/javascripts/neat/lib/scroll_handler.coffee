class @Neat.ScrollHandler
  _.extend @prototype, Backbone.Events

  constructor: (options={})->
    @$viewPort = $(options.viewPort ? window)
    @$document = $(document)
    @$viewPort.scroll _.bind(@_windowWasScrolled, @)

  _viewportHeight: ->
    @$viewPort.height()

  _documentHeight: ->
    if $.isWindow @$viewPort[0]
      @$document.height()
    else
      @$viewPort[0].scrollHeight

  _windowWasScrolled: ->
    viewportHeight = @_viewportHeight()
    documentHeight = @_documentHeight()

    scrollTop = @$viewPort.scrollTop()
    scrollMax = documentHeight - viewportHeight
    progress = scrollTop / scrollMax
    distanceFromBottom = scrollTop - scrollMax

    return if scrollMax <= 0

    @trigger "scroll",
      scrollTop: scrollTop
      scrollMax: scrollMax
      progress: progress
      distanceFromBottom: distanceFromBottom
