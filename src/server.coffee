WsServer = require('ws').Server

class Server
  constructor: (@httpServer, @RoomImpl, @UserImpl) ->
    @wss = new WsServer server: @httpServer
    @wss.on 'connection', @onConnection.bind this
    @roomsById = {}
    @roomsBySid = {}
    @bystanders = {} # Users who aren't in a room.
    @lastUserId = 0
    @lastRoomId = 0

  onConnection: (ws) ->
    id = @lastUserId++
    user = new @UserImpl id, ws, this
    @bystanders[id] = user
    user.open()

  getOrCreateRoom: (sid) ->
    room = @roomsBySid[sid]
    return room if room
    room = new @RoomImpl this, @lastRoomId++, sid
    @roomsById[room.id] = room
    @roomsBySid[room.sid] = room
    return room

  onUserEnterRoom: (user) ->
    delete @bystanders[user.id]

  onUserExitRoom: (user) ->
    @bystanders[user.id] = user

  onUserQuit: (user) ->
    delete @bystanders[user.id]

  closeRoom: (room) ->
    delete @roomsById[room.id]
    delete @roomsBySid[room.sid]


class Room
  constructor: (@server, @id, @sid) ->
    @usersById = {}
    @usersBySid = {}
    @nUsers = 0

  onUserEnter: (user) ->
    @server.onUserEnterRoom user
    user.uniqueifySidForRoom this
    @usersById[user.id] = user
    @usersBySid[user.sid] = user
    @nUsers++
    @sendToRest 'userEnter', user.getUserInfo(), user.id

  onUserExit: (user) ->
    delete @usersById[user.id]
    delete @usersBySid[user.sid]
    @nUsers--
    @server.onUserExitRoom user
    if @nUsers is 0
      @server.closeRoom this
    else
      @sendToAll 'userExit', user.id

  sendToAll: (type, msg) ->
    for id, user of @usersById
      user.send type, msg
    return

  sendToRest: (type, msg, exceptId) ->
    for id, user of @usersById
      user.send type, msg unless user.id is exceptId
    return

  getRoomInfo: ->
    id: @id
    sid: @sid
    userInfos: @getUserInfos()

  getUserInfos: ->
    for id, user of @usersById
      user.getUserInfo()


class User
  constructor: (@id, @ws, @server) ->
    @sid = 'user-' + @id
    @room = null
    @isClosing = false
    @listeners = {}

  listen: (type, func) ->
    @listeners[type] = func

  open: ->
    @listen 'enterRoom', @onEnterRoom.bind this
    @listen 'exitRoom', @onExitRoom.bind this

    @ws.onmessage = @onMessage.bind this
    @ws.onerror = @onError.bind this
    @ws.onclose = @onClose.bind this

  close: ->
    return if @isClosing
    @isClosing = true
    @onExitRoom()
    @server.onUserQuit this
    @ws.close()

  send: (type, msg, cb) ->
    @ws.send JSON.stringify [type, msg], cb

  # Change the name of this user such that it is unique for the room.
  uniqueifySidForRoom: (room) ->
    # TODO

  onMessage: (event) ->
    [type, msg] = JSON.parse event.data
    listener = @listeners[type]
    return listener msg if listener

  onClose: (event) ->
    @close()

  onError: (event) ->
    console.error 'socket-error', event

  onEnterRoom: (sid) ->
    if @room
      @send 'enterRoom', err: 'You *are* in a room.'
      return

    @room = @server.getOrCreateRoom sid
    @room.onUserEnter this
    @send 'enterRoom', { roomInfo: @room.getRoomInfo(), you: @id }

  onExitRoom: ->
    return if not @room
    @room.onUserExit this
    @room = null

  getUserInfo: ->
    id: @id
    sid: @sid


exports.Server = Server
exports.Room = Room
exports.User = User
