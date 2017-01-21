require "./trace.cr"
require "./types.cr"

module Charly
  # `Context` includes data about the current program being executed
  private class Context
    property trace : Array(Trace)
    property cached_files : Hash(String, BaseType)

    def initialize(@trace = [] of Trace)
      @cached_files = {} of String => BaseType
    end
  end
end
