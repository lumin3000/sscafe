ck = require 'coffeekup'
mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

config = SS.config
doNothing = ()->

Chat = ( ->
  historyMessages = []
  limited = 100
  add: (message)->
    [
      doNothing
      ()->historyMessages.shift()
    ][+!!(historyMessages.length>=limited)]()
    historyMessages.push message
  getHistory: ->
    historyMessages
)()

exports.actions =(session)->
  history:(str,next)->
    channel = config.channels.default
    next Chat.getHistory()
  create:(message,next)->
    channel = config.channels.default
    message =  {from: session.attributes.n, message: message,time:"#{new Date().getHours()}:#{new Date().getMinutes()}"}
    Chat.add message
    SS.publish.channel [channel], 'newMessage',[message]
    next true