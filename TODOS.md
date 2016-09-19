# Todos

- Function to print the AST of a block at run-time
  - Depth property

- Better unit testing framework
  - Context-specific DSL
  - describe
  - it
  - assert
    - is_equal
    - is_null
    - is_not_null

- More functions for arrays and strings
  - split(string, search) - Split a string into different pieces
    - argument has to be a string containing the haystack
    - if the argument is an empty string, return an array containing each char
  - secure_read(array, index) - Read the property at an index from an array. If the index is out of bounds, return NULL
  - delete(arg) - Returns an array where all values equal to *arg* all removed
  - delete_at(index) - Returns an array where the value at *index* is removed
  - clone(array) - Returns a new array containing copies of all values
  - flatten(array) - returns an flattened array (recursively)
  - index_of(array, value) - returns the index of value inside array

- Math functions
  - Just interface with the native ruby methods

- IO Functions
  - file_get_contents
  - file_write_contents
  - file_append_contents
  - file_accessible
  - file_create

- require(filename)
  - run a given program inside *filename*
  - filename can be a path, relative to the path of the current file
  - if filename is a folder, require main.charly inside that directory
  - if a file was already run, don't run again

- load(filename)
  - the exact same as require(filename) but the file is run again if it was already run before

- global value called ARGV
  - array of strings of arguments passed from the cli

- Parse call expressions correctly
  - a()()() should work
  - a(1)(1)(1) = 25 should work (array syntax)

- Optimize parser (passive long-term goal)
  - Performance is currently pretty fucked up

- Rewrite Lexer
  - Performance is also pretty fucked up
  - If 0..n matches, all substrings until 0..n-1 also have to match (this is an issue)
  - Keep on moving the cursor if something doesn't match and the last string wasn't a match

- Fix weird lexing errors
  - "2-2" -> :NUM :NUM
