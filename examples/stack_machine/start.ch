const Assembler = require("./assembler.ch")
let Machine = require("./machine.ch")

const memory_size = 16
const source = "

; Put the value 25 at the address 0
load 25
load 0
write

; Put the value 50 at the address 1
load 50
load 1
write

; Load the values at addresses 0 and 1 and add them together
load 0
read
load 1
read
add

; Print the top of the stack
print

"

Machine = Machine(memory_size)

Assembler().tokenize(source).iterate(->(read) {
  const token = read()

  switch token {
    case "add" {
      Machine.add()
    }

    case "sub" {
      Machine.sub()
    }

    case "load" {
      Machine.load(read())
    }

    case "print" {
      Machine.print(print)
    }

    case "write" {
      Machine.write()
    }

    case "read" {
      Machine.read()
    }

    default {
      throw Exception("Unknown instruction: " + token)
    }
  }
})
