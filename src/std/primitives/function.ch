export = primitive class Function {
  func mid(callback) {
    func() {
      callback(self, arguments)
    }
  }

  func pretty_print() {
    @to_s().colorize(34)
  }
}
