# Charly Language Guide (v0.3.0)

Your syntax files need to be encoded in UTF-8.

## Comments

Single-line comment start with `//`. Multiline comments are created via `/*` and `*/`

```javascript
// I'm a comment

/*
  I'm a multiline comment
*/
```

## Variables

Variables are defined via the `let` keyword.
If you try to access a variable that wasn't initialized before, a runtime exception is thrown.

```javascript
let myVar = 25
let myOtherVariable = 50

myVar + myOtherVariable // => 75
```

## Constants

Constants are declared the same way as variables. They can't be changed, hence the name constant.
You need to initialize them in the declaration.

```javascript
const myconst // => syntax error
const myOtherConst = 25
myOtherConst = 30 // => runtime exception
```

## Literals

Charly has a total of 10 primitive types. Not all can be constructed directly.
For example the `TInternalFunction` can only be gathered from a call to `__internal__method`

| Literal                 | Type     |
|-------------------------|----------|
| 25                      | Numeric  |
| 25.5                    | Numeric  |
| "Charly"                | String   |
| [1, 2, 3]               | Array    |
| null                    | Null     |
| NAN                     | Numeric  |
| false                   | Boolean  |
| true                    | Boolean  |
| class Box {}            | Class    |
| func() {}               | Function |
| ->() {}                 | Function |
| { let name = "Charly" } | Object   |

> You can get the type of a value by using the `typeof` operator.
  It returns the name of the type as a string.

```javascript
typeof 25 // => "Numeric"
typeof "hello world" // => "String"
typeof null // => "Null"
typeof func() {} // => "Function"
```

### Null
The `Null` type can be compared to `undefined` in javascript or `nil` in some other languages.

```javascript
null
```

### Boolean
A `Boolean` only has two different values: `true` and `false`.

```javascript
true
false
```

### Numeric
All Numeric types inside Charly are Crystal's native `Float64` type.

Numeric literals, just like any other expression in the language, can be prefixed with `-` to negate them.

Underscores can be used to make some numbers more readable:

```javascript
1_000_000 // better than 1000000
```

Floats are created using the `.` character.

```javascript
123_456.456_789
```

A Numeric will silently overflow if you pass the lower or upper limit of `Float64`.
The following REPL session elaborates this:

![Numeric literal overflowing](images/overflow.png)

Operations such as `1 / 0` will result in the `NAN` value.

### String
A String represents an immutable sequence of UTF-8 characters.

It uses Crystal's native `String` type underneath.

You can create it using `"` characters.

```javascript
"hello world"
```

A backslash can be used to denote various special characters inside the string:

```javascript
"\"" // double quote
"\\" // backslash
"\e" // escape
"\f" // form feed
"\n" // newline
"\r" // carriage return
"\t" // tab
"\v" // vertical tab
```

A string can span multiple lines:

```javascript
"hello
      world" // same as "hello\n     world"
```

### Array
An Array is a resizeable list of items of any type. It is typically created with an array literal:

```javascript
[1, 2, 3]
[1, "hello world", ["whats up"]]
```

You can add new items to an array using the push method:

```javascript
let nums = []
nums.push(0)
nums.push(1)
nums.push(2)

nums // => [0, 1, 2]
```

You can concat two arrays together via the `+` operator:

```javascript
[1, 2] + [3, 4] // => [1, 2, 3, 4]
```

You can compare two arrays using the `==` operator:

```javascript
[1, 2, 3, 4] == [1, 2, 3, 4] // => true
[1, 2] == [3, 4] // => false
```

### Objects

Charly doesn't have special syntax to create objects. Instead it uses something we call `Containers`.

A `Container` is basically the scope of a block turned into an Object:

```javascript
let Box = {
  let name = "Charly"
  let age = 200
}

Box.name // => "Charly"
Box.age // => 200
```

This can be compared to the javascript equivalent of using `new Function()`:

```javascript
let Box = (new function() {
  this.name = "Charly"
  this.age = 200
})

Box.name // "Charly"
Box.age // 200
```

