# Todos

## Array syntax
  - Introduce two new terminals called :LEFT_BRACKET & :RIGHT_BRACKET
  - Functions inside standard library to get count of elements inside array
  - Get value by index like this `[1, 2, 3](2) => 3`
  - Parsed as `term(:LEFT_BRACKET) && EL() && term(:RIGHT_BRACKET)`

## Rewrite Lexer
  - If 0..n matches, all substrings until 0..n-1 also have to match (this is an issue)
  - Keep on moving the cursor if something doesn't match and the last string wasn't a match

## Fix weird lexing errors
  - "2-2" -> :NUM :NUM
