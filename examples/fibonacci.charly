func fib(n) {
  let last = 0
  let curr = 1

  let tmp
  n.times(func() {
    tmp = curr
    curr += last
    last = tmp
  })

  last
}

const n = "Which fibonacci number do you want?: ".promptn()
print(fib(n))