You can access properties of objects via `[]`:

```javascript
let Box = {
  let name = "mybox"
}

Box["name"] // => "mybox"
```

### Functions

You can define a new function like this:

```javascript
func foo() {
  return "hello world"
}
```

The last expression inside a function is used as it's return value

```javascript
func foo() {
  25
}

foo() // => 25
```

You can also do explicit returns

```javascript
func foo() {
  if true {
    return true
  }

  return false
}

foo() // => true
```

If you need the function literal, you can use anonymous function literals:

```javascript
func foo(callback) {
  callback(42)
}

foo(func(arg) {
  print(arg) // => 42
})
```

There is also the lambda syntax, which goes like this:

```javascript
[1, 2, 3].map(->(num) {
  print(num)
})

[1, 2, 3].map(->(num) print(num))
```

Of course you could also pass the print method directly, this would however result in the following:

```javascript
[1, 2, 3].map(print)

/*
  1
  0
  3
  2
  1
  3
  3
  2
  3
*/
```

Because `Array#map` passes the value, index and size of the array to the callback,
print will write all these values to the console.

When you write a lambda function without parenthesis or curly braces, it will wrap the expression inside a block.

The following:

```javascript
foo(->25)
```

becomes:

```javascript
foo(->{ 25 })
```

which in turn get's converted to:

```javascript
foo(func() {
  return 25
})
```

All arguments are also inserted via a quick access identifier.

```javascript
[1, 2, 3].map(->$0 * 2) // => [2, 4, 6]
```

### Classes

Classes in Charly can inherit from multiple other classes.

They can have instance methods and properties and also static methods and properties.

Below is an example of a simple `Person` class.

```javascript
class Person {
  property name
  property age
  property height

  func constructor(name, age, height) {
    @name = name
    @age = age
    @height = height
  }

  func greet() {
    print("My name is " + @name)
    print("I am " + @age + " years old")
    print("I am " + @height + " meters tall")
  }
}

let John = Person("John", 21, 1.85)
John.greet()

/*
  Will print:

  My name is John
  I am 21 years old
  I am 1.85 meters tall
*/
```

You define properties via the `property` keyword followed by an identifier.

To define a static method or property, prefix the property or func keyword with the `static` keyword.

```javascript
class Box {
  static property count

  static func foo() {
    "class method"
  }
}
Box.count = 0

Box.foo() // => "class method"
```

To inherit from other classes, you use the `extends` keyword.

```javascript
class Foo {
  func foo() {
    "foo method"
  }
}

class Bar {
  func bar() {
    "bar method"
  }
}

class Baz extends Foo, Bar {
  func baz() {
    "baz method"
  }
}

let myBaz = Baz()
myBaz.foo() // => "foo method"
myBaz.bar() // => "bar method"
myBaz.baz() // => "baz method"
```

Static properties and methods are also copied to the child classes. The values of static properties are copied by value.
They are not references.

```javascript
class Foo {
  static property foo

  static func what() {
    "static what"
  }
}
Foo.foo = "test"

class Bar extends Foo {}

Bar.what() // => "static what"
Bar.foo // => "test"

Foo.foo = "hello world"

Bar.foo // => "test"
```

## self reference

`@test` will be rewritten to `self.test` by the parser automatically.

The `self` reference always points to the object a method was called on.

```javascript
let myBox = {
  let name;

  func foo() {
    @name
  }
}

myBox.name = "box"
myBox.foo() // => "box"
```

If you directly call a method `foo()`, `self` is set to whatever it what in the context where the method is defined.
Think of it like Arrow Funtions in JavaScript.

```javascript
let Box = {
  let name = "box"

  func foo() {
    return func() {
      print(self.name)
    }
  }
}

let method = Box.foo()
method() // => "box"
```

## Assignments

Assignment is done with the `=` character.

```javascript
// assigns to a local variable
local = 1

// assigns to the current self variable
@instance = 2

// The above is simply rewritten to
self.instance = 2
```

## Control expressions

