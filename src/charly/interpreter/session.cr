require "./types.cr"
require "../file.cr"

class Session
  include CharlyTypes
  property cached_require_calls : Hash(String, BaseType)
  property argv : Array(String)
  property flags : Array(String)
  property file : VirtualFile

  def initialize(@argv, @flags, @file)
    @cached_require_calls = {} of String => BaseType
  end
end
