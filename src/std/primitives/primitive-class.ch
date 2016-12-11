export = primitive class PrimitiveClass {
  func pretty_print() {
    @to_s().colorize(35)
  }

  # Add a new method to this primitive
  func add_method(name, method) {
    if name.typeof() ! "String" {
      throw Exception("Expected string as first argument, got " + object.typeof())
    }

    if method.typeof() ! "Function" {
      throw Exception("Expected function as second argument, got " + object.typeof())
    }

    @methods[name] = method
  }
}
