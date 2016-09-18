# Todos

## Array syntax
  - Functions inside standard library to get count of elements inside array

## Parse call expressions correctly
  - a()()() should work
  - a(1)(1)(1) = 25 should work (array syntax)

## Rewrite Lexer
  - If 0..n matches, all substrings until 0..n-1 also have to match (this is an issue)
  - Keep on moving the cursor if something doesn't match and the last string wasn't a match

## Fix weird lexing errors
  - "2-2" -> :NUM :NUM
