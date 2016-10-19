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
      io << "#{@message}\n"

      presenter = ErrorPresenter.new(@location)
      presenter.present(io)
    end
  end
end
