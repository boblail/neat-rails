$.fn.extend
  cssHover: (selector)->
    if arguments.length == 0
      @hover(
        -> $(@).addClass('hovered'),
        -> $(@).removeClass('hovered'))
    else
      @delegate selector, 'hover', (e)->
        if e.type == 'mouseenter'
          $(@).addClass('hovered')
        else
          $(@).removeClass('hovered')    
  
  isIn: (selector)->
    @is(selector) or (@parents(selector).length > 0)
