require './shared'
require './tooltip'
require './customizations'


# globally accessible method for getting the URL of a user's avatar
window.avatarUrl = (user, img_size) -> 
  user = fetch(user)
  if !!user.avatar_file_name
    app = arest.cache['/application'] or fetch('/application')
    (app.asset_host or '') + \
          "/system/avatars/" + \
          "#{user.key.split('/')[2]}/#{img_size}/#{user.avatar_file_name}"  
  else 
    null


user_name = (user, anon) -> 
  user = fetch user
  if anon || !user.name || user.name.trim().length == 0 
    'Anonymous' 
  else 
    user.name

##########
# Performance hack.
# Was seeing major slowdown on pages with lots of avatars simply because we
# were attaching a mouseover and mouseout event on each and every Avatar for
# the purpose of showing a tooltip name. So we use event delegation instead. 
show_tooltip = (e) ->
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-tooltip')
    user = fetch(e.target.getAttribute('data-user'))

    anonymous = user.key != fetch('/current_user').user && (customization('anonymize_everything') || e.target.getAttribute('data-anonymous') == 'true')

    current_user = fetch('/current_user')
    name = e.target.getAttribute('data-tooltip')
    
    opinion_views = fetch 'opinion_views'

    attributes = get_participant_attributes()
    grouped_by = opinion_views.active_views.group_by

    tooltip = fetch 'tooltip'

    tooltip.render = ->
      DIV 
        style: 
          padding: '8px 4px'
          color: 'white'
          position: 'relative'


        DIV 
          style: 
            display: 'flex'
            alignItems: 'center'

          if user.avatar_file_name
            IMG 
              style: 
                width: 70
                height: 70
                borderRadius: '50%'
                marginRight: 10
                display: 'inline-block' 
              src: avatarUrl user, 'large'

          DIV 
            style: 
              fontFamily: 'Fira Sans Condensed'
              fontSize: 18

            name

        if !anonymous

          UL 
            style:
              listStyle: 'none'
              marginTop: 4

            for attribute in attributes
              is_grouped = grouped_by && grouped_by.name == attribute.name

              user_val = user.tags[attribute.key]

              if typeof user_val == "string" && user_val?.indexOf ',' > -1 
                user_val = user_val.split(',')
              else if is_grouped
                user_val = [user_val]

              continue if !is_grouped && !user_val

              LI 
                style: 
                  padding: '1px 0'

                SPAN 
                  style: 
                    fontFamily: 'Fira Sans Condensed'
                    fontSize: 12
                    # fontStyle: 'italic'
                    paddingRight: 8 
                    textTransform: 'uppercase'   
                    color: '#ccc'              
                  attribute.name 

                for val in user_val
                  SPAN 
                    style: 
                      fontSize: 12
                      color: if is_grouped then get_color_for_group(val or 'Unreported')
                      whiteSpace: 'nowrap'
                      paddingRight: 8
                    val or 'Unreported'


    tooltip.coords = $(e.target).offset()
    tooltip.coords.left += e.target.offsetWidth / 2
    tooltip.tip = name
    save tooltip
    e.preventDefault()





hide_tooltip = (e) ->
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-tooltip')
    if e.target.getAttribute('data-title')
      e.target.setAttribute('title', e.target.getAttribute('data-title'))
      e.target.removeAttribute('data-title')

    clearTooltip()



document.addEventListener "mouseover", show_tooltip
document.addEventListener "mouseout", hide_tooltip

$('body').on 'focusin', '.avatar', show_tooltip
$('body').on 'focusout', '.avatar', hide_tooltip

# focus/blur don't seem to work at document level
# document.addEventListener "focus", show_tooltip, true
# document.addEventListener "blur", hide_tooltip, true


