# Todos

## Syntax to define own functions
  - return vs last expression
    - return and last expression can be used
    - return should be treated as a function call inside a block
    - return get's then picked up by the interpreter
    - if return is never called, the last expression
        of the block will be used as the return value

## Implement Stacks, each block gets his own stack
  - stacks contain a pointer to their parent stack
  - if a stack doesn't contain a value that is requested, it's checked in the parent
  - function arguments are values that get saved inside a function body block stack
  - stacks are created, destroyed, handled inside run_block

## Boolean types
  - yes / no
  - add comparison operators
    - >
    - <
    - <=
    - >=
    - == (value is equal, strict)
    - =T (same type)
    - ==T (same type and same value, strict)

## If statements
  - blocks
  - else if optional
  - else if OR elsif
  - parens around expressions are obligatory
  - if statements should be treated as expressions,
      with the last expression active inside each of their blocks being their return value (just like in ruby)

## Make sure the parser can work with multiple files.
  - Provide class method to merge arbitrary amounts of syntax trees
  - Implement Deep Copy method (Helper.rb ???)

## Fix weird lexing errors
  - "2-2" -> :NUM :NUM
  - comments???

## Interface to allow calling native interpreter methods
  - native("stdout", "hellloooooo")
