##
# EditPoint
# Form for editing or creating a point. Used by NewPoint component & when someone
# edits their point. 
window.EditPoint = ReactiveComponent
  displayName: 'EditPoint'

  render : ->
    proposal = fetch @props.proposal
    point = fetch @props.point 

    if !@local.sign_name?
      _.defaults @local, 
        sign_name : if @props.fresh then true else !point.hide_name
        add_details : false

    textarea_style = 
      width: '100%'
      overflow: 'hidden'
      fontSize: 14
      padding: '4px 6px'

    style = 
      position: 'relative'
      fontSize: 14
      zIndex: 1
      marginTop: if TABLET_SIZE() then 40
      marginBottom: 15


    DIV
      className: 'edit_point'
      style: style
      'aria-describedby': 'tips_for_new_point'

      DIV
        style: 
          position: 'relative'

        @drawTips()


        CharacterCountTextInput 
          id: 'nutshell'
          ref: 'nutshell'
          maxLength: 180
          name: 'nutshell'
          pattern: '^.{3,}'
          'aria-label': translator('engage.point_summary_placeholder', 'A succinct summary of your point.')
          placeholder:  translator('engage.point_summary_placeholder', 'A succinct summary of your point.')
          required: 'required'
          defaultValue: if @props.fresh then null else point.nutshell
          style: _.extend {}, textarea_style,
            minHeight: 75
          count_style: 
            position: 'absolute'
            right: 0
            top: -21   

        INPUT 
          id:'is_pro'
          name: 'is_pro'
          type: 'hidden'
          value: "#{@props.valence == 'pros'}"

      
      DIV null,
          
        AutoGrowTextArea 
          id:'text'
          name:'fulltext'
          'aria-label': translator('engage.point_description_placeholder', 'Add background or evidence.')  
          placeholder: translator('engage.point_description_placeholder', 'Add background or evidence.')  
          min_height: 80 # if PORTRAIT_MOBILE() then 150 else 80
          defaultValue: if @props.fresh then null else point.text
          style: textarea_style
          onHeightChange: => 
            s = fetch('reasons_height_adjustment')
            s.edit_point_height = $$.height ReactDOM.findDOMNode(@)
            save s

      if @local.errors?.length > 0
        
        DIV
          role: 'alert'
          style:
            fontSize: 18
            color: 'darkred'
            backgroundColor: '#ffD8D8'
            padding: 10
            marginTop: 10
          for error in @local.errors
            DIV null, 
              I
                className: 'fa fa-exclamation-circle'
                style: {paddingRight: 9}

              SPAN null, error

      DIV 
        style: 
          marginTop: 3
          marginBottom: '.5em'

        if !proposal.active
          DIV 
            style: {color: '#777', fontSize: 12}
            translator 'engage.no_new_points', 'New points disabled for this proposal'
        else
          BUTTON 
            className: 'btn'
            ref: 'submit_point'
            'data-action': 'submit-point'
            onClick: @savePoint
            style: 
              backgroundColor: focus_color() 
            translator 'engage.done_button', 'Done'             

        BUTTON
          onTouchEnd: @done
          onClick: @done
          className: 'like_link'
          style:
            color: '#888888'
            top: 2 #if mobile then 0 else 2
            marginLeft: 10
            # right: if mobile then -10 else 20
            position: 'relative'
            padding: if mobile then 10 else 0
          translator 'shared.cancel_button', 'cancel'

        DIV 
          style: 
            clear: 'both'

      if proposal.active
        DIV 
          style: 
            position: 'relative'

          INPUT
            className: 'newpoint-anonymous'
            type:      'checkbox'
            id:        "sign_name-#{@props.valence}"
            name:      "sign_name-#{@props.valence}"
            checked:   @local.sign_name
            style: 
              verticalAlign: 'middle'
            onChange: =>
              @local.sign_name = !@local.sign_name
              save(@local)
          
          LABEL 
            htmlFor: "sign_name-#{@props.valence}"
            title: translator 'engage.point_anonymous_toggle_explanation', """This won\'t make your point perfectly anonymous, but will make \
                     it considerably harder for others to associate with you. \
                     Note that signing your name lends your point more weight \
                     with peers."""
            translator 'engage.point_anonymous_toggle', 'Sign your name'


  componentDidMount : ->
    proposal = fetch @props.proposal

    if proposal.active 

      ReactDOM.findDOMNode(@refs.nutshell).querySelector('#nutshell').focus() 
      
      $$.ensureInView ReactDOM.findDOMNode(@refs.submit_point),
        scroll: false
        position: 'bottom'

      s = fetch('reasons_height_adjustment')
      s.edit_point_height = $$.height ReactDOM.findDOMNode(@)
      save s

  componentWillUnmount : -> 
    s = fetch('reasons_height_adjustment')
    s.edit_point_height = 0       
    save s    

  # guidelines/tips for good points
  drawTips : -> 
    proposal = fetch @props.proposal

    singular =  if @props.valence == 'pros' 
                  get_point_label 'pro', proposal
                else 
                  get_point_label 'con', proposal

    plural =  get_point_label @props.valence, proposal 

    DIV 
      id: 'tips_for_new_point'
      style:
        position: 'absolute'
        left: if @props.valence == 'pros' then "calc(-100% - 4px)" else "calc(100% + 4px)"

        width: "100%"
        color: 'white'
        zIndex: 1
        backgroundColor: focus_color() 

      DIV 
        style: 
          padding: '14px 18px'
          position: 'relative'

        SPAN 
          style: 
            fontWeight: 600

          translator 
            id: 'engage.write_point_header'
            pro_or_con: capitalize(singular)
            "Write a new {pro_or_con}"

        UL 
          style: 
            listStylePosition: 'outside'
            marginLeft: 16
            marginTop: 5

          do ->
            tips = [translator({id: "engage.point_authoring.tip_single", pros_or_cons: capitalize(plural)}, "Make only one point. Add multiple {pros_or_cons} if you have more."),
                    translator("engage.point_authoring.tip_direct", "Be direct. The summary is your main point.")
                    translator("engage.point_authoring.tip_attacks", "No personal attacks.")
                   ]

            for tip in tips
              LI 
                key: tip
                style: 
                  paddingBottom: 3
                tip  

  done : ->
    your_points = fetch @props.your_points_key
    if @props.fresh
      your_points.adding_new_point = false
    else
      your_points.editing_points = _.without your_points.editing_points, @props.point

    save your_points

  savePoint : (ev) ->

    proposal = fetch @props.proposal
  
    form = ReactDOM.findDOMNode(@)

    nutshell = form.querySelector('#nutshell').value
    text = form.querySelector('#text').value
    hide_name = !@local.sign_name

    if !@props.fresh
      # If we're updating an existing point, we just have to update
      # some of the fields from the form
      point = fetch @props.point
      point.nutshell = nutshell
      point.text = text
      point.hide_name = hide_name
    else
      current_user = fetch('/current_user').user
      point =
        key : '/new/point'
        is_pro : @props.valence == 'pros'
        user : current_user
        comment_count : 0
        includers : [current_user]
        proposal : proposal.key
        nutshell : nutshell
        text : text
        hide_name : hide_name

    point.errors = []
    save point, => 
      if point.errors?.length == 0
        @done()
        show_flash(translator('engage.flashes.point_saved', "Your point has been saved"))
      else
        @local.errors = point.errors
        save @local
