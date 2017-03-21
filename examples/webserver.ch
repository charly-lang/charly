const http = require("net")
const server = http.create_server("localhost", 8080)

server.on("request", ->(req, res) {
  res.body = req.to_s()
})

server.on("listen", ->{
  print("listening on localhost:8080")
})

server.on("close", ->{
  print("closing server")
})

server.listen()
