/*
 * The stack machine
 * */
class Machine {
  property stack // stack memory
  property memory // heap memory
  property sp // stack pointer

  func constructor(memory_size) {
    @stack = []
    @memory = Array.of_size(memory_size, 0)
    @sp = 0
  }

  /*
   * Loads a number onto the stack
   * */
  func load(num) {
    @stack.push(num)
    @sp += 1
    num
  }

  /*
   * Pops off and returns the top of the stack
   * */
  func pop() {
    const top = @stack.pop()
    @sp -= 1
    return top
  }

  /*
   * Adds the two uppermost values on the stack
   * and pushes the result back onto the stack
   * */
  func add() {
    const right = @pop()
    const left = @pop()
    @load(left + right)
  }

  /*
   * Subtracts the highest value from the second-highest value
   * */
  func sub() {
    const right = @pop()
    const left = @pop()
    @load(left - right)
  }

  /*
   * Prints the top of the stack
   * */
  func print(print) {
    print(@stack.last())
  }

  /*
   * Writes the top value of the stack into the address
   * at the second-highest place of the stack
   * */
  func write() {
    const address = @pop()
    const value = @pop()

    if address < 0 || address > @memory.length() {
      throw Exception("Illegal memory access at address " + address)
    }

    @memory[address] = value
  }

  /*
   * Puts the value in memory at the address given by the top-most value of the stack
   * onto the stack
   * */
  func read() {
    const address = @pop()

    if address < 0 || address > @memory.length() {
      throw Exception("Illegal memory access at address " + address)
    }

    @load(@memory[address])
  }
}

export = Machine
