const Math = require("math")
const side = "side> ".promptn()

func isOnCircle(x, y, width) {
  const radius = width / 2

  const sideX = (x - radius) ** 2
  const sideY = (y - radius) ** 2
  const diameter = Math.sqrt(sideX + sideY)

  if diameter < radius - radius * 0.1 {
    1
  } else if diameter > radius + radius * 0.1 {
    -1
  } else {
    0
  }
}

side.times(->(y) {
  side.times(->(x) {
    const pos = isOnCircle(x, y, side - 1)

    if pos == 1 {
      write(". ")
    } else if pos == -1 {
      write("  ")
    } else {
      write("# ")
    }
  })

  write("\n")
})
