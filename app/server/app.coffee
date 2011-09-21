# Server-side Code


exports.actions =
  init: (cb) ->
    
    cb "SocketStream version #{SS.version} is up and running."
  router: (commander,commandname,param,cb)->
    app = SS.server.index
    commands =
      user:app.user.user @session
      sessions:app.user.sessions @session
      chat:app.chat @session
    commands[commander][commandname] param,cb