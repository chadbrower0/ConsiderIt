require './shared'


styles += """

#tooltip .downward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-top: 10px solid black;
}
#tooltip .upward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-bottom: 10px solid black;
}

"""

clear_tooltip = ->
  tooltip = fetch('tooltip')
  tooltip.coords = tooltip.tip = tooltip.top = tooltip.positioned = null
  tooltip.offsetY = tooltip.offsetX = null 
  tooltip.rendered_size = false 
  save tooltip


toggle_tooltip = (e) ->
  tooltip_el = e.target.closest('[data-tooltip]')
  if tooltip_el?
    tooltip = fetch('tooltip')
    if tooltip.coords
      clear_tooltip()
    else 
      show_tooltip(e)

show_tooltip = (e) ->
  tooltip_el = e.target.closest('[data-tooltip]')
  if tooltip_el?
    name = tooltip_el.getAttribute('data-tooltip')
    tooltip = fetch 'tooltip'
    tooltip.coords = $(tooltip_el).offset()
    tooltip.coords.left += tooltip_el.offsetWidth / 2
    tooltip.tip = name
    save tooltip
    e.preventDefault()

hide_tooltip = (e) ->
  tooltip_el = e.target.closest('[data-tooltip]')
  if tooltip_el?
    clear_tooltip()

document.addEventListener "click", toggle_tooltip

document.addEventListener "mouseover", show_tooltip
document.addEventListener "mouseout", hide_tooltip

$('body').on 'focusin', '[data-tooltip]', show_tooltip
$('body').on 'focusout', '[data-tooltip]', hide_tooltip

# focus/blur don't seem to work at document level
# document.addEventListener "focus", show_tooltip, true
# document.addEventListener "blur", hide_tooltip, true



window.Tooltip = ReactiveComponent
  displayName: 'Tooltip'

  render : -> 


    tooltip = fetch('tooltip')
    return SPAN(null) if !tooltip.coords

    coords = tooltip.coords
    tip = tooltip.tip

    style = _.defaults {}, (@props.style or {}), 
      fontSize: 14
      padding: '4px 8px'
      borderRadius: 8
      pointerEvents: 'none'
      zIndex: 999999999999
      color: 'white'
      backgroundColor: 'black'
      position: 'absolute'      
      boxShadow: '0 1px 1px rgba(0,0,0,.2)'
      maxWidth: 350



    if tooltip.top || !tooltip.top?
      # place the tooltip above the element
      _.extend style, 
        top: coords.top + (tooltip.offsetY or 0) - (tooltip.rendered_size?.height or 0) - 12
        left: if !tooltip.rendered_size then -99999 else coords.left + (tooltip.offsetX or 0) - tooltip.rendered_size?.width / 2
    else 
      # place the tooltip below the element
      _.extend style, 
        top: coords.top + (tooltip.offsetY or 0)
        left: if !tooltip.rendered_size then -99999 else coords.left + (tooltip.offsetX or 0) - (tooltip.rendered_size.width or 0)

    DIV
      id: 'tooltip'
      role: "tooltip"
      style: style


      DIV 
        dangerouslySetInnerHTML: {__html: tip}

      if tooltip.top || !tooltip.top?
        SPAN 
          className: 'downward_arrow'
          style: 
            position: 'absolute'
            bottom: -7
            left: if tooltip.positioned != 'right' then "calc(50% - 10px)" 
            right: if tooltip.positioned == 'right' then 7

      else   
        SPAN 
          className: 'upward_arrow'
          style: 
            position: 'absolute'
            left: if tooltip.positioned != 'right' then "calc(50% - 10px)" 
            top: -7
            right: if tooltip.positioned == 'right' then 7

  componentDidUpdate: ->
    tooltip = fetch('tooltip')
    if !tooltip.rendered_size && tooltip.coords 

      tooltip.rendered_size = 
        width: @getDOMNode().offsetWidth
        height: @getDOMNode().offsetHeight
      save tooltip

