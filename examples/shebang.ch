#!/usr/local/bin/charly

print("This is executed directly")
print("You passed these arguments: ")

ARGV.each(->(arg) {
  print("  - " + arg)
})
