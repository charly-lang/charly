require "./syntax/lexer/location.cr"
require "./error-presenter.cr"

module CharlyExceptions
  abstract class BaseException < Exception
    property location : Location

    def initialize(@location, @message)
    end
  end

  class SyntaxError < BaseException
    def to_s(io)

      io << "SyntaxError in #{(@location.file.try &.filename).colorize(:yellow)}\n"

      # Highlight offensive location
      presenter = ErrorPresenter.new(@location)
      presenter.present(io)

      # Error message
      io << "#{@message}\n"
    end
  end
end
