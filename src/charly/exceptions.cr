require "./syntax/location.cr"
require "./error-presenter.cr"

module CharlyExceptions
  abstract class BaseException < Exception
  end

  class SyntaxError < BaseException
    property location : Location

    def initialize(@location, @message)
    end

    def to_s(io)

      io << "SyntaxError in #{(@location.file.try &.filename).colorize(:yellow)}\n"

      # Highlight offensive location
      presenter = ErrorPresenter.new(@location)
      presenter.present(io)

      # Error message
      io << "#{@message}\n"
    end
  end

  class RunTimeError < BaseException
    def to_s(io)
      io << "RunTimeError\n#{@message}\n"
    end
  end
end