All control expressions inside Charly behave as if they were normal expressions.

This means that altough you can't place a control expression inside a method call, it will still return a value.

```javascript
func foo(arg) {
  if arg < 25 {
    true
  } else {
    false
  }
}

foo(10) // => true
foo(40) // => false
```

### Truthy and falsey values

A _truthy_ value is a value that is considered true for an `if` and `while` guard.
A _falsey_ value is a value that is considered false in those places.

The only falsey values are `false` and `null`. Any other value is _truthy_.

### if statements

The parenthesis around the test expression are optional

```javascript
if 2 < 5 {
  print("Mathematics still works!")
} else {
  print("Something's off...")
}

if 2 + 2 == 9 - 5 {
  print("Mathematics still works!")
} else {
  print("Somethings's off...")
}
```

For statements which require a value to be falsey, you can use the `unless` statement.

```javascript
unless 2 < 5 {
  print("Something's off...")
}

unless obj.failed() {
  print("Everything worked!")
}
```

Additionally, there is a `guard` statement.

```javascript
let input = "enter your name> ".prompt()

guard input.length() > 0 {
  print("You didn't type anything.")
}

guard false {
  // This block will run
}
```

### switch statements

For more complex branching, you can use the `switch` statement.

```javascript
let num = 25

switch num {
  case 1, 2, 3 {
    print("num is either 1, 2 or 3")
  }

  case 25 {
    print("num is 25")
  }

  default {
    print("num is neither 1, 2, 3 or 25")
  }
}

```

The switch statement can also be inlined.

```javascript
let num = 25

let answer = switch num {
  case 20 {
    "num is 20"
  }

  default {
    "num is not 25"
  }
}
```

The switch statement yields the value of the case statement which was run.

```javascript
func foo(num) {
  switch num {
    case 20 {
      "the argument was 20"
    }

    default {
      "the argument wasn't 20"
    }
  }
}

foo(20) // => "the argument was 20"
foo(25) // => "the argument wasn't 20"
foo(30) // => "the argument wasn't 20"
```

### while statements

The parenthesis around the test expression are optional

```javascript
while true {
  print("and another one")
}

let i = 0
while i < 100 {
  print(i)
  i += 1
}
```

For simple loops that repeat for a fixed amount of time, you are encouraged to use the `Numeric#times` method.

```javascript
5.times(->(i){
  print(i)
})
```

```javascript
5.times(->{
  print("hello world")
})
```

You can break inside a while statement.

```javascript
let i = 0
while true {

  if i >= 100 {
    break
  }

  print(i)

  i += 1
}
```

`continue` is also supported.

```javascript
let i = 0
while i < 50 {

  if i % 2 == 0 {
    i += 1
    continue
  }

  print(i)

  i += 1
}
```

A inverted method of the while loop also exists. The `until` loop runs while the test returns false.

```javascript
let i = 0
until i == 100 {
  i += 1
}

i // => 100
```

To create infinite loops, you can use the `loop` statement.

```javascript
loop {
  print("hello world")
}
```

## Types and methods

The next sections will assume you know what object oriented programming is,
as well as the concepts of classes and methods.

### Everything is an object

Everything in Charly is an object. Not every type can have an internal state however.
Only `Object`, `Class`, `PrimitiveClass` and `Array` can have an internal state.

When you write `5`, the interpreter actually treats it as a primitive.
There are no funny castings or object instantiations (inside Charly). When you write `5.times`,
the interpreter searches for a primitive class called `Numeric` and checks if it contains a method called `times`.

This allows the interpreter to reuse the same object for all primitives of the same type.

This principle applies to all language primitives.
The primitive class `Array` for example, specifies a method called `push` which inserts an element into the array.

### Method arguments

If a method expects to be called with 2 arguments, you have to pass two. If you pass 1 it throws an exception.

```javascript
func foo(a, b, c) {
  return true
}

foo(1, 2, 3) // => true
foo(1, 2, 3, 4) // => true
foo(1, 2) // => runtime exception
```

### Operators

