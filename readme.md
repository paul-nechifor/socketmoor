# Socketmoor

A very basic framework for room-based WebSocket communication meant for games.

Assumptions:

* Users and rooms have an unchangeable unique numeric `id`.

* Users and rooms have a changeable unique string `sid`.

* User `sid`s are unique only in rooms.

* A client can only be present in a single room and must leave it to enter
another.

* Rooms are created when a client wants to enter a rooms that doesn't exit.

* Rooms are destroyed when all clients leave.

## License

MIT
