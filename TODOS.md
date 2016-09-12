# Todos

## Implement Stacks, each block gets his own stack
  - stacks are created, destroyed, handled inside run_block

## Rewrite Lexer
  - If 0..n matches, all substrings until 0..n-1 also have to match (this is an issue)
  - Keep on moving the cursor if something doesn't match and the last string wasn't a match

## Rewrite Parser for better efficieny
  - Remove left-recursive rules
  - Better DSL for specifying grammar rules (checking T() over and over again if it matches?)
  - Implement a way to specify an empty token
  - Group together productions that start with the same tokens
  - Implement some kind of heuristics so that nodes that are more often used get checked first

## Fix weird lexing errors
  - "2-2" -> :NUM :NUM
