class window.Neat.ModelEditor extends Backbone.View
  tagName: 'li'
  className: 'neat-row neat-interactive neat-editable'
  
  initialize: (options)->
    options = options ? {}
    @templateOptions = options.templateOptions ? {}
    @viewPath = @viewPath ? options.viewPath
    @resource = @resource ? window.inflect.singularize(options.resource)
    $(@el).addClass(@resource)
    
    # Renders the 'show' template normally,
    # renders 'edit' when in edit mode.
    @showTemplate = Neat.template["#{@viewPath}/show"]
    @editTemplate = Neat.template["#{@viewPath}/edit"]
    
    # Wire up events.
    # Don't use Backbone's events hash because if subclasses
    # use that more familiar syntax, they'll blow away events
    # defined in this class.
    $(@el).delegate('.save-button',   'click', _.bind(@save, @))
    $(@el).delegate('.delete-button', 'click', _.bind(@delete, @))
    $(@el).delegate('.cancel-button', 'click', _.bind(@cancelEdit, @))
    
    # Begin editing when this resource is clicked
    # unless the user clicked a link or button.
    $(@el).click (e)=>
      @edit() if @canEdit() and !$(e.target).isIn('input, button, a, label')
  
  render: ->
    json = _.extend(@model.toJSON(), {options: @templateOptions})
    $(@el).html @template()(json)
    $(@el).attr('id', "#{@resource}_#{@model.get('id')}") # e.g. "calendar_5"
    @
  
  inEdit: -> $(@el).hasClass('editor')
  canEdit: -> $(@el).hasClass('neat-editable') and !@inEdit()
  template: -> if @inEdit() then @editTemplate else @showTemplate
  
  cancelEdit: (e)->
    e?.preventDefault()
    e?.stopImmediatePropagation()
    if @inEdit()
      $(@el).removeClass('editor').addClass('neat-editable')
      @render()
      @trigger('edit:end')
    @
  
  edit: ->
    unless @inEdit()
      $el = $(@el)
      $el.addClass('editor').removeClass('neat-editable hovered')
      @trigger('edit:begin')
      @render()
      $el.find(':input:visible').first().focus()
    @
  
  save: (e)->
    e?.preventDefault()
    $form = $(@el).closest('form')
    newAttributes = $form.serializeObject()
    @debug 'saving: ', newAttributes
    attributes =  @model.changedAttributes(newAttributes)
    
    if attributes
      previousAttributes = @model.toJSON()
      
      @model.save attributes,
        wait: true
        success: =>
          for attribute, newValue of attributes
            @debug "  . #{attribute} changed from ", previousAttributes[attribute], " to ", @model.get(attribute)
          @onSaveSuccess()
        error: _.bind(@onSaveError, @)
    
    @cancelEdit()
  
  delete: (e)->
    e?.preventDefault()
    if @confirmDelete(@resource)
      $(@el).removeClass('neat-editable').addClass('deleted')
      
      @model.destroy
        wait: true
        success: =>
          @model.collection.remove(@model) if @model.collection
          @onDeleteSuccess
        error: _.bind(@onSaveError, @)
      @cancelEdit()
  
  confirmDelete: (resource)->
    confirm("Delete this #{resource}?")
  
  
  
  onSaveSuccess: ->
  onSaveError: ->
  onDeleteSuccess: ->
  onDeleteError: ->
  
  
  
  debug: (o...)->
    @log(o...) if Neat.debug
  
  log: (o...)->
    Neat.logger.log "[#{@resource}] ", o...
