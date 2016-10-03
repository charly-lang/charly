require "./session.cr"

# A single stack containing variables
class Stack
  property parent : Stack?
  property session : Session

  def initialize(parent, session)
    @parent = parent
    @session = session
  end
end