#### Unary operators

```javascript
+   // positive, doesn't do anything right now
-   // negative
!   // not
~   // bitwise NOT
```

#### Binary operators

```javascript
+   // addition
-   // subtraction
*   // multiplication
/   // division
%   // modulo
&   // bitwise and
|   // bitwise or
^   // bitwise xor
**  // exponentiation
<<  // shift left, append
>>  // shift right
==  // equals
!   // not equals
<   // less
<=  // less or equal
>   // greater
>=  // greater or equal
+=  // left = left + right
-=  // left = left + right
*=  // left = left + right
/=  // left = left + right
%=  // left = left + right
**=  // left = left + right
```

#### Indexing

```javascript
[] // array index and object property access
```

## Exceptions

You can throw exceptions from anywhere in the program. Everything is throwable.

```javascript
func foo(arg) {
  if arg < 10 {
    throw Exception("arg is smaller than 10")
  }
}

foo(5)
```

This will show up in the console as:

```
test/debug.ch
      1. func foo(arg) {
      2.   if arg < 10 {
->    3.     throw Exception("arg is smaller than 10")
      4.   }
      5. }
at debug.ch:3:5:5
at foo (debug.ch:7:1:3)
Uncaught Object:Exception: arg is smaller than 10
```

## Requiring files

You can include other files using the `require` method. It accepts a single string argument that serves as the filename.

When including a file, the contents of the `export` variable is then returned by the `require` call.

Example:

__main.ch__

```javascript
let external = require("./external.ch")
print(external.message) // "hello world"
print(external.foo(1, 2)) // 3
```

__external.ch__

```javascript
export = {
  let message = "hello world"

  func foo(l, r) {
    l + r
  }
}
```

If you call require on the same file twice, it will result the value returned by the very first call.

If you call require on a file that was already required before, a cached version will be returned.
The file won't be executed twice.

__main.ch__

```javascript
let external = require("./external.ch")
external.message = "it changed"

let external_second = require("./external.ch")
print(external_second.message) // => "it changed"

external == external_second // => true
```

__external.ch__

```javascript
export = {
  let message = "hello world"
}
```

Recursive `require` call won't be catched or prevented in any way.

## Command line arguments and flags

The `Charly` command has the ability to receive flags.
A list of these can be obtained by running `charly -h` in the command line.

You can pass flags via the following format

```bash
charly input.ch -f lint
```

Arguments which are not flags are passed to the program instead of the interpreter.

```bash
charly input.ch hello -f tokens world 25 25 --foo -b
                ^     ^  ^      ^     ^  ^  ^     ^
                |     |__|      |_____|__|__|_____|
               ARGV     |                |
                      IFLAGS            ARGV
```

You can access command line arguments and flags via the `ARGV` and `IFLAGS` constants.
Current environment variables are available via `ENV`.

```bash
charly input.ch hello -f tokens world 25 25 --foo -b
```

```javascript
ARGV // => ["hello", "world", 25, 25, "--foo", "-b"]
IFLAGS // => ["tokens"]
ENV["TERM"] // => xterm-256color
```

You can see the license and a list of contributors via the following commands

```
$ charly --license
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
```

```
# Contributors
- [Leonard Schütz (Author) @KCreate](https://github.com/KCreate)
- ...
```

## Built-in REPL

Charly has a built-in REPL (Read Eval Print Loop) where you can quickly test out new ideas.

You can invoke it by typing `charly` or `charly repl`

Here you can write Charly statements. Run them by pressing enter.

The REPL provides a few _magic_ variables which are specific to your current REPL session.

- `$` This variable always contains the value of the last evaluated expression
- `history` This is an array of all commands you have entered
- `context` This is the top-level context of the REPL.
- `echo` Boolean value to toggle the echo of entered expressions

## Extending primitive types

Primitives in Charly can be extended as if they were regular objects.
A good example of this is the `Numeric#times` method. It allows you to write really expressive code like this:

```javascript
5.times(->{
  print("Hello!")
})
```

It is implemented like this:

