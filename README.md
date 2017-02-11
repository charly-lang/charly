[![Build Status](https://travis-ci.org/charly-lang/charly.svg?branch=master)](https://travis-ci.org/charly-lang/charly)
[![Version](https://img.shields.io/badge/Version-0.3.0-green.svg)](https://github.com/charly-lang/charly/releases/tag/v0.3.0)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/charly-lang/charly/blob/master/LICENSE)

<img align="right" alt="Charly" width="150" src="res/charly.png" />

# The Charly programming language

This is my try at writing an interpreter of a dynamic language from scratch with my bare hands. It is implemented in [Crystal](https://crystal-lang.org/). It is absolutely not production-ready and is meant only for my own learning-purposes.

# Syntax and language guide

Take a look at the [official website](https://charly-lang.github.io/charly/) for an introduction to the language.

# Using the built-in REPL

You can use the arrow keys to navigate the cursor. Up and down will scroll through the history.

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

If you need to pass arguments or flags to a REPL session you can do so via the repl command
```
$ charly repl these are all arguments
```

```javascript
> ARGV
[these, are, all, arguments]
```

# OS Support
I'm developing on macOS 10.12 so it should work without any problems on that.
The [CI Build](https://travis-ci.com/charly-lang/charly) runs on Ubuntu 12.04.5 LTS.

# Installation
1. Install [Crystal](https://crystal-lang.org)
2. Clone this repo (`git clone https://github.com/charly-lang/charly`)

3. Run `install.sh`

You will be prompted for your admin password (used to copy to `/usr/local/bin`).

After that you need to set the `CHARLYDIR` environment variable. Just add the following line to your
`.bashrc`, `.zshrc`, etc. Replace the path with the path to the Charly source code (e.g The path to the git repo).

```bash
export CHARLYDIR=~/GitHub/charly-lang/charly
```

You can also build the interpreter via the following command:

```bash
$ mkdir bin
$ crystal build src/charly.cr --release -o bin/charly
```

This will place the executable in the `bin` folder.

# CLI options
```
$ charly -v
Charly 0.3.0 [ee05bdf] (11. February 2017)

$ charly -h
Usage: charly [filename] [flags] [arguments]
    -f FLAG, --flag FLAG             Set a flag
    -h, --help                       Print this help message
    -v, --version                    Prints the version number
    --license                        Prints the license

Flags:
    ast                              Display the AST of the userfile
    dotdump                          Dump dot language displaying the AST
    tokens                           Display tokens of the userfile
    lint                             Don't execute after parsing (linting)

29 internal methods are loaded
```

# [License](https://github.com/charly-lang/charly/blob/master/LICENSE)
