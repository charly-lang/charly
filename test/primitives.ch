export = ->(it) {
  it("added methods have access to the self identifier", ->(assert) {
    Numeric.methods.cube = ->() {
      self * self * self
    }

    assert(5.cube(), 125)
  })

  it("runs in the correct scope", ->(assert) {
    let count = 0
    Numeric.methods.bar = ->() {
      count += 1
    }

    1.bar()
    1.bar()
    1.bar()
    1.bar()
    1.bar()
    1.bar()
    1.bar()

    assert(count, 7)
  })

  it("adds methods to primitive types", ->(assert) {
    Numeric.methods.add = ->(arg) {
      self + arg
    }

    assert(5.add(10), 15)
  })

  it("adds values to primitive types", ->(assert) {
    Numeric.methods.foo = 2

    assert(5.foo, 2)
  })

  it("adds methods via add_method", ->(assert) {
    Numeric.add_method("do_something", ->(arg) {
      "Got: " + arg
    })

    assert(5.do_something(25), "Got: 25")
  })
}
