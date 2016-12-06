const context = {
  let $
  const context = self
  const history = []
}

let input

while ((input = "> ".prompt()) ! ".exit") {

  try {
    context.$ = io.eval(input, context)
  } catch(e) {
    context.$ = e
  }

  print(context.$.pretty_print())

  context.history.push(input)
}

export = context
