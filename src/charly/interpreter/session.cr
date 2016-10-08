require "./types.cr"

class Session
  include CharlyTypes
  property cached_require_calls : Hash(String, BaseType)

  def initialize
    @cached_require_calls = {} of String => BaseType
  end
end
