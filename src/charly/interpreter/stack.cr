require "./session.cr"
require "./types.cr"

# A single stack containing variables
class Stack
  include CharlyTypes
  property parent : Stack?
  property session : Session
  property values : Hash(HashKey, BaseType)
  property locked : Bool

  def initialize(parent, session)
    @parent = parent
    @session = session
    @values = {} of HashKey => BaseType
    @locked = false
  end

  def to_s(io, all = false)
    stackdump(io, all)
  end

  def stackdump(io, all = false)
    if all
      parent = @parent
      if parent.is_a? Stack
        parent.stackdump(io, all)
      end
    end

    # Display all values as a table
    io << "## Stackdump\n"
    @values.each do |key, value|
      io << depth
      io << " "
      io << self.object_id
      io << " "
      io << "[#{key}]"
      io << " = "
      io << "[#{value}]"
      io << "\n"
    end
  end

  def clear
    @values.clear
  end

  def depth(n = 0)
    parent = @parent
    if parent.is_a? Stack
      return parent.depth(n + 1)
    end
    return n
  end

  def top
    parent = @parent
    if parent.is_a? Stack
      return parent.top
    end
    return self
  end

  def session
    parent = @parent
    if parent.is_a? Stack
      return parent.session
    end
    return @session
  end

  def lock
    @locked = true
  end

  def unlock
    @locked = false
  end

  def write(key, value, declaration = false, check_parent = true)

    # Check if this is a declaration
    if declaration

      # Check if the stack is locked
      if @locked
        raise "Could not write to variable '#{key}', stack is locked!"
      else
        @values[key] = value
        return value
      end
    end

    # Check if the current stack contains the key
    parent = @parent
    if contains key
      @values[key] = value
      return value
    elsif check_parent && parent.is_a?(Stack)
      return parent.write(key, value, false, true)
    else
      raise "Could not write to variable '#{key}', variable wasn't declared!"
    end
  end

  # Get a key from the stack
  # If the key doesn't exist, check the parent stack
  # unless *check_parent* is passed
  def get(key, check_parent = true)
    parent = @parent
    if contains key
      return @values[key]
    elsif check_parent && parent.is_a? Stack
      return parent.get(key)
    else
      raise "Variable '#{key}' is not defined!"
    end
  end

  # Check if the current stack contains a value
  def contains(key)
    return @values.has_key? key
  end

  # Check if the current stack, or any of it's parents stack
  # contain a given key
  def defined(key)
    parent = @parent
    if contains(key)
      return true
    elsif parent.is_a? Stack
      return parent.defined(key)
    else
      return false
    end
  end
end
