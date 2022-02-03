

styles += """
  .INTAKE_QUESTIONS .intake-question {
    background-color: #F1F1F1;
    border: 1px solid #DDDDDD;
    padding: 18px 10px 18px 38px;
    border-radius: 8px;
    margin: 8px 0;
  }

  .INTAKE_QUESTIONS .intake-question.open {
    display: flex;
    align-items: start;
    position: relative;
  }


  .INTAKE_QUESTIONS .intake-question.open button {
    flex-shrink: 0;
    flex-grow: 0;
    display: inline-block;
    margin-left: 24px;
    background-color: transparent;
    border: none;
  }

  .INTAKE_QUESTIONS .intake-question.open svg {
  }


  .INTAKE_QUESTIONS .intake-question.open .name {
    font-size: 16px; 
    font-weight: 500;
    padding-right: 60px;
    flex-grow: 1;
  }

  .INTAKE_QUESTIONS button.new_question {
    padding: "8px 8px";
    margin-top: 12px;
  }





"""


question_index = (question) -> 
  subdomain = fetch '/subdomain'
  qidx = null
  for q, idx in (subdomain.customizations.user_tags or [])
    if q.self_report.question == question.self_report.question
      qidx = idx
      break 
  qidx

delete_question = (question) -> 
  if confirm("Are you sure you want to delete this question?")
    subdomain = fetch '/subdomain'

    delete_idx = question_index question 

    if delete_idx != null
      subdomain.customizations.user_tags.splice delete_idx, 1
      save subdomain


move_question = (from, to) -> 
  subdomain = fetch '/subdomain'

  uneditable_tags = (q for q in subdomain.customizations.user_tags when !q.self_report)
  questions = (q for q in subdomain.customizations.user_tags when q.self_report)

  moving = questions[from]

  questions.splice from, 1
  questions.splice to, 0, moving

  questions.concat uneditable_tags
  subdomain.customizations.user_tags = questions
  save subdomain


window.IntakeQuestions = ReactiveComponent
  displayName: 'IntakeQuestions'

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    intake_q_state = fetch 'intake-questions'

    subdomain.customizations.user_tags ?= []

    questions = (q for q in subdomain.customizations.user_tags when q.self_report)

    DIV 
      className: 'INTAKE_QUESTIONS'



      P null,
        """
          Intake questions enable you to collect information from new participants during account 
          registration (e.g. demographics). This information is then available to you in exploratory 
          data analysis, as well as in data export. 
        """

        # It can help you better understand who is participating and what different groups think.

      P
        style: 
          fontStyle: 'italic'
          marginTop: 18
        """
          Recommendation: Because each question makes the registration process take longer, 
          only ask questions you are confident will be important in your analysis. Aim for five 
          or fewer questions.
        """



      DIV 
        style: 
          marginTop: 36

        H2 
          style: 
            fontSize: 22

          "Questions"


        UL 
          style: 
            listStyle: 'none'

          for q, idx in questions
            do (q) =>

              LI 
                "data-idx": idx
                className: "intake-question open"
                draggable: true

                SPAN
                  className: 'name'

                  q.view_name or q.self_report.question


                BUTTON 
                  style: 
                    cursor: 'pointer'
                  onClick: => 
                    intake_q_state.editing = q
                    save intake_q_state
                  onKeyPress: (e) -> 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      e.preventDefault()
                      intake_q_state.editing = q
                      save intake_q_state

                  edit_icon 23, 23, '#888'

                BUTTON 
                  style: 
                    cursor: 'move'

                  drag_icon 23, '#888'

                BUTTON 
                  style:
                    position: 'absolute'
                    right: -36
                    cursor: 'pointer'
                  onClick: -> delete_question(q)
                  onKeyPress: (e) -> 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      e.preventDefault()
                      delete_question(q)
                  trash_icon 23, 23, '#888'


        BUTTON 
          className: 'new_question btn'
          onClick: -> 
            intake_q_state.new_question = true 
            save intake_q_state
          onKeyPress: (e) -> 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              e.preventDefault()
              intake_q_state.new_question = true 
              save intake_q_state

          "+ question"


      DIV 
        style: 
          marginTop: 36

        LABEL 
          style: {}

          H2
            style: 
              display: 'inline-block'
              fontSize: 22
            "Preamble"

          SPAN 
            style: 
              fontSize: 16
              fontWeight: 400
              paddingLeft: 6
            "optional"

          TEXTAREA
            style: 
              width: '100%'
              padding: '6px 8px'
              fontSize: 17
            defaultValue: subdomain.customizations?.host_questions_framing
            onChange: (ev) ->
              subdomain.customizations.host_questions_framing = ev.target.value
              save subdomain

            rows: 3

        DIV 
          style: 
            fontSize: 14
          "Message shown to participants before they answer your intake questions."

        if intake_q_state.editing || intake_q_state.new_question
          EditIntakeQuestion()


  componentDidMount: ->
    @makeQuestionsDraggable()

  componentDidUpdate: -> 
    @makeQuestionsDraggable()

  makeQuestionsDraggable: ->

    @onDragOver ?= (e) =>
      e.preventDefault()
      @draggedOver = e.currentTarget.getAttribute('data-idx')

    @onDragStart ?= (e) =>
      @dragging = e.currentTarget.getAttribute('data-idx')

    @onDrop ?= (e) =>
      move_question @dragging, @draggedOver

    for question in @getDOMNode().querySelectorAll('.intake-question.open')
      question.removeEventListener('dragstart', @onDragStart) 
      question.removeEventListener('dragover', @onDragOver)
      question.removeEventListener('drop', @onDrop) 

      question.addEventListener('dragstart', @onDragStart) 
      question.addEventListener('dragover', @onDragOver)
      question.addEventListener('drop', @onDrop) 



