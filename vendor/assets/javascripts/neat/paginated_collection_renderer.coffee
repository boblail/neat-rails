class window.Neat.PaginatedCollectionRenderer extends window.Neat.BasicCollectionRenderer

  constructor: (@view, @collection, @options) ->
    super
    @paginator = new window.Lail.PaginatedList [],
      page_size: if window.Neat.forPrint then Infinity else @options.pageSize
      always_show: false
    @paginator.onPageChange _.bind(@_renderPage, @)



  _render: ->
    @paginator.renderPaginationIn(@view.$el.find('.pagination'))
    @_repaginate()

  _repaginate: ->
    @_rerenderPage(1)

  _rerenderPage: (page)->
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

  _renderPage: ->
    @view.$el.find('.extended-pagination').html(@paginator.renderExtendedPagination())
    @_renderVisibleModels()

  _visibleModels: ->
    @paginator.getCurrentSet()

  _collectionHasBeenSorted: ->
    @_repaginate()

  _modelHasBeenAddedToCollection: ->
    @_rerenderPage()

  _modelHasBeenRemovedFromCollection: ->
    @_rerenderPage()

  _modelHasBeenChanged: ->
    @_rerenderPage()
