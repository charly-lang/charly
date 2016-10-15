require "./types.cr"

class Session
  include CharlyTypes
  property cached_require_calls : Hash(String, BaseType)
  property argv : Array(String)
  property flags : Array(String)

  def initialize(@argv, @flags)
    @cached_require_calls = {} of String => BaseType
  end
end
