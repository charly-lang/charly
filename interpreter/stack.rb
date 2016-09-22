require_relative "../misc/Helper.rb"

# A single stack, containing a pointer to it's parent stack
class Stack
  attr_accessor :parent, :values, :program, :session, :locked

  def initialize(parent)
    @parent = parent
    @values = {}
    @program = nil
    @session = nil
    @locked = false
  end

  def clear
    @values = {}
  end

  def depth(n = 0)
    if @parent
      return @parent.depth(n + 1)
    end
    return n
  end

  def top_node
    if @parent
      return @parent.top_node
    end
    return self
  end

  def session
    if @parent
      return @parent.session
    end
    return @session
  end

  # Lock the stack
  def lock
    @locked = true
  end

  # Unlock the stack
  def unlock
    @locked = false
  end

  # Returns the stack for a given identifier
  def stack_for_key(k)
    if @values.key? k
      self
    else
      if @parent != NIL
        @parent.stack_for_key k
      else
        NIL
      end
    end
  end

  def []=(k, d, v)
    if @locked
      raise "Can't write to locked stack!"
    end

    stack = stack_for_key k

    if d
      @values[k] = v
      return
    end

    unless stack == NIL
      stack.values[k] = v
    else
      raise "Can't write to variable '#{k}', not defined!"
    end
  end

  def [](k)
    if @values.key? k
      @values[k]
    else
      unless @parent == NIL
        @parent[k]
      else
        raise "Variable '#{k}' is not defined!"
      end
    end
  end
end
