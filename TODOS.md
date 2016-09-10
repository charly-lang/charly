# Todos

## Implement Stacks, each block gets his own stack
  - stacks are created, destroyed, handled inside run_block

## Boolean types
  - add comparison operators
    - &&
    - ||
    - >
    - <
    - <=
    - >=
    - == (value is equal, strict)
    - === (same type)
    - ==== (same type and same value, strict)

## If statements
  - blocks
  - else if optional
  - else if OR elsif
  - parens around expressions are obligatory
  - if statements should be treated as expressions,
      with the last expression active inside each of their blocks being their return value (just like in ruby)

## Fix weird lexing errors
  - "2-2" -> :NUM :NUM
  - comments???
