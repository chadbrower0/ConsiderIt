require './shared'
require './customizations'
require './histogram'
require './slider'
require './permissions'
require './bubblemouth'


pad = (num, len) -> 
  str = num
  dec = str.split('.')
  i = 0 
  while i < len - dec[0].toString().length
    dec[0] = "0" + dec[0]
    i += 1

  dec[0] + if dec.length > 0 then '.' + dec[1] else ''

window.CollapsedProposal = ReactiveComponent
  displayName: 'CollapsedProposal'

  render : ->
    proposal = fetch @props.proposal
    options = @props.options

    col_sizes = column_sizes
                  width: @props.width

    current_user = fetch '/current_user'

    watching = current_user.subscriptions[proposal.key] == 'watched'

    return if !watching && fetch('homepage_filter').watched

    subdomain = fetch '/subdomain'

    your_opinion = fetch proposal.your_opinion
    if your_opinion?.published
      can_opine = permit 'update opinion', proposal, your_opinion, subdomain
    else
      can_opine = permit 'publish opinion', proposal, subdomain

    draw_slider = can_opine > 0 || your_opinion?.published

    icons = customization('show_proposer_icon', proposal, subdomain) && !@props.hide_icons
    slider_regions = customization('slider_regions', proposal, subdomain)
    show_proposal_scores = !@props.hide_scores && customization('show_proposal_scores', proposal, subdomain)

    opinions = opinionsForProposal(proposal)

    if draw_slider
      slider = fetch "homepage_slider#{proposal.key}"
    else 
      slider = null 

    if slider && your_opinion && slider.value != your_opinion.stance && !slider.has_moved 
      # Update the slider value when the server gets back to us
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider

    # sub_creation = new Date(fetch('/subdomain').created_at).getTime()
    # creation = new Date(proposal.created_at).getTime()
    # opacity = .05 + .95 * (creation - sub_creation) / (Date.now() - sub_creation)

    can_edit = permit('update proposal', proposal, subdomain) > 0

    opinion_views = fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']
    everyone = !!opinion_views.active_views['everyone'] || !!opinion_views.active_views['weighed_by_substantiated'] || !!opinion_views.active_views['weighed_by_recency']

    opinion_publish_permission = permit('publish opinion', proposal, subdomain)

    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal, subdomain)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"

    LI
      key: proposal.key
      id: 'p' + (proposal.slug or "#{proposal.id}").replace('-', '_')  # Initial 'p' is because all ids must begin 
                                           # with letter. seeking to hash was failing 
                                           # on proposals whose name began with number.
      style: _.defaults {}, (@props.wrapper_style or {}),
        minHeight: 84
        position: 'relative'
        margin: "0 0 #{if can_edit then '0' else '15px'} 0"
        padding: 0
        listStyle: 'none'


      onMouseEnter: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onMouseLeave: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local
      onFocus: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onBlur: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local

      DIV 
        style: 
          width: col_sizes.first 
          display: 'inline-block'
          verticalAlign: 'top'
          position: 'relative'

        DIV 
          style: 
            position: 'absolute'
            left: if icons then -40 - 18
            top: if icons then 4


          if icons
            editor = proposal_editor(proposal)

            if proposal.pic
              A
                href: proposal_url(proposal)
                'aria-hidden': true
                tabIndex: -1
                IMG
                  src: proposal.pic 
                  style:
                    height: 40
                    width: 40
                    borderRadius: 0
                    backgroundColor: '#ddd'
                    # opacity: opacity

            # Person's icon
            else if editor 
              A
                href: proposal_url(proposal)
                'aria-hidden': true
                tabIndex: -1
                Avatar
                  key: editor
                  user: editor
                  style:
                    height: 40
                    width: 40
                    borderRadius: 0
                    backgroundColor: '#ddd'
                    # opacity: opacity
            else 
              SPAN 
                style: 
                  height: 50
                  width: 50
                  display: 'inline-block'
                  verticalAlign: 'top'
                  border: "2px dashed #ddd"
          else
            @props.icon?() or SVG 
              key: 'bullet'
              style: 
                position: 'relative'
                left: -22
                top: 3
              width: 8
              viewBox: '0 0 200 200' 
              CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'



        # Name of Proposal
        DIV
          style:
            display: 'inline-block'
            paddingBottom: if !can_edit then 20 else 4
            width: col_sizes.first

          A
            className: 'proposal proposal_homepage_name'
            style: _.defaults {}, (@props.name_style or {}),
              fontWeight: 600
              textDecoration: 'underline'
              #borderBottom: "1px solid #444"  
              color: '#000'            
              fontSize: 20
              
            href: proposal_url(proposal, just_you)

            proposal.name

          if customization('proposal_show_description_on_homepage', null, subdomain)
            DIV 
              style: 
                fontSize: 14
                color: '#444'
                marginBottom: 4
              dangerouslySetInnerHTML: __html: proposal.description  

          DIV 
            style: 
              fontSize: 12
              color: '#555' #'#999'
              marginTop: 4
              #fontStyle: 'italic'

            if customization('proposal_meta_data', null, subdomain)?
              customization('proposal_meta_data', null, subdomain)(proposal)

            else if !@props.hide_metadata && customization('show_proposal_meta_data', null, subdomain)
              show_author_name_in_meta_data = !icons && (editor = proposal_editor(proposal)) && editor == proposal.user

              SPAN 
                style: 
                  paddingRight: 16

                if !show_author_name_in_meta_data
                  TRANSLATE 'engage.proposal_metadata_date_added', "Added: "
                
                prettyDate(proposal.created_at)


                SPAN 
                  style: 
                    padding: '0 8px'
                  '|'

                if show_author_name_in_meta_data
                  [ 
                    SPAN 
                      style: {}
                      TRANSLATE
                        id: 'engage.proposal_author'
                        name: fetch(editor)?.name 
                        " by {name}"

                    SPAN 
                      style: 
                        padding: '0 8px'
                      '|'
                  ]



                if customization('discussion_enabled', proposal, subdomain)
                    A 
                      href: proposal_url(proposal, true)
                      style: 
                        #fontWeight: 500
                        cursor: 'pointer'

                      TRANSLATE
                        id: "engage.point_count"
                        cnt: proposal.point_count

                        "{cnt, plural, one {# pro or con} other {# pros and cons}}"

                      if proposal.active && permit('create point', proposal, subdomain) > 0
                        [
                          SPAN 
                            style: 
                              padding: '0 8px'
                            '|'

                          SPAN 
                            style: 
                              textDecoration: 'underline'
                            TRANSLATE
                              id: "engage.add_your_own"

                              "add a consideration"
                        ]



            if @props.show_category && proposal.cluster
              SPAN 
                style: 
                  padding: '1px 2px'
                  color: @props.category_color or 'black'
                  fontWeight: 500

                get_list_title "list/#{proposal.cluster}", true, subdomain

            if opinion_publish_permission == Permission.DISABLED
              SPAN 
                style: 
                  padding: '0 16px'

                TRANSLATE "engage.proposal_closed.short", 'closed'

            else if opinion_publish_permission == Permission.INSUFFICIENT_PRIVILEGES
              SPAN 
                style: 
                  padding: '0 16px'

                TRANSLATE "engage.proposal_read_only.short", 'read-only'

          if can_edit
            DIV
              style: 
                visibility: if !@local.hover_proposal then 'hidden'
                position: 'relative'
                top: -2

              A 
                href: "#{proposal.key}/edit"
                style:
                  marginRight: 10
                  color: focus_color()
                  backgroundColor: 'transparent'
                  padding: 0
                  fontSize: 12
                TRANSLATE 'engage.edit_button', 'edit'

              if permit('delete proposal', proposal, subdomain) > 0
                BUTTON
                  style:
                    marginRight: 10
                    color: focus_color()
                    backgroundColor: 'transparent'
                    border: 'none'
                    padding: 0
                    fontSize: 12

                  onClick: => 
                    if confirm('Delete this proposal forever?')
                      destroy(proposal.key)
                      loadPage('/')
                  TRANSLATE 'engage.delete_button', 'delete'




      # Histogram for Proposal
      DIV 
        style: 
          display: 'inline-block' 
          position: 'relative'
          top: -26
          verticalAlign: 'top'
          width: col_sizes.second
          marginLeft: col_sizes.gutter
                

        Histogram
          key: "histogram-#{proposal.slug}"
          proposal: proposal
          opinions: opinions
          width: col_sizes.second
          height: 40
          enable_individual_selection: !browser.is_mobile
          enable_range_selection: !just_you && !browser.is_mobile
          draw_base: true
          draw_base_labels: !slider_regions

        Slider 
          base_height: 0
          draw_handle: !!draw_slider
          key: "homepage_slider#{proposal.key}"
          width: col_sizes.second
          polarized: true
          regions: slider_regions
          respond_to_click: false
          base_color: 'transparent'
          handle: slider_handle.triangley
          handle_height: 18
          handle_width: 21
          handle_style: 
            opacity: if just_you && !browser.is_mobile && @local.hover_proposal != proposal.key && !@local.slider_has_focus then 0 else 1             
          offset: true
          ticks: 
            increment: .5
            height: 2

          handle_props:
            use_face: false
          label: translator
                    id: "sliders.instructions"
                    negative_pole: get_slider_label("slider_pole_labels.oppose", proposal, subdomain)
                    positive_pole: get_slider_label("slider_pole_labels.support", proposal, subdomain)
                    "Express your opinion on a slider from {negative_pole} to {positive_pole}"
          onBlur: (e) => @local.slider_has_focus = false; save @local
          onFocus: (e) => @local.slider_has_focus = true; save @local 

          readable_text: slider_interpretation
          onMouseUpCallback: (e) =>
            # We save the slider's position to the server only on mouse-up.
            # This way you can drag it with good performance.
            if your_opinion.stance != slider.value

              # save distance from top that the proposal is at, so we can 
              # maintain that position after the save potentially triggers 
              # a re-sort. 
              prev_offset = @getDOMNode().offsetTop
              prev_scroll = window.scrollY

              your_opinion.stance = slider.value
              your_opinion.published = true
              save your_opinion
              window.writeToLog 
                what: 'move slider'
                details: {proposal: proposal.key, stance: slider.value}
              @local.slid = 1000

              update = fetch('homepage_you_updated_proposal')
              update.dummy = !update.dummy
              save update

            mouse_over_element = closest e.target, (node) => 
              node == @getDOMNode()

            if @local.hover_proposal == proposal.key && !mouse_over_element
              @local.hover_proposal = null 
              save @local
    
      # little score feedback
      if show_proposal_scores        
        DIV 
          style: 
            position: 'absolute'
            left: "calc(100% + 22px)"
            top: 9

          HistogramScores
            proposal: proposal

