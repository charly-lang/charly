class Assembler {
  property tokens
  property source
  property pos
  property buffer

  func constructor() {
    @tokens = []
    @token = null
    @source = ""
    @pos = 0
    @buffer = ""
  }

  func setup(source) {
    @tokens = []
    @source = source
    @pos = 0
  }

  func tokenize(source) {
    @setup(source)

    while @pos < @source.length() {
      @read_token().tap(->(token) {
        if token {
          @tokens.push(token)
        }
      })
    }

    @tokens
  }

  func read_token() {
    let char = @current_char()

    guard typeof char == "String" {
      return false
    }

    if char == " " || char == "\n" {
      @read_char()
      return false
    }

    if char == ";" {
      until @read_char() == "\n" {}
      @read_char()
      return false
    }

    if char.digit() {
      return @read_numeric()
    }

    switch char {
      case "a" {
        if @read_char() == "d" && @read_char() == "d" {
          @read_char()
          return "add"
        } else {
          throw Exception("Invalid instruction, expected add")
        }
      }

      case "s" {
        if @read_char() == "u" && @read_char() == "b" {
          @read_char()
          return "sub"
        } else {
          throw Exception("Invalid instruction, expected sub")
        }
      }

      case "r" {
        if @read_char() == "e" && @read_char() == "a" && @read_char() == "d" {
          @read_char()
          return "read"
        } else {
          throw Exception("Invalid instruction, expected read")
        }
      }

      case "w" {
        if @read_char() == "r" && @read_char() == "i" && @read_char() == "t" && @read_char() == "e" {
          @read_char()
          return "write"
        } else {
          throw Exception("Invalid instruction, expected write")
        }
      }

      case "p" {
        switch @read_char() {
          case "o" {
            if @read_char() == "p" {
              @read_char()
              return "pop"
            } else {
              throw Exception("Invalid instruction, expected pop")
            }
          }

          case "r" {
            if @read_char() == "i" && @read_char() == "n" && @read_char() == "t" {
              @read_char()
              return "print"
            } else {
              throw Exception("Invalid instruction, expected pop")
            }
          }

          default {
            throw Exception("Invalid instruction, expected either pop or print")
          }
        }
      }

      case "l" {
        if @read_char() == "o" && @read_char() == "a" && @read_char() == "d" {
          @read_char()
          return "load"
        } else {
          throw Exception("Invalid instruction, expected load")
        }
      }
    }

    print(char.ord())

    throw "Unrecognized char: " + char
  }

  func read_char() {
    @source[@pos + 1].tap(->{
      @pos += 1
    })
  }

  func current_char() {
    @source[@pos]
  }

  func read_numeric() {
    @buffer = ""

    loop {
      const char = @current_char()

      if typeof char ! "String" {
        @read_char()
        break
      }

      if char.digit() {
        @buffer += char
        @read_char()
      } else {
        break
      }
    }

    const numeric_value = @buffer.to_n().tap(->{
      @buffer = ""
    })

    return numeric_value
  }
}

export = Assembler
