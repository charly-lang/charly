require "./types.cr"
require "./stack/stack.cr"
require "../file.cr"

class Session
  include CharlyTypes
  property cached_require_calls : Hash(String, BaseType)
  property argv : Array(String)
  property flags : Array(String)
  property file : VirtualFile
  property primitives : Stack
  property prelude : Stack

  def initialize(@argv, @flags, @file, @primitives, @prelude)
    @cached_require_calls = {} of String => BaseType
  end
end
