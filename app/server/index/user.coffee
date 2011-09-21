crypto = require 'crypto'
ck = require 'coffeekup'
mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

config = SS.config

#helpers
doNothing = ()->

flashMessage = (messages)->
  messages = [messages,[messages]][+(typeof messages == 'string')]
  ck.render ()->
    div '.ui-widget.flash',->
      @messages
    div '.ui-widget.flash',->
      @messages
    coffeescript ->
      setTimeout ()->
        $('.flash').fadeOut()
      ,5000
  ,messages:messages.join(',')

#model
model = {}


validatePresenceOf = (value)->
  value && value.length
validatesLengthOfName = (value)->
  20>= value.length >0
validatesLengthOfPassword = (value)->
  64>= value.length >3
validatesFormatOfEmail =(value)->
  /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/
  .test value
validatesUniquenessOf =()->

Auth = new Schema
  name: { type: String }
  email: { type: String,index:{unique:true}}
  hashed_password: { type: String }
  salt: {type: String}
  
Auth.virtual('id').get () -> 
  @_id.toHexString()

Auth.virtual('password').set (password) ->
  @_password = password
  @salt = @makeSalt()
  @hashed_password = @encryptPassword password
.get () -> @_password

Auth.method 'authenticate', (plainText) ->
  @encryptPassword(plainText) is @hashed_password

Auth.method 'makeSalt', () -> 
  Math.round(new Date().valueOf() * Math.random()) + ''

Auth.method 'encryptPassword', (password) ->
  crypto.createHmac('sha1', @salt).update(password).digest 'hex'

Auth.pre 'save', (next) ->
  _error = null
  failed=(errString)->_error=new Error errString
  passed=(str)->
  v = [failed,passed]
  v[+!!validatesLengthOfPassword @password] '密码长度4-64'
  v[+!!validatePresenceOf @password] '请填写密码' 
  v[+!!validatesFormatOfEmail @email] '邮箱格式不正确'
  v[+!!validatePresenceOf @email] '请填写邮箱'
  v[+!!validatesLengthOfName @name] '用户名长度1-20'
  v[+!!validatePresenceOf @name] '请填写用户名' 
  next _error
  console.log 'auth pre saved:'+_error
  
Auth = mongoose.model "Auth", Auth


LoginToken = new Schema
  email: { type: String, index: true }
  series: { type: String, index: true }
  token: { type: String, index: true }

LoginToken.method 'randomToken', ()->
  Math.round((new Date().valueOf() * Math.random())) + ''

LoginToken.pre 'save', (next)->
  @token = @randomToken()
  newSeries = ()=>@series=@randomToken()
  [doNothing,newSeries][+!!@isNew]()
  next()

LoginToken.virtual('id').get ()->
  @_id.toHexString()

LoginToken.virtual('cookieValue').get ()->
  JSON.stringify { email: @email, token: @token, series: @series }
LoginToken = mongoose.model 'LoginToken', LoginToken

  
  
#view
viewHelper = 
  textbox : (attrs) ->
    attrs.type = 'text'
    attrs.name = attrs.id
    input attrs
  passwordbox : (attrs) ->
    attrs.type = 'password'
    attrs.name = attrs.id
    input attrs
    
sessionsView =( ->
  new:->
    h1 @title
    form method: 'post', action: 'login', ->
      textbox id: 'email'
      passwordbox id: 'password'
      button @title
      a '#registlink', href: '#regist', -> '注册'
  create:->
  edit:->
  update:->
  destroy:->
  index:->
  show:->
)()

userView =( ->
  new:->
    h1 @title
    form method: 'post', action: 'register', ->
      textbox id: 'name'
      textbox id: 'email'
      passwordbox id: 'password'
      button @title
      a '#loginlink', href: '#login', -> '登录'
  create:->
  edit:->
  update:->
  destroy:->
  index:->
  show:->
)()



