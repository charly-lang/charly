# Todos

## Implement Stacks, each block gets his own stack
  - stacks are created, destroyed, handled inside run_block

## While Loops
  - Treat as statements
  - Node contains :test, :block
  - Every iteration get's it's own new stack. The last stack is completly thrown away
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

## Rewrite Lexer
  - If 0..n matches, all substrings until 0..n-1 also have to match (this is an issue)
  - Keep on moving the cursor if something doesn't match and the last string wasn't a match

## Rewrite Parser for better efficieny
  - Remove left-recursive rules
  - Better DSL for specifying grammar rules (checking T() over and over again if it matches?)

## Fix weird lexing errors
  - "2-2" -> :NUM :NUM
