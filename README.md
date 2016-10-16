[![Build Status](https://travis-ci.com/KCreate/charly-lang.svg?token=yitMwy9Lg5peiAqCZjoK&branch=master)](https://travis-ci.com/KCreate/charly-lang)

<img align="right" alt="Charly" width="150" src="docs/images/charly.png" />

# The Charly programming language
## v0.0.1

This is my try at writing an interpreter of a dynamic language from scratch with my bare hands. It is implemented in [Crystal](https://crystal-lang.org/).

# Syntax

Semicolons are completely optional!

__Declaring a variable__
```charly
let number = 900
let float = 5.5928
let string = "Hello World"
let boolean = true
let array = [1, "charly", false]
let nullvalue = null
let object = {
  let name = "leonard"
  let age = 16
}
```

__Declaring constants__
```charly
const PI = 3.14159265358979323846
const E = 2.7182818284590451

PI = 4 # Cannot redeclare constant PI
```

__Objects__
```charly
let Box = {
  let name = "mybox"
}

Box.name # mybox
Box["name"] # mybox
Box.name = "yourbox"
Box.name # yourbox
Box["name"] # yourbox

Box.age # null
Box["age"] = 16
Box.age # 16
```

__Declaring a function__
```charly
func callback(value, callback) {
  callback(value)
}

let result = callback(25, func(value) {
  value * 2
})

result # => 50
```

__Repeat & While loops__
```charly
5.times(func(i) {
  print("Hello")
})

let i = 0
while (i < 10) {
  print("In a while loop")
  i = i + 1
}
```

__User Input__
```charly
# Strings
let input = gets()
print(input)

# Numbers
let input_number = gets().to_n()
print(input_number)
```

__Primitive types__
```charly
25.type()                           # => Numeric
25.5.type()                         # => Numeric
"Charly".type()                     # => String
[1, 2, 3].type()                    # => Array
null.type()                         # => Null
false.type()                        # => Boolean
(class Box {}).type()               # => Class
(func() {}).type()                  # => Function
{ let name = "charly" }.type()     # => Object
```

__Including other files__
```charly
# Include a file in the current directory
require("external.charly")

# Include the someotherlibrary from the standard library
require("someotherlibrary")
```

__Working with arrays__
```charly
let array = [1, 2, 3]
array.push(4)
print(array) # => [1, 2, 3, 4]
```

__Classes & Objects__
```charly
class Person {
  let name
  let age

  func constructor(name, age) {
    self.name = name
    self.age = age
  }
}

let leonard = Person("Leonard", 16)
print(leonard.name) # "Leonard"
print(leonard.age) # 16
```

__CLI arguments and flags__
You can access flags passed to the interpreter via the global `IFLAGS` array. Flags are stored as a String.
Command line arguments (arguments passed after the filename which are not flags) are available via `ARGV`.

Current environment variables are available via the object `ENV`.

Example:
```
$ charly test.charly 1 2 3 -f ast
```

Will result in:

```charly
ARGV # [1, 2, 3]
IFLAGS # [ast]
ENV["SHELL"] # /bin/bash
ENV.SHELL # /bin/bash
```

# Using the built-in REPL

Currently it's not possible to use the left-arrow or right-arrow keys to position your cursor. I know this sucks and I will change it in the future.

```
$ charly repl
> 2 + 2
4
> "test"
test
> $ * 4
testtesttesttest
> func increment(a) { a + 1 }
Function
> increment(25)
26
> print("hello world")
hello world
null
> .exit
```

# Everything is an object... kind of
When you write `5`, the interpreter actually treats it as a primitive. There are no funny castings or object instantiations. You can normally write code like `2 + 5` and it will work. Once you do something like `5.times(func(){})`, the interpreter searches the current scope for an object called `Numeric` and checks if there is a function called `times` on it. If it finds the method, it injects a variable called `self` into the function's stack and executes it.

This allows the interpreter to reuse the same object for all primitives.

This principle applies to all language primitives. The `Array` object for example, specifies a method called `push` which inserts an element into the array.

# Behaviour of *self* in methods
The self keyword always points to the object a method was called on. Where the method currently lives is not taken into consideration. Example:
```charly
let value = 10

let Box = {
  let value = 10

  func foo(new) {
    self.value = new
  }
}

# Both the outer value and the value inside Box are set to 10

Box.foo(20)
# Outer *value* is still 10, Box.value is now 20

let foo = Box.foo
foo(50)
# Outer *value* is still 10, Box.value is now 50
```

If you directly call method, the interpreter will set *self* to whatever value it was in the scope where the function was defined in. It behaves kind of like [Arrow functions in JavaScript](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Functions/Arrow_functions). This means you can _"extract"_ functions and they keep working the way you expect them to.

Example:
```charly
let Box = {
  let name = "leonard"

  func greet() {
    "Hello " + self.name
  }
}

let greet = Box.greet
print(greet()) # will print Hello leonard
```

This currently only works on objects. If you try to extract a method like *each* from an Array this won't work. This will be fixed in a future release.

# OS Support
I'm developing on macOS 10.12 so it should work without any problems on that.
The [CI Build](https://travis-ci.com/KCreate/charly-lang) runs on Ubuntu 12.04.5 LTS.

# Installation
You will need a working [crystal](http://crystal-lang.org/) installation.

To install the `charly` command and automatically copy it to the `/usr/bin` folder, run `install.sh`.
You will be prompted for your admin password (used to copy to `/usr/bin`).

# CLI options
```
$ charly -h
Usage: charly [options] filename [arguments]
    -f FLAG, --flag FLAG             Set a flag
    -h, --help                       Show this help
    -v, --version                    Show the version number

Flags:
    ast                              Display AST's of parsed programs
    tokens                           Display tokens of parsed programs
    noexec                           Disable execution
    noprelude                        Don't load the prelude file
    stackdump                        Dump the top-level stack at the end of execution
```

# Contributors
- [KCreate - Leonard Schütz](https://github.com/KCreate)

# Inspired by
- Javascript
- C
- Ruby

# License
The MIT License (MIT)

Copyright (c) 2016 Leonard Schuetz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
