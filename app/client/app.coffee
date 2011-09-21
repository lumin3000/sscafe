# Client-side Code
SS.socket.on 'disconnect', ->  $('#message').text('SocketStream server is down :-(')
SS.socket.on 'reconnect', ->   $('#message').text('SocketStream server is up :-)')

window.Client = ()->
  getCookie:(options)->
     $.cookie options.name
  setCookie:(options)->
    console.log JSON.stringify options
    $.cookie options.name,options.value,options.options
  removeCookie:(options)->
    $.cookie options.name,null

window.Client = window.Client()

top.Cafe = ()->
  initChat:()->
    renderMessage = (msgObj) ->
      $.each msgObj,(idx,el)->
        $("<p><small>#{el.time}</small> #{el.from}:#{el.message}</p>").hide().appendTo('#chatlog').slideDown()
    callServer 'chat','history','',renderMessage
    $('#demo').css 'display','block'
    SS.events.on 'newMessage', renderMessage
    $('#demo').show().submit ->
      message = $('#myMessage').val()
      if message.length > 0
        callServer 'chat','create',message,(success)->
          if success then $('#myMessage').val('') else alert('Unable to send message')
      else
        alert('Oops! You must type a message first')
  drawLoginOrApp:(res)->
    commands = 
      registed:(tmpl,command)=>
        $('#testArea').html tmpl
        Client[command.name] command.param
        Cafe.initChat()
      regist:(tmpl,command)->
        $('#testArea').html tmpl
        $('#testArea form').submit ()->
          callServer 'user','create',$(this).serializeJSON(),Cafe.drawLoginOrApp
          false
        $('#loginlink').click ()->
          callServer 'sessions','new','',Cafe.drawLoginOrApp
          false
      registError:(tmpl,command)->
        alert tmpl
      loggedin:(tmpl,command)=>
        $('#testArea').html tmpl
        Client[command.name] command.param
        Cafe.initChat()
      login:(tmpl,command)->
        $('#testArea').html tmpl
        $('#testArea form').submit ()->
          callServer 'sessions','create',$(this).serializeJSON(),Cafe.drawLoginOrApp
          false
        $('#registlink').click ()->
          callServer 'user','new','',Cafe.drawLoginOrApp
          false
      loginError:(tmpl,command)->
            alert tmpl
    commands[res.command] res.tmpl,res.afterCommand||null
  userlogout:->
    $.cookie 'logintoken',null
    top.location.reload()
  init:->
    callServer 'user','logintoken',{logintoken:$.cookie 'logintoken'},Cafe.drawLoginOrApp
  
  
top.Cafe = top.Cafe()



exports.init = ->
  SS.events.on 'callclient',(command)->
    console.log 'command:'+command
    command = JSON.parse command
    Client[command.name] command.param
    
  SS.server.app.init (response) ->
    $('#message').text(response)
    window.callServer = SS.server.app.router
    Cafe.init()
    