styles += """
  [data-widget="EditIntakeQuestion"] #modal-wrapper {
    margin: 0 auto;
    position: relative;
    z-index: 0;
    padding: 3em 0;
  }

  [data-widget="EditIntakeQuestion"] #modal-body {
    padding: 3.5em 125px 4em 125px;
    font-size: 16px;
    box-shadow: 0 2px 4px rgba(0,0,0,.4), 0 0 100px rgb(255 255 255 / 40%);
    background-color: #f1f1f1;
    position: relative;
    border-radius: 16px;
  }

  [data-widget="EditIntakeQuestion"] .field {
    margin-bottom: 24px;
  }

  [data-widget="EditIntakeQuestion"] label {
    display: block;

  }

  [data-widget="EditIntakeQuestion"] .field label {
    font-size: 13px;
    font-weight: 500;
    text-transform: uppercase;
    margin-bottom: 4px;
    // color: #666;
  }

  [data-widget="EditIntakeQuestion"] input[type="text"], [data-widget="EditIntakeQuestion"] textarea {
    padding: 6px 8px;
    width: 100%;
    font-size: 16px;
    border: 1px solid #d1d1d1;
  }

"""

window.EditIntakeQuestion = ReactiveComponent
  displayName: "EditIntakeQuestion"

  mixins: [Modal]

  render: -> 
    subdomain = fetch '/subdomain'
    intake_q_state = fetch 'intake-questions'

    question = intake_q_state.editing

    _.defaults @local, 
      input_type: question?.self_report?.input or 'dropdown'
      view_name: question?.view_name
      question: question?.self_report?.question
      options: question?.self_report?.options?.join('\n')
      required: if intake_q_state.new_question then true else question?.self_report?.required
      visibility: if intake_q_state.new_question then 'host-only' else question?.visibility

    if intake_q_state.editing  
      idx = question_index question

    wrap_in_modal = (children) -> 
      DIV null,

        DIV 
          id: 'lightbox'

        DIV
          id: 'modal'
          ref: 'dialog'
          role: 'dialog'
          # 'aria-labeledby': 'AUTH_task'
          # 'aria-describedby': if options.goal then 'AUTH_goal'


          DIV
            id: 'modal-wrapper'
            style: 
              maxWidth: AUTH_WIDTH() 

            DIV
              id: 'modal-body'

              children


    save_question = => 
      if intake_q_state.new_question
        question = 
          key: "#{subdomain.name}-#{slugify(@local.question)}"
          view_name: @local.view_name
          visibility: @local.visibility
          self_report: 
            question: @local.question
            input: @local.input_type
            options: if @local.input_type != 'text' then @local.options?.split('\n') else null
            required: @local.required

        if question.self_report.options?.indexOf('Other') > -1 
          question.self_report.open_text_option = 'Other'

        subdomain.customizations.user_tags ?= []
        subdomain.customizations.user_tags.push question
        save subdomain
      else 
        _.extend question, 
          view_name: @local.view_name
          visibility: @local.visibility
        _.extend question.self_report,
          question: @local.question
          input: @local.input_type
          options: if @local.input_type != 'text' then @local.options?.split('\n') else null
          required: @local.required

        if question.self_report.options?.indexOf('Other') > -1 
          question.self_report.open_text_option = 'Other'

        subdomain.customizations.user_tags.splice(idx, 1, question)

        save subdomain


      close_modal()

    close_modal = -> 
      intake_q_state.editing = intake_q_state.new_question = false  
      save intake_q_state    


    question_types = [
      {name: 'dropdown', description: 'select one option'}
      {name: 'checklist', description: 'select one or more options'}
      {name: 'text', description: 'open-ended response'}
    ]

    validated = @local.view_name?.length > 0 && @local.question?.length > 0 && @local.input_type?.length > 0 && (@local.input_type == 'text' || @local.options?.length > 0)

    wrap_in_modal DIV null,

      DIV 
        className: 'field'

        LABEL 
          htmlFor: "#name"
          'Name'

        INPUT
          id: '#name'
          type: 'text'
          defaultValue: @local.view_name
          onChange: (e) =>
            @local.view_name = e.target.value
            save @local


      DIV 
        className: 'field'

        LABEL 
          htmlFor: "#question"

          'Your Question'

        INPUT
          id: '#question'
          type: 'text'
          defaultValue: @local.question
          onChange: (e) =>
            @local.question = e.target.value
            save @local

      DIV 
        className: 'field'

        LABEL 
          htmlFor: "#question_type"

          'Question type'

        SELECT
          id: '#question_type'
          type: 'text'
          defaultValue: @local.input_type
          onChange: (e) =>
            @local.input_type = e.target.value
            save @local          
          style: 
            fontSize: 16

          for typ in question_types
            OPTION 
              value: typ.name
              "#{typ.name} – #{typ.description}"


      if @local.input_type in ['dropdown', 'checklist']
        DIV 
          className: 'field'

          LABEL 
            htmlFor: "#responses"

            'Possible responses (1 per line)'

          AutoGrowTextArea
            id: '#responses'
            defaultValue: @local.options
            min_height: 60
            onChange: (e) =>
              @local.options = e.target.value
              save @local


          DIV 
            style: 
              fontSize: 12
              color: '#373737'
            'To add an open-ended response option, include a response named “Other”'



      if @local.input_type != 'text'
        DIV 
          style: 
            marginBottom: 24

          LABEL 
            htmlFor: 'required'
            style: 
              marginBottom: 8

            "Who can see answers to this question?"

          LABEL 
            style: 
              display: 'flex'
              marginBottom: 8

            INPUT 
              name: 'required'
              type: 'radio'
              defaultChecked: @local.visibility == 'host-only'
              className: 'bigger'
              onChange: (e) =>
                @local.visibility = 'host-only'


            SPAN 
              style: 
                paddingLeft: 12
                fontSize: 14

              "Only forum hosts. Responses should not be visible to other participants."

          LABEL 
            style: 
              display: 'flex'

            INPUT 
              name: 'required'
              type: 'radio'
              defaultChecked: @local.visibility == 'open'
              className: 'bigger'
              onChange: (e) =>
                @local.visibility = 'open'

            SPAN 
              style: 
                paddingLeft: 12
                fontSize: 14

              "Hosts and participants. Responses can be used by anyone for opinion filtering."




      LABEL 
        style: 
          display: 'flex'

        INPUT 
          className: 'bigger'
          type: 'checkbox'
          defaultChecked: @local.required
          onChange: (e) =>
            @local.required = e.target.checked

        SPAN 
          style: 
            paddingLeft: 12

          "Participants are "
          B null, "required" 
          " to answer this question"



      DIV 
        style:
          display: 'flex'
          marginTop: 36

        BUTTON 
          className: 'btn'
          onClick: save_question
          disabled: !validated
          style: 
            marginRight: 12
            backgroundColor: if !validated then '#aaa'
            cursor: if !validated then 'not-allowed'

          onKeyPress: (e) -> 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              e.preventDefault()
              save_question()
          'Save'


        BUTTON 
          className: 'like_link'
          onClick: close_modal
          onKeyPress: (e) -> 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              e.preventDefault()
              close_modal()
          'cancel'














drag_icon = (height, color) ->
  width = height * 14 / 20
  SVG 
    viewBox: "0 0 14 20" 
    stroke: 'none'
    fill: color
    width: width
    height: height 

    dangerouslySetInnerHTML: __html: """
      <g>
          <circle id="Oval" cx="2" cy="2" r="2"></circle>
          <circle id="Oval" cx="2" cy="10" r="2"></circle>
          <circle id="Oval" cx="2" cy="18" r="2"></circle>
          <circle id="Oval" cx="12" cy="18" r="2"></circle>
          <circle id="Oval" cx="12" cy="10" r="2"></circle>
          <circle id="Oval" cx="12" cy="2" r="2"></circle>
      </g>
      """


edit_icon = (width, height, color) ->
  SVG 
    viewBox: "0 0 24 24" 
    stroke: color
    fill: 'none'
    width: width
    height: height 

    dangerouslySetInnerHTML: __html: """
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
      """

trash_icon = (width, height, color) ->
  SVG 
    viewBox: "0 0 24 24" 
    stroke: color
    fill: 'none'
    width: width
    height: height 

    dangerouslySetInnerHTML: __html: """
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
      """





