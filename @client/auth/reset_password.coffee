require './auth'

window.styles += """

"""

window.ResetPassword = ReactiveComponent
  displayName: 'ResetPassword'

  render: -> 
    i18n = auth_translations()

    form = AuthForm 'reset password', @

    form.Draw 
      task: translator("auth.reset_password.heading", 'Reset Your Password')

      DIV null, 

        DIV
          style:
            color: auth_text_gray
            marginBottom: 18
          i18n.verification_sent_message

        INPUT({name: 'user[verification_code]', disabled: true, style: {display: 'none'}} ) # prevent autofill of code with email address
        INPUT({type: 'password', name: 'user[password]', disabled: true, style: {display: 'none'}} ) # prevent autofill of code with password
        form.RenderInput 
          label: i18n.code_label
          name: 'verification_code'
        form.RenderInput 
          label: translator('auth.reset_password.new_pass', 'New password')
          type: 'password'
          name: 'password'

        form.ShowErrors()

        DIV 
          style: 
            marginTop: 20
            textAlign: 'center'

          TRANSLATE 
            id: "auth.reset_password.help"
            link: 
              component: A
              args: 
                target: '_blank'
                href: 'https://vimeo.com/198802322'
                style: 
                  textDecoration: 'underline'
                  fontWeight: 600

            'Having trouble resetting your password? Watch this brief <link>video tutorial</link>.'
    