#control helpers
setSession = (s,auth,next)->
  s.setUserId auth.id
  s.attributes = {n:auth.name}
  s.channel.subscribe config.channels.default
  s.save next

#control
exports.actions =
  sessions:(session)->
    view = sessionsView      
    new:(str,next)->
      next 
        command:'login'
        tmpl:ck.render(view.new, title:'登录',hardcode: viewHelper)      
    create:(param,renderView)->
      self = this
      authenticated = (str,auth)->
        loginToken = new LoginToken { email: auth.email }
        setSession session,auth, ()->
          loginToken.save ()->
            renderView
              command:'loggedin'
              tmpl:flashMessage("#{session.attributes.n}，登录成功。")+'<a href="#" onclick="Cafe.userlogout();return false">退出</a>'
              afterCommand:
                name:'setCookie'
                param:
                  name:'logintoken'
                  value:loginToken.cookieValue
                  options:expires:3650
          console.log "user logined #{session.user_id}"
      authFail = (err,next)->
        console.log "login_fail"
        renderView {command:'loginError',tmpl:"用户名或密码不正确，请重新输入"}
      authPassword= (auth,next)->
        next auth.authenticate param.password
      authEmail = (email,next)->
        Auth.findOne {email:email},next
      authEmail param.email,(err,auth)->
        [authFail,authPassword][+!!auth] auth||err||null,(passwordAuthed)->
          [authFail,authenticated][+!!passwordAuthed] '',auth      
    destroy:()->   
  user:(session)->
    view = userView
    new:(str,next)->
      next 
        command:'regist'
        tmpl:ck.render(view.new, title:'注册',hardcode: viewHelper)
    create:(param,renderView)->
      auth = new Auth(param)
      console.log "creating new user: #{param.name} - #{param.email}"
      auth.save (err)->
        console.log "new user #{auth.name} created:"+(+!!err)
        saveSucceed = ()->
          console.log "regist?"+(err ||'noerr')
          loginToken = new LoginToken { email: auth.email }
          setSession session,auth, ()->
            loginToken.save ()->
              renderView
                command:'registed'
                tmpl:flashMessage("#{session.attributes.n}，注册成功。")+'<a href="#" onclick="Cafe.userlogout();return false">退出</a>'
                afterCommand:
                  name:'setCookie'
                  param:
                    name:'logintoken'
                    value:loginToken.cookieValue
                    options:expires:3650
            console.log "user created #{session.user_id}"
        saveFail = ()->
          console.log "registError"
          renderView {command:'registError',tmpl:"#{err}"}
        [saveSucceed,saveFail][+!!err]()
    logintoken:(param,renderView)->
      #console.log "logintoken begin:"+param+';;;'
      self = this
      cookie={email:''}
      cookieToken = null
      authenticated = (str,auth)->
        cookieToken.token = cookieToken.randomToken()
        setSession session,auth,()->
          cookieToken.save ()->
            renderView
              command:'loggedin'
              tmpl:flashMessage("#{session.attributes.n}，欢迎回来～")+'<a href="#" onclick="Cafe.userlogout();return false">退出</a>'
              afterCommand:
                name:'setCookie'
                param:
                  name:'logintoken'
                  value:cookieToken.cookieValue
                  options:expires:3650
            console.log "logintoken#{session.user_id}"
      authFail = (str,next)->
        console.log "logintoken_fail"
        self.new '',renderView
      authFromAuth = (email,next)->
        #console.log "logintoken5"+JSON.stringify(email,null,'\t')
        Auth.findOne email,next
      authFromCookie = (clientcookie,next)->
        cookie = JSON.parse clientcookie
        #console.log "clientcookie:"+cookie
        LoginToken.findOne cookie,next
      cookieFound = ->
        authFromCookie param.logintoken,(err, token)->
          cookieToken = token || null
          [authFail,authFromAuth][+!!token] {email:cookie.email},(err,auth)->
            [authFail,authenticated][+!!auth] '',auth||null
      [authFail,cookieFound][+!!param.logintoken]()