window.HistogramScores = ReactiveComponent
  displayName: 'HistogramScores'

  render: ->
    proposal = @props.proposal

    {weights, salience, groups} = compose_opinion_views(opinions, proposal)
    opinions = get_opinions_for_proposal opinions, proposal, weights


    if opinions.length == 0 
      return SPAN null

    all_groups = get_user_groups_from_views groups
    has_groups = !!all_groups


    show_tooltip = => 
      if has_groups && opinions.length > 0
        tooltip = fetch 'tooltip'
        anchor = $(@refs.score.getDOMNode())
        tooltip.coords = anchor.offset()
        tooltip.offsetY = anchor[0].offsetHeight + 8
        tooltip.offsetX = anchor[0].offsetWidth
        tooltip.positioned = 'right'
        tooltip.top = false
        colors = get_color_for_groups all_groups

        legend_color_size = 28

        rating_str = "0000 / 00%"

        group_scores = {}

        for group in all_groups 

          weight = 0
          cnt = 0
          score = 0
          for o in opinions 
            continue if salience[o.user.key or o.user] < 1 or group not in groups[o.user.key or o.user]
            w = weights[o.user.key or o.user]
            score += o.stance * w
            weight += w
            cnt += 1
          avg = score / weight
          if weight > 0 
            group_scores[group] = {avg, cnt}

        visible_groups = Object.keys group_scores
        visible_groups.sort (a,b) -> group_scores[b].avg - group_scores[a].avg

        separator_inserted = false 

        items = visible_groups.slice()

        if items.length > 1
          separator_idx = 0
          for group,idx in items 
            {avg, cnt} = group_scores[group]
            if idx != 0 && group_scores[items[idx - 1]].avg > overall_avg \
                        && group_scores[items[idx]].avg <= overall_avg 
              separator_idx = idx 
              break 
          items.splice separator_idx, 0, 'avg_separator'

        tooltip.render =  =>
          opinion_views = fetch 'opinion_views'
          DIV 
            style: 
              padding: "12px 12px 12px 18px"

            DIV 
              style:
                marginBottom: 12
              "Grouped by: #{opinion_views.active_views.group_by.name}"

            UL 
              'aria-hidden': true
              style: 
                listStyle: 'none'

              for group,idx in items 
                insert_separator = group == 'avg_separator' 

                if insert_separator
                  separator_inserted = true 
                else 
                  {avg, cnt} = group_scores[group]

                diff = avg - overall_avg

                LI 
                  style: 
                    fontSize: 14
                    display: 'flex'
                    alignItems: 'center'
                    marginBottom: 16

                  DIV 
                    style: 
                      borderRadius: '50%'
                      backgroundColor: colors[group]
                      width: legend_color_size
                      height: legend_color_size
                      display: 'inline-block'
                      border: '1px solid white'
                      boxShadow: "inset 0 -1px 2px 0 rgba(0,0,0,0.16)"
                      visibility: if insert_separator then 'hidden'

                  DIV 
                    style: 
                      paddingLeft: 12

                    DIV 
                      style: 
                        fontWeight: 500
                        fontFamily: 'Fira Sans Condensed'
                        textAlign: if insert_separator then 'right'

                      if !insert_separator
                        group
                      else 
                        "Overall average opinion:"

                    
                    if !insert_separator
                      DIV 
                        style: 
                          color: 'white'
                          marginTop: -2
                          fontSize: 11

                        "#{Math.round(avg * 100)}% • "
                        TRANSLATE
                          id: "engage.proposal_score_summary"
                          num_opinions: cnt 
                          "{num_opinions, plural, =0 {no opinions} one {# opinion} other {# opinions} }"

                  DIV 
                    style: 
                      color: if insert_separator then 'white' else if diff < 0 then '#ff3636' else '#21e621'
                      textAlign: 'right'
                      flex: 1
                      paddingLeft: 16
                      fontSize: 12
                      fontWeight: 600

                    if insert_separator
                      "#{Math.round(overall_avg * 100)}%" 
                    else 
                      "#{if diff > 0 then '+' else ''}#{Math.round(diff * 100)}%"




        save tooltip


    overall_score = 0
    overall_weight = 0
    overall_cnt = 0
    for o in opinions 
      continue if salience[o.user.key or o.user] < 1
      w = weights[o.user.key or o.user]
      overall_score += o.stance * w
      overall_weight += w
      overall_cnt += 1
    overall_avg = overall_score / overall_weight
    negative = overall_score < 0
    overall_score *= -1 if negative

    score = pad overall_score.toFixed(1),2


    DIV 
      'aria-hidden': true
      ref: 'score'
      style: 
        textAlign: 'left'
        whiteSpace: 'nowrap'


      onFocus: show_tooltip
      onMouseEnter: show_tooltip
      onBlur: clearTooltip
      onMouseLeave: clearTooltip


      SPAN 
        style: 
          color: '#555'
          cursor: 'default'
          lineHeight: .8
          fontSize: 11

        TRANSLATE
          id: "engage.proposal_score_summary"

          num_opinions: overall_cnt 
          "{num_opinions, plural, =0 {no opinions} one {# opinion} other {# opinions} }"

        DIV 
          style: 
            position: 'relative'
            top: -4
      
          TRANSLATE
            id: "engage.proposal_score_summary.explanation"
            percentage: Math.round(overall_avg * 100) 
            "{percentage}% average"

        if has_groups
          DIV 
            style: 
              color: focus_color()
              position: 'relative'
              top: -4
            'by group' 














