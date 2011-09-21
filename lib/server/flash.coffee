ck = require 'coffeekup'

flashMessage = (messages)->
  messages = [messages,[messages]][+(typeof messages == 'string')]
  ck.render
    div '.ui-widget.flash' ->
      messages.join ','

