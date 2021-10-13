require './shared'


zero_popover = -> 
  popover = fetch('popover')
  popover.coords = popover.tip = popover.render = popover.top = popover.positioned = null
  popover.offsetY = popover.offsetX = null 
  popover.rendered_size = false 
  popover.id = null
  popover.hide_triangle = false
  popover.size_checked = undefined
  save popover

window.clear_popover = (immediate, cb) ->
  popover = fetch('popover')

  if immediate
    zero_popover()
    cb?()
  else 
    id = popover.id

    setTimeout ->
      if !popover.has_focus && popover.id == id && !popover.element_in_focus
        zero_popover()
        cb?()
    , 250






window.hide_popover = (e) ->
  if e.target.getAttribute('data-popover')
    if e.target.getAttribute('data-title')
      e.target.setAttribute('title', e.target.getAttribute('data-title'))
      e.target.removeAttribute('data-title')
    popover = fetch('popover')
    popover.element_in_focus = false 
    if popover.coords
      clear_popover false, ->
        if e.target.getAttribute('data-previous_zindex')?
          e.target.style.zIndex = e.target.getAttribute('data-previous_zindex')
          e.target.removeAttribute 'data-previous_zindex'


window.toggle_popover = (e) ->
  if e.target.getAttribute('data-popover')
    popover = fetch('popover')
    if popover.element_in_focus
      hide_popover(e)
    else 
      show_popover(e) 


window.show_popover = (e) ->
  if e.target.getAttribute('data-popover')
    popover = fetch 'popover'

    popover.element_in_focus = e.target.getAttribute('data-popover')

    setTimeout -> 
      if popover.element_in_focus == e.target.getAttribute('data-popover') 



        if e.target.getAttribute('title')
          e.target.setAttribute('data-title', e.target.getAttribute('title'))
          e.target.removeAttribute('title')

        style = getComputedStyle(e.target)
        if style?.zIndex
          e.target.setAttribute('data-previous_zindex', "#{e.target.style.zIndex}")
          e.target.style.zIndex = "#{parseInt(style.zIndex) + 1}"

        if e.target.getAttribute('data-user')
          user = e.target.getAttribute('data-user')
          if user != popover.id 
            clear_popover(true)
            anon = e.target.getAttribute('data-anonymous') == 'true'
            popover.id = user 
            popover.render = -> 
              AvatarPopover 
                key: user 
                user: user
                anon: anon
                opinion: e.target.getAttribute('data-opinion')
        else if e.target.getAttribute('data-proposal-scores')
          proposal = e.target.getAttribute('data-popover')
          if proposal != popover.id 
            clear_popover(true)
            popover.render = -> 
              ProposalScoresPopover 
                key: proposal
                proposal: proposal
                overall_avg: parseFloat(e.target.getAttribute('data-proposal-scores'))

            popover.offsetY = e.target.offsetHeight + 12
            popover.offsetX = -e.target.offsetWidth / 2 + 36
            popover.positioned = 'right'
            popover.top = false
            popover.id = proposal

        else 
          popover.tip = e.target.getAttribute('data-popover')

        popover.coords = calc_coords(e.target) 

        save popover
    , 400
    e.preventDefault()


calc_coords = (el) ->
  coords = $(el).offset()
  coords.left += el.offsetWidth / 2
  coords



document.addEventListener "mouseover", show_popover
document.addEventListener "mouseout", hide_popover

$('body').on 'focusin', '[data-popover]', show_popover
$('body').on 'focusout', '[data-popover]', hide_popover


$('body').on 'click', '[data-popover]', toggle_popover

window.Popover = ReactiveComponent
  displayName: 'Popover'

  render : -> 
    popover = fetch('popover')
    return SPAN(null) if !popover.coords

    coords = popover.coords
    tip = popover.tip

    style = _.defaults {}, (@props.style or {}), 
      fontSize: 14
      padding: '4px 8px'
      borderRadius: 8
      zIndex: 9999
      color: 'black'
      backgroundColor: 'white'
      position: 'absolute'      
      boxShadow: '0 1px 9px rgba(0,0,0,.5)'
      # maxWidth: 350


    arrow_size = 
      height: 10
      width: 26

    if popover.top || !popover.top?
      # place the popover above the element
      _.extend style, 
        top: coords.top + (popover.offsetY or 0) - (popover.rendered_size?.height or 0) - arrow_size.height
        left: if !popover.rendered_size then -99999 else coords.left + (popover.offsetX or 0) - popover.rendered_size?.width / 2
    else 
      # place the popover below the element
      _.extend style, 
        top: coords.top + (popover.offsetY or 0)
        left: if !popover.rendered_size then -99999 else coords.left + (popover.offsetX or 0) - (popover.rendered_size.width or 0)

    arrow_up = popover.top || !popover.top?

    get_focus = ->
      popover.has_focus = true 
      save popover 
    lose_focus = ->
      popover.has_focus = false 
      clear_popover()
      save popover 

    DIV
      id: 'popover'
      role: "popover"
      style: style
      onFocus: get_focus
      onMouseEnter: get_focus
      onBlur: lose_focus
      onMouseLeave: lose_focus

      if popover.render 
        popover.render()
      else 
        DIV 
          dangerouslySetInnerHTML: {__html: tip}

      SVG 
        width: arrow_size.width
        height: arrow_size.height 
        viewBox: "0 0 531.74 460.5"
        preserveAspectRatio: "none"
        style: 
          position: 'absolute'
          bottom: if arrow_up then -arrow_size.height
          top: if !arrow_up then -arrow_size.height
          left: if popover.positioned != 'right' then "calc(50% - #{arrow_size.width / 2}px)" 
          right: if popover.positioned == 'right' then 7       
          transform: if !arrow_up then 'scale(1,-1)' 
          display: if popover.hide_triangle then 'none' 

        POLYGON
          stroke: "none" 
          fill: 'white'
          points: "530.874,0.5 265.87,459.5 0.866,0.5"

        G null,
          for x1 in [0.866, 530.874]
            LINE 
              x1: x1
              y1: 0.5
              x2: 265.87
              y2: 459.5
              stroke: "black" 
              strokeWidth: 35
              strokeOpacity: .25

  


  componentDidUpdate: ->
    popover = fetch('popover')

    if popover.coords 
      rendered_size = 
        width: @getDOMNode().offsetWidth
        height: @getDOMNode().offsetHeight

      popover.rendered_size ?= {}

      if rendered_size.width != popover.rendered_size.width || rendered_size.height != popover.rendered_size.height
        popover.size_checked ?= Date.now()
        if Date.now() - popover.size_checked < 500
          popover.rendered_size = rendered_size
          save popover
