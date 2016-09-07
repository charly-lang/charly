# Todos
## Rewrite grammar on paper
    - Statements???
    - Functions should be treated as expressions
    - Remove confusion about expressions and terms
    - Every expression can be used inside other expressions
        - NumericLiteral
        - StringLiteral
        - IdentifierLiteral
        - BinaryExpression
        - AssignmentExpression
        - etc ...

## Make sure the parser can work with multiple files.
  - Provide class method to merge arbitrary amounts of syntax trees
  - Implement Deep Copy method (Helper.rb ???)

## Fix comments

## Syntax to define own functions
    - return vs last expression
        - return and last expression can be used
        - return should be treated as a function call inside a block
        - return get's then picked up by the interpreter
        - if return is never called, the last expression
            of the block will be used as the return value

## Interface to allow calling native interpreter methods
    - native("stdout", "hellloooooo")