##
# Avatar
# Displays a user's avatar
#
# Higher resolution images are available ('large' and 'original'). These can 
# be specified by setting the img_size property of Avatar.
#
# Additionally, Avatar will automatically upgrade the image resolution if 
# the style specifies a width greater than the size of the thumbnails. 
#
# Avatar will output either a SPAN or IMG. The choice of which tag is used 
# is fraught based upon the browser and how React replaces elements. In the 
# future we can refactor this for a cleaner implementation.
#
# Properties set on Avatar will be transferred to the outputted SPAN or IMG.
#
# Props
#   img_size (default = 'small')
#      The size of the embedded image. 'small' or 'large' or 'original'
#   hide_tooltip (default = false)
#      Suppress the tooltip on hover. 
#   anonymous (default = false)
#      Don't show a real picture and show "anonymous" in the tooltip. 


window.avatar = (user, props) ->
  attrs = _.clone props

  if !user.key 
    if user == arest.cache['/current_user']?.user 
      user = fetch(user)
    else if arest.cache[user]
      user = arest.cache[user]
    else 
      fetch user
      return SPAN null

  attrs.style ?= {}
  style = attrs.style

  # Setting avatar image
  #   Don't show one if it should be anonymous or the user doesn't have one
  #   Default to small size if the width is small  
  anonymous = (user.key != arest.cache['/current_user']?.user) && (attrs.anonymous? && attrs.anonymous) 
  src = null

  if !anonymous && !props.custom_bg_color && user.avatar_file_name 
    if style?.width >= 50 && !browser.is_ie9
      img_size = 'large'
    else 
      img_size = attrs.img_size or 'small'

    src = avatarUrl user, img_size

    # Override the gray default avatar color if we're showing an image. 
    # In most cases the white will allow for a transparent look. It 
    # isn't set to transparent because a transparent icon in many cases
    # will reveal content behind it that is undesirable to show.  
    style.backgroundColor = 'white'
  else if props.set_bg_color && !props.custom_bg_color 
    user.bg_color ?= hsv2rgb(Math.random() / 5 + .6, Math.random() / 8 + .025, Math.random() / 4 + .4)
    style.backgroundColor = user.bg_color

  id = if anonymous 
         "avatar-hidden" 
       else 
         "avatar-#{user.key.split('/')[2]}"

  name = user_name user, anonymous

  if attrs.alt 
    alt = attrs.alt.replace('<user>', name) 
    delete attrs.alt
  else 
    alt = name 

  attrs = _.extend attrs,
    key: user.key
    className: "avatar #{props.className or ''}"
    'data-user': if anonymous then -1 else user.key
    'data-tooltip': if !props.hide_tooltip then alt 
    'data-anon': anonymous  
    tabIndex: if props.focusable then 0 else -1
    width: style?.width
    height: style?.width

  if src
    # attrs.alt = if props.hide_tooltip then '' else tooltip 
    # the above fails too much on broken images, and 
    # screenreaders would probably be overwhelmed with saying all these stances.
    # If in future it turns out we want alt text for accessibility, we can address
    # the broken text ugliness by using img { text-indent: -10000px } to 
    # hide the alt text / broken image
    attrs.alt = ""
    attrs.src = src
    IMG attrs
  else 
    # IE9 gets confused if there is an image without a src
    # Chrome puts a weird gray border around IMGs without a src
    SPAN attrs
  




window.Avatar = ReactiveComponent
  displayName: 'Avatar'
  
  render : ->
    avatar @data(), @props 

       

styles += """
.avatar {
  position: relative;
  vertical-align: top;
  border: none;
  display: inline-block;
  margin: 0;
  padding: 0;
  border-radius: 50%;
  background-size: cover;
  background-color: #{default_avatar_in_histogram_color}; 
  transition: width 750ms, height 750ms, transform 750ms, background-color 750ms, opacity 50ms;
  user-select: none; 
  -moz-user-select: none; 
  -webkit-user-select: none;
  -ms-user-select: none;
}
.avatar.avatar_anonymous {
    cursor: default; 
}
/* for styling icon of broken images */
img.avatar:after { 
  position: absolute;
  z-index: 2;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: #f7954c; 
  border-radius: 50%;
  content: "";
}

"""
