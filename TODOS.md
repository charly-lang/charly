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
      with the last expression active inside each of their blocks,
      being their return value (just like in ruby)
  - Even though treated as expression, they shouldn't be allowed where expressions would be allowed (that's just weird)
  - Treat as statements

## While Loops
  - Treat as statements
  - Node contains :test, :block
  - WhileStatement

## For loops (Will be called repeat)
  - will be implemented inside the prelude as a callback based function
  - callback receives argument :index
  - Code-Proposal:
  ```
  func repeat(amount, callback) {
      let i = 0
      while (i < amount) {
        callback(i);
        i = i + 1;
      };
  };
  ```

## Fix weird lexing errors
  - "2-2" -> :NUM :NUM
