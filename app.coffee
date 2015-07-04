app = require("http").createServer(handler)
io = require("socket.io").listen(app)
fs = require("fs")
path = require "path"
url = require "url"

handler = (req, res) ->
    pathname = url.parse(req.url).pathname
    pathname = if pathname is "/" then "/index.html" else pathname
    pathname = pathname.replace /[\.\/]/g, ""
    filePath = path.join(__dirname, "/static/", pathname)

    fs.readFile __dirname + "/static/index.html", (err, data) ->
        if err
            res.writeHead 500
            return res.end("Error loading index.html")

        res.writeHead 200
        res.end data
        return
    return

app.listen 8181
contents = {}
io.sockets.on "connection", (socket) ->
    myRoomId = null

    socket.once "join", (data) ->
        return if data.roomId in [null, undefined, ""]

        myRoomId = data.roomId
        isNewUser = contents[myRoomId] is undefined

        unless contents[myRoomId]?
            unless data.code in [null, undefined, ""]
                contents[myRoomId] = data.code
            else
                contents[myRoomId] = "# Hello CoffeeScript"

        socket.emit "joined", {
            rooms   : Object.keys(contents)
            code    : contents[myRoomId]
        }

        if isNewUser
            socket.broadcast.emit "userJoined", {roomId: myRoomId}
            console.log "\u001b[36m[connection]\u001b[mnew client connected. (room: #{myRoomId})"
        else
            console.log "\u001b[36m[connection]\u001b[mclient reconnected. (room: #{myRoomId})"

        return

    socket.on "requestBody", (req) ->
        return unless contents[req.roomId]?

        socket.emit "bodyResponse", {
            roomId  : req.roomId
            code    : contents[req.roomId]
        }
        return

    socket.on "update", (req) ->
        # console.log "\u001b[32m#{myRoomId} update code.\u001b[m"
        contents[myRoomId] = req.code
        io.sockets.emit "updateOther", {roomId: myRoomId}
        return

    socket.on "teardown", (req) ->
        delete contents[req.roomId]
        io.sockets.emit "teardown room", {roomId: req.roomId}
        return

    return

console.log "Initialized."
