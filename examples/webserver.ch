const http = require("net")
const server = http.create_server("localhost", 8080)

let count = 0

server.on("request", ->(req, res) {
  res.body = "" + count
  count += 1

  if count > 10 {
    server.close()
  }
})

server.on("listen", ->{
  print("listening on localhost:8080")
})

server.on("close", ->{
  print("closing server")
})

server.listen()
