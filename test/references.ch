export = ->(it) {
  it("creates references to variables", func(assert) {
    let string = "hello "
    let reference = &string

    string += "world"

    assert(string, "hello world")
    assert(&reference, "hello world")
    assert(reference.to_s(), "Reference:String")

    &reference = 25

    assert(string, 25)
    assert(reference.to_s(), "Reference:Numeric")
  })

  it("dereferences correctly", func(assert) {
    let string = "test"
    let reference= &string

    assert(reference.typeof(), "Reference")

    reference = 25

    assert(string, "test")
    assert(reference, 25)
  })

  it("passes references to functions", func(assert) {
    let string = "test"
    let reference = &string

    func foo(arg) {
      &arg = 25
    }

    foo(reference)

    assert(string, 25)
  })

  it("puts references into objects", func(assert) {
    let string = "test"
    let container = {
      let string = &string
    }

    string = "hello world"

    assert(container.string.value(), "hello world")

    let reference = container.string

    assert(&reference, "hello world")

    &reference = 25

    assert(string, 25)
    assert(container.string, 25)
  })
}
