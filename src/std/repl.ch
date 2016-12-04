const context = {
  let $
  const context = self
}

let input

while ((input = "> ".prompt()) ! ".exit") {

  try {
    context.$ = io.eval(input, context)
  } catch(e) {
    context.$ = e
  }

  print(context.$.pretty_print())
}

export = context
