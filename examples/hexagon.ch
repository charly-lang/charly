let i = gets("> ", false).to_n()
let o = 0
let j = 0

loop {
  (i - 1 - o).n(->write(" "));
  (i + o).n(->write("* "));
  write("\n");

  if j < i - 1 {
    o += 1
  } else {
    o -= 1
  }

  if o < 0 {
    break
  }

  j += 1
}
