require_relative "../misc/Helper.rb"
require_relative "../misc/Location.rb"

# Performs Lexical Analysis
class Lexer

  def self.rules
    [
      [:COMMENT,      /\A#.*\Z/],
      [:KEYWORD,      /\A(let|func|if|else)\Z/],
      [:NUMERICAL,    /\A-?\d+(\.)?(\d+)?\Z/],
      [:STRING,       /\A"(""|[^"])*"?\Z/],
      [:BOOLEAN,      /\A(true|false)\Z/],
      [:ASSIGNMENT,   /\A\=\Z/],
      [:PLUS,         /\A\+\Z/],
      [:MINUS,        /\A\-\Z/],
      [:MULT,         /\A\*\Z/],
      [:DIVD,         /\A\/\Z/],
      [:MODULUS,      /\A\%\Z/],
      [:POW,          /\A\*\*\Z/],
      [:TERMINAL,     /\A;\Z/],
      [:COMMA,        /\A,\Z/],
      [:IDENTIFIER,   /\A(\w|_)+\Z/],
      [:LEFT_PAREN,   /\A\(\Z/],
      [:RIGHT_PAREN,  /\A\)\Z/],
      [:LEFT_CURLY,   /\A\{\Z/],
      [:RIGHT_CURLY,  /\A\}\Z/],
      [:WHITESPACE,   /\A\s+\Z/]
    ]
  end

  # Returns all tokens inside "file"
  def self.analyse(file)

    input = file.content

    tokens = []

    # Read chars until nothing matches anymore
    cursor = 0
    forward = 1
    tokens = []
    line = 1
    while cursor < input.length do

      # Don't scan outside the bounds of the string
      if (cursor + forward) > input.length
        break
      end

      # Once a token doesn't match anymore
      if !identifiable?(input[cursor, forward])

        # Increment line number if a newline is recognized
        if input[[cursor - 1, 0].max, 1] == "\n" || input[[cursor - 2, 0].max, 2] == "\r\n"
          line += 1
        end

        substring = input[cursor, forward - 1]
        token = identify(substring, line, file)

        if token.nil?
          raise "Could not parse input: (#{substring})"
        end

        tokens << token

        cursor = cursor + forward - 1
        forward = 1
        next
      end

      # If identifiable and we reached the end of the file
      if identifiable?(input[cursor, forward]) && (cursor + forward + 1) > input.length
        token = identify(input[cursor, forward], line, file)
        tokens << token

        cursor = cursor + forward + 1
        forward = 1
        next
      end

      forward += 1
    end

    tokens
  end

  def self.identify(input, line, file)
    rules.each do |r|
      if input =~ r[1]

        # Strip whitespace from tokens where whitespace can be ignored
        if r[0] != :WHITESPACE
          input.strip!
        end

        # Strip quotes from parsed strings
        # Also replace escaped double quotes
        if r[0] == :STRING
          input = input[1..-2]
          input.split()
        end

        return Token.new(r[0], input, Location.new(file, line))
      end
    end

    nil
  end

  def self.identifiable?(input)
    rules.each do |r|
      if input =~ r[1]
        return true
      end
    end

    false
  end
end

# A single token returned by the Lexer
class Token
  attr_reader :token, :value, :location

  def initialize(token, value, location)
    @token = token
    @value = value
    @location = location
  end

  def to_s
    "(#{location}) #{'%-11.11s' % @token} │#{@value}│"
  end
end
