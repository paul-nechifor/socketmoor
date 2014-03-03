class Server
  constructor: (@wsAddress, @RoomImpl, @UserImpl) ->
    @ws = new WebSocket @wsAddress
    @listeners = {}
    @calls = {}
    @room = null
    @me = null

  listen: (type, func) ->
    @listeners[type] = func

  setup: (cb) ->
    @listen 'enterRoom', @onEnterRoom.bind this
    @listen 'exitRoom', @onExitRoom.bind this

    @ws.onmessage = @onMessage.bind this
    @ws.onerror = @onError.bind this
    @ws.onclose = @onClose.bind this
    @ws.onopen = cb

  send: (type, msg) ->
    @ws.send JSON.stringify([type, msg])

  call: (type, msg, cb) ->
    callsForType = @calls[type]
    if not callsForType
      callsForType = [cb]
      @calls[type] = callsForType
    else
      callsForType.push cb

    @send type, msg

  onMessage: (event) ->
    [type, msg] = JSON.parse event.data
    listener = @listeners[type]
    return listener msg if listener

    callsForType = @calls[type]
    return if not callsForType or callsForType.length is 0
    head = callsForType.shift()
    head msg

  onError: (event) ->

  onServerError: (msg) ->

  onClose: (event) ->

  enterRoom: (sid) ->
    throw 'You are in a room.' if @room
    @send 'enterRoom', sid

  onEnterRoom: (msg) ->
    if msg.err
      @onServerError msg.err
      return null

    @room = new @RoomImpl this, msg.roomInfo
    @room.createPreviousUsers msg.roomInfo.userInfos, msg.you
    @me = @room.usersById[msg.you]



  exitRoom: ->
    throw 'You are not in a room.' if not @room
    @send 'exitRoom', ''

  onExitRoom: (msg) ->
    if msg.err
      @onServerError msg.err
      return null

    @room.onExit()
    @room = null
    @me = null


class Room
  constructor: (@server, roomInfo) ->
    @id = roomInfo.id
    @sid = roomInfo.sid
    @usersById = {}
    @usersBySid = {}

    @server.listen 'userEnter', @onUserEnter.bind this
    @server.listen 'userExit', @onUserExit.bind this

  createPreviousUsers: (userInfos, you) ->
    for userInfo in userInfos
      @onUserEnter userInfo, userInfo.id is you
    return

  onUserEnter: (userInfo, isMe) ->
    user = new @server.UserImpl this, userInfo, isMe
    @usersById[user.id] = user
    @usersBySid[user.sid] = user
    return user

  onUserExit: (id) ->
    user = @usersById[id]
    delete @usersById[id]
    delete @usersBySid[user.sid]
    return user

  exit: ->
    @server.exitRoom()

  onExit: ->


class User
  constructor: (@room, userInfo, isMe) ->
    @id = userInfo.id
    @sid = userInfo.sid
    @isMe = !!isMe


exports.Server = Server
exports.Room = Room
exports.User = User
