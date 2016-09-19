[![Build Status](https://travis-ci.com/KCreate/charly-lang.svg?token=yitMwy9Lg5peiAqCZjoK&branch=master)](https://travis-ci.com/KCreate/charly-lang)

# The __Charly__ programming language interpreter

This is my try at writing an interpreter of a dynamic language from scratch with my bare hands.

# Syntax

__Declaring a variable__
```charly
let number = 900;
let float = 5.5928;
let string = "Hello World";
let boolean = true;
let array = [1, "charly", false];
let nullvalue = null;
```

__Declaring a function__
```charly
func callback(value, callback) {
    callback(value);
};

let result = callback(25, func(value) {
    value * 2;
});

result; # => 50
```

__Repeat & While loops__
```charly
repeat(5, func() {
    print("Hello");
});

let i = 0;
while (i < 10) {
    print("In a while loop");
    i = i + 1;
};
```

__User Input__
```charly

# Strings
let input = gets();
print(input);

# Numbers
let input_number = Number(gets());
print(input_number);
```

__Type casting and checking__
```charly
typeof(25); # => Numeric
typeof(25.5); # => Numeric
typeof("Charly"); # => String
typeof([1, 2, 3]); # => Array
typeof(null); # => Null
typeof(false); # => Bool

let number = 25;
print("Number is: " + String(number));
```

Note: The charly interpreter doesn't automatically convert Numerics to Strings.

__Including other files__
```charly
require("external.charly"); # Include a file in the current directory
require("somelibrary"); # Include the main.charly file in the folder somelibrary
require("someotherlibrary"); # Include the someotherlibrary from the standard library
```

__Working with arrays__
```charly
let array = [1, 2, 3];
array = append(array, 4);
print(array); # => 1, 2, 3, 4
```

Note: More documentation about Array methods will work

# CLI options
```
ruby main.rb filename [options...]

<options>
 --log              # Display logging info
 --ast              # Display the abstract syntax tree
 --tokens           # Display a list of tokens found by lexical analysis
 --noexec           # Don't execute the program (Useful if you just want to dump AST's)
 --noopt            # Skip the structurization step in the parser (useful for debugging, but the file probably won't be executable after)
 --nometa           # Hide meta info in the abstract syntax tree
 --noprelude        # Don't load the prelude file (You'll have to load your own standard library yourself)
 --nodeproductions  # Display realtime-information about nodes being produced (laggy af)
 --dump-ast-json    # Dump the Abstract Syntax Tree of all programs in a file called AST.#{filename}.json inside the parser-dump directory
```

# Contributors
- [KCreate - Leonard Schütz](https://github.com/KCreate)

# Inspired by
- Javascript
- C

# License
The MIT License (MIT)
Copyright (c) <2016> Leonard Schütz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
