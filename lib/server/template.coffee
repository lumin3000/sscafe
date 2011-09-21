crypto = require 'crypto'
ck = require 'coffeekup'
mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId



#model
model = {}

AuthSchema = new Schema
AuthSchema.add
  name: { type: String }
  email: { type: String,index:{unique:true}}
  hashed_password: { type: String }
  salt: {type: String}
mongoose.model "Auth", AuthSchema
model.auth = db.model "Auth"


#control
control = ()->
  new:()->
  create:()->
  edit:()->
  update:()->
  destroy:()->
  index:()->
  show:()->
  
  
  
#view
view = ->
  new:->
    h1 @title
    coffeescript ->
      alert 'Alerts suck!'
    form method: 'post', action: 'login', ->
      textbox id: 'username'
      textbox id: 'password'
      button @title
  create:->
  edit:->
  update:->
  destroy:->
  index:->
  show:->
  helpers:
    textbox : (attrs) ->
      attrs.type = 'text'
      attrs.name = attrs.id
      input attrs
view = view()


user = ()->
  createUsers:(cb)->
    cb 'createUsers'
  removeUsers:(cb)->
    cb 'removeUsers'
    
module.exports = user()

