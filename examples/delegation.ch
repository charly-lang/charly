class Box {
  property delegate

  func talk() {
    "The box says: " + @delegate.message()
  }
}

const myBox = Box()

myBox.delegate = {
  func message() {
    "This is being delegated"
  }
}

print(myBox.talk())