```javascript
Numeric.methods.times = func(callback) {
  let i = 0
  while (i < self) {
    callback(i)
    i += 1
  }

  self
}
```

You can add your own methods to primitive classes via the `Numeric.methods` object.

For arrays you would use `Array.methods`, for strings `String.methods` and so on.

Let's define a `indent` method on strings which takes two arguments, the amount and a filler string.

```javascript
String.methods.indent = ->(amount, filler) {
  @split("\n").each(->(line) {
    (value * amount) + line
  }).join("\n")
}
```

You can now indent strings via the `String#indent` method.

```javascript
"hello\nworld\nwhats\nup".indent(2, "-")

/*
  --hello
  --world
  --whats
  --up
*/
```

## Unit-testing

Charly provides a built-in unit-testing library.
Create a file containing the code below and update the testcases array with
the paths to your test files.

You can then run the test cases with this command: `charly main.ch`.

```javascript
const UnitTest = require("unit-test")

const result = UnitTest(->(describe, it, assert, context) {

  const testcases = [
    ["My test suite", "./mytest.ch"],
    ["My other test suite", "./myothertest.ch"]
  ]

  // Loads and runs all the test cases sequentially
  testcases.each(->(test) {
    const module = require(test[1])
    describe(test[0], ->{
      module(describe, it, assert, context)
    })
  })
})

UnitTest.display_result(result, ->(code) {
  io.exit(code)
})
```

Running this file will output the following:

```bash
$ charly main.ch
Charly [4f4e1bc] Unit Testing Framework
.FFFF.......

Some test suites have failed
1) some behaviour does something else
  Assertion #1
  Expected: false
  Got: true
2) some behaviour some more extended test cases does something
  Assertion #1
  Expected: 4
  Got: 6
```

You can also run a single file directly with the following command: `charly test mytest.ch`

Every file exporting a function taking three arguments can be run as a
test suite. The only pre-requisite is that it follows the schema below:

__mytest.ch__

```javascript
export = ->(describe, it, assert) {

  describe("some behaviour", ->{

    it("should do something", ->{
      assert(25 + 25, 50)
      assert(true, true)
      assert("hello", "hello")
    })

    it("does something else", ->{
      assert(true, false)
    })

    describe("some more extended test cases", ->{

      it("does something", ->{
        assert(2 + 4, 4)
      })

    })

  })

}
```

## IO

Things related to IO and the file system are either directly included in the prelude, or
are available via the `fs` module. The prelude contains bindings to STDIN, STDOUT and STDERR
and also provides some convenience functions to access these files.

```javascript
// newline terminated string to STDOUT
print("hello world")

// non-terminated string to STDOUT
write("hello world")

// read a line from STDIN
// the first argument is the prompt
// the second argument is wether the input should be appended to the history
// this uses libreadline internally
gets("enter: ", false)

// read a single char from STDIN
getc()
```

## Files

Access to the file system is provided via the `fs` module.

```javascript
const fs = require("fs")

let file = fs.open("foo.txt", "w+", "utf8")
file.puts("hello world")
file.close()

// foo.txt
hello world\n
```

See [fs.ch](https://github.com/charly-lang/charly/blob/master/src/std/modules/fs.ch) for a
list of available methods and their documentation.

## Native extensions written in Crystal

Charly currently has rudimentary support for native extensions written in Crystal.

The way this works is via Crystal files that have to be compiled into the interpreter itself.

You can add your own files like this:

1. Create a file called `myfile.cr` inside `src/charly/interpreter/internals`

2. Insert the following code:

```ruby
require "../**"

module Charly::Internals

  charly_api "mymethod", TString do |myarg|
    return TString.new("You said: " + myarg.value)
  end

end
```

3. Recompile & reinstall the interpreter

4. Link against the method inside your Charly program like this:

```javascript
const mymethod = __internal__method("mymethod")

print(mymethod("Hello World")) // => You said: Hello World
```

5. Finished!

___

* Copyright © 2016 - present Leonard Schütz