window.MediaCollapsedProposal = ReactiveComponent
  displayName: 'MediaCollapsedProposal'

  render : ->
    proposal = fetch @props.proposal
    options = @props.options

    @max_description_height = 48

    col_sizes = column_sizes
                  width: @props.width

    current_user = fetch '/current_user'

    watching = current_user.subscriptions[proposal.key] == 'watched'

    return if !watching && fetch('homepage_filter').watched

    your_opinion = fetch proposal.your_opinion
    if your_opinion?.published
      can_opine = permit 'update opinion', proposal, your_opinion
    else
      can_opine = permit 'publish opinion', proposal

    draw_slider = can_opine > 0 || your_opinion?.published

    icons = customization('show_proposer_icon', proposal) && !@props.hide_icons
    slider_regions = customization('slider_regions', proposal)
    show_proposal_scores = !@props.hide_scores && customization('show_proposal_scores', proposal)

    opinions = opinionsForProposal(proposal)

    if draw_slider
      slider = fetch "homepage_slider#{proposal.key}"
    else 
      slider = null 

    if slider && your_opinion && slider.value != your_opinion.stance && !slider.has_moved 
      # Update the slider value when the server gets back to us
      slider.value = your_opinion.stance
      if your_opinion.stance
        slider.has_moved = true
      save slider

    can_edit = permit('update proposal', proposal) > 0

    just_you = opinion_views.active_views['just_you']
    everyone = opinion_views.active_views['everyone']

    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"

    LI
      key: proposal.key
      id: 'p' + (proposal.slug or "#{proposal.id}").replace('-', '_')  # Initial 'p' is because all ids must begin 
                                           # with letter. seeking to hash was failing 
                                           # on proposals whose name began with number.
      style: _.defaults {}, (@props.wrapper_style or {}),

        position: 'relative'
        margin: "0 0 68px 0"
        padding: 0
        listStyle: 'none'

      onMouseEnter: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onMouseLeave: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local
      onFocus: => 
        if draw_slider
          @local.hover_proposal = proposal.key; save @local
      onBlur: => 
        if draw_slider && !slider.is_moving
          @local.hover_proposal = null; save @local



      DIV 
        style: 
          position: 'relative'


        DIV 
          style: 
            color: 'black'
            textTransform: 'uppercase'
            marginBottom: 4

          get_list_title "list/#{proposal.cluster}", true

        # Name of Proposal
        DIV
          style:
            display: 'inline-block'
            paddingBottom: if !can_edit then 20 else 4

          A
            className: 'proposal proposal_homepage_name'
            style: _.defaults {}, (@props.name_style or {}),
              color: '#000'            
              fontSize: 28
              fontFamily: header_font()
              textDecoration:'underline'

            href: proposal_url(proposal, just_you)

            proposal.name

          # short description
          if proposal.description
            DIV 
              ref: 'shortened_description'
              style: 
                color: '#666'
                maxHeight: if @local.description_collapsed then @max_description_height
                overflow: if @local.description_collapsed then 'hidden'
              dangerouslySetInnerHTML: __html: proposal.description 
          
          if @local.description_collapsed
            BUTTON
              id: 'expand_full_text'
              style:
                cursor: 'pointer'
                padding: '12px 0 10px 0'
                textAlign: 'left'
                border: 'none'
                backgroundColor: 'transparent'

              onMouseDown: => 
                @local.description_collapsed = false
                save(@local)

              onKeyDown: (e) =>
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  @local.description_collapsed = false
                  e.preventDefault()
                  document.activeElement.blur()
                  save(@local)

              '(more)'


          if can_edit
            DIV
              style: 
                visibility: if !@local.hover_proposal then 'hidden'
                position: 'relative'
                top: -2

              A 
                href: "#{proposal.key}/edit"
                style:
                  marginRight: 10
                  color: focus_color()
                  backgroundColor: 'transparent'
                  padding: 0
                  fontSize: 12
                TRANSLATE 'engage.edit_button', 'edit'

              if permit('delete proposal', proposal) > 0
                BUTTON
                  style:
                    marginRight: 10
                    color: focus_color()
                    backgroundColor: 'transparent'
                    border: 'none'
                    padding: 0
                    fontSize: 12

                  onClick: => 
                    if confirm('Delete this proposal forever?')
                      destroy(proposal.key)
                      loadPage('/')
                  TRANSLATE 'engage.delete_button', 'delete'



      # Histogram for Proposal
      DIV 
        style: 
          position: 'relative'
                

        Histogram
          key: "histogram-#{proposal.slug}"
          proposal: proposal
          opinions: opinions
          width: HOMEPAGE_WIDTH()
          height: 136
          enable_individual_selection: !browser.is_mobile
          enable_range_selection: everyone && !browser.is_mobile
          draw_base: true
          draw_base_labels: !slider_regions

        Slider 
          base_height: 0
          draw_handle: !!draw_slider
          key: "homepage_slider#{proposal.key}"
          width: HOMEPAGE_WIDTH()
          polarized: true
          regions: slider_regions
          respond_to_click: false
          base_color: 'transparent'
          handle: slider_handle.triangley
          handle_height: 18
          handle_width: 21
          handle_style: 
            opacity: if just_you && !browser.is_mobile && @local.hover_proposal != proposal.key && !@local.slider_has_focus then 0 else 1             
          offset: true
          handle_props:
            use_face: false
          label: translator
                    id: "sliders.instructions"
                    negative_pole: get_slider_label("slider_pole_labels.oppose", proposal)
                    positive_pole: get_slider_label("slider_pole_labels.support", proposal)
                    "Express your opinion on a slider from {negative_pole} to {positive_pole}"
          onBlur: (e) => @local.slider_has_focus = false; save @local
          onFocus: (e) => @local.slider_has_focus = true; save @local 

          readable_text: slider_interpretation
          onMouseUpCallback: (e) =>
            # We save the slider's position to the server only on mouse-up.
            # This way you can drag it with good performance.
            if your_opinion.stance != slider.value

              # save distance from top that the proposal is at, so we can 
              # maintain that position after the save potentially triggers 
              # a re-sort. 
              prev_offset = @getDOMNode().offsetTop
              prev_scroll = window.scrollY

              your_opinion.stance = slider.value
              your_opinion.published = true
              save your_opinion
              window.writeToLog 
                what: 'move slider'
                details: {proposal: proposal.key, stance: slider.value}
              @local.slid = 1000

              update = fetch('homepage_you_updated_proposal')
              update.dummy = !update.dummy
              save update

            mouse_over_element = closest e.target, (node) => 
              node == @getDOMNode()

            if @local.hover_proposal == proposal.key && !mouse_over_element
              @local.hover_proposal = null 
              save @local

  componentDidMount : ->
    proposal = fetch @props.proposal
    if (proposal.description && @max_description_height && @local.description_collapsed == undefined \
        && $(@refs.shortened_description.getDOMNode()).height() > @max_description_height)
      @local.description_collapsed = true; save(@local)

  componentDidUpdate : ->
    proposal = fetch @props.proposal
    if (proposal.description && @max_description_height && @local.description_collapsed == undefined \
        && $(@refs.shortened_description.getDOMNode()).height() > @max_description_height)
      @local.description_collapsed = true; save(@local)

