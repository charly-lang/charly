require "../syntax/ast.cr"
require "./stack/stack.cr"
require "./types.cr"
require "./session.cr"
require "./event.cr"
require "./internal-functions.cr"

# Execute the AST by recursively traversing it's nodes
class Interpreter
  include CharlyTypes
  include CharlyExceptions

  property initial_stack : Stack
  property program_result : BaseType
  property session : Session

  def initialize(program, stack, session)
    @initial_stack = stack
    @session = session
    @program_result = exec_program(program, stack)
  end

  # Executes *program* inside *stack*
  def exec_program(program, stack)
    global = TObject.new(stack)
    stack.write("self", global, declaration: true, constant: true, force: true)
    stack.write("program", global, declaration: true, constant: true, force: true)
    stack.write("export", TNull.new, declaration: true)

    begin
      exec_block(program.children[0], stack)
    rescue e : Events::Return
      raise RunTimeError.new("Invalid return statement")
    rescue e : Events::Break
      raise RunTimeError.new("Invalid break statement")
    rescue e : Events::Exit
      code = e.payload

      if code.is_a? TNumeric
        exit code.value.to_i
      else
        exit 0
      end
    end
  end

  # Executes *node* inside *stack*
  def exec_block(node, stack)
    last_result = TNull.new
    node.children.each do |expression|
      last_result = exec_expression(expression, stack)
    end
    last_result
  end

  # Executes *node* inside *stack*
  def exec_expression(node, stack)

    if node.is_a? VariableDeclaration
      return exec_variable_declaration(node, stack)
    end

    if node.is_a? VariableInitialisation
      return exec_variable_initialisation(node, stack, constant: false)
    end

    if node.is_a? ConstantInitialisation
      return exec_variable_initialisation(node, stack, constant: true)
    end

    if node.is_a? VariableAssignment
      return exec_variable_assignment(node, stack)
    end

    if node.is_a? UnaryExpression
      return exec_unary_expression(node, stack)
    end

    if node.is_a? BinaryExpression
      return exec_binary_expression(node, stack)
    end

    if node.is_a? ComparisonExpression
      return exec_comparison_expression(node, stack)
    end

    if node.is_a? And
      return exec_and(node, stack)
    end

    if node.is_a? Or
      return exec_or(node, stack)
    end

    if node.is_a? IdentifierLiteral
      return exec_identifier_literal(node, stack)
    end

    if node.is_a? CallExpression
      return exec_call_expression(node, stack)
    end

    if node.is_a? MemberExpression
      return exec_member_expression(node, stack)
    end

    if node.is_a? IndexExpression
      return exec_index_expression(node, stack)
    end

    if node.is_a? IfStatement
      return exec_if_statement(node, stack)
    end

    if node.is_a? WhileStatement
      return exec_while_statement(node, stack)
    end

    if node.is_a? NumericLiteral
      return exec_literal(node, stack)
    end

    if node.is_a? StringLiteral
      return exec_literal(node, stack)
    end

    if node.is_a? BooleanLiteral
      return exec_literal(node, stack)
    end

    if node.is_a? FunctionLiteral
      return exec_literal(node, stack)
    end

    if node.is_a? ArrayLiteral
      return exec_literal(node, stack)
    end

    if node.is_a? ClassLiteral
      return exec_literal(node, stack)
    end

    if node.is_a? ContainerLiteral
      return exec_container_literal(node, stack)
    end

    if node.is_a? ReturnStatement
      return exec_return_statement(node, stack)
    end

    if node.is_a? BreakStatement
      return exec_break_statement(node, stack)
    end

    if node.is_a? ThrowStatement
      return exec_throw_statement(node, stack)
    end

    if node.is_a? TryCatchStatement
      return exec_try_catch(node, stack)
    end

    if node.is_a? NullLiteral
      return TNull.new
    end

    if node.is_a? NANLiteral
      return TNumeric.new(Float64::NAN)
    end

    raise RunTimeError.new("Unknown node encountered #{node} #{stack}")
  end

  # Initializes a variable in the current stack
  # The value is set to TNull
  def exec_variable_declaration(node, stack)
    value = TNull.new
    stack.write(node.identifier.name, value, true)
    return value
  end

  # Saves value to a given variable in the current stack
  def exec_variable_initialisation(node, stack, constant = false)

    # Resolve the value
    value = exec_expression(node.expression, stack)
    stack.write(node.identifier.name, value, declaration: true, constant: constant)
    return value
  end

  # Assign the result of an expression to a variable
  # in the current stack
  def exec_variable_assignment(node, stack)

    # Resolve the expression
    value = exec_expression(node.expression, stack)

    # Check if this is a member expression
    identifier = node.identifier
    if identifier.is_a? MemberExpression

      # Get some values
      member = identifier.member
      identifier = identifier.identifier

      # Resolve the identifier
      identifier = exec_expression(identifier, stack)

      # Only TObjects are allowed
      unless identifier.is_a?(TObject)
        raise RunTimeError.new("#{identifier} is not an object")
      end

      identifier.stack.write(member.name, value, true, false)
      return value
    elsif identifier.is_a? IndexExpression

      # Get some values
      member = identifier.argumentlist
      identifier = identifier.identifier

      # Resolve the identifier
      identifier = exec_expression(identifier, stack)

      # Only TArray and TString allowed
      if identifier.is_a? TArray

        # Check that there is at least 1 expression
        unless member.children.size > 0
          raise RunTimeError.new("Missing index for array index expression")
        end

        # Resolve the member
        member = exec_expression(member.children[0], stack)

        # Typecheck the member
        if member.is_a?(TNumeric)

          # Out-of-bounds check
          if member.value < 0 || member.value > identifier.value.size - 1
            raise RunTimeError.new("Index out of bounds!")
          end

          # Write to the index
          identifier.value[member.value.to_i64] = value
          return value
        else
          raise RunTimeError.new("Can't use #{member} in array index expression.")
        end
      end

      # Search for the the __member function
      prop = redirect_property(identifier, "__member_write", stack)
      if prop.is_a? TFunc

        # Resolve all children
        arguments = [] of BaseType
        member.children.each do |child|
          arguments << exec_expression(child, stack)
        end
        arguments << value

        # Execute the __member function
        return exec_function(prop, arguments, identifier)
      end
    elsif identifier.is_a?(IdentifierLiteral)
      stack.write(identifier.name, value)
    end

    return value
  end

  # Extracts the value of a variable from the current stack
  def exec_identifier_literal(node, stack)
    stack.get(node.name)
  end

  def exec_unary_expression(node, stack)

    # Resolve the right side
    right = exec_expression(node.right, stack)

    # Search for a operator overload on comparison expressions
    operator_name = case node.operator
    when TokenType::Minus
      "__uminus"
    when TokenType::Not
      "__unot"
    else
      nil
    end

    if operator_name.is_a? String
      prop = redirect_property(right, operator_name, stack)
      if prop.is_a? TFunc
        return exec_function(prop, [] of BaseType, right)
      end
    end

    case node.operator
    when TokenType::Minus
      if right.is_a? TNumeric
        return TNumeric.new(-right.value)
      end
    when TokenType::Not
      return TBoolean.new(!eval_bool(right, stack))
    end

    puts node

    raise RunTimeError.new("Invalid operator or right-hand-side in unary expression")
  end

  def exec_binary_expression(node, stack)

    # Resolve the left and right side
    operator = node.operator
    left = exec_expression(node.left, stack)
    right = exec_expression(node.right, stack)

    # Search for a operator overload on binary expressions
    operator_name = case operator
    when TokenType::Plus
      "__plus"
    when TokenType::Minus
      "__minus"
    when TokenType::Mult
      "__mult"
    when TokenType::Divd
      "__divd"
    when TokenType::Mod
      "__mod"
    when TokenType::Pow
      "__pow"
    else
      nil
    end

    if operator_name.is_a? String
      prop = redirect_property(left, operator_name, stack)
      if prop.is_a? TFunc
        return exec_function(prop, [right] of BaseType, left)
      end
    end

    if left.is_a?(TNumeric) && right.is_a?(TNumeric)
      case operator
      when TokenType::Plus
        return TNumeric.new(left.value + right.value)
      when TokenType::Minus
        return TNumeric.new(left.value - right.value)
      when TokenType::Mult
        if left.value == 0 || right.value == 0
          return TNumeric.new(0)
        end
        return TNumeric.new(left.value * right.value)
      when TokenType::Divd
        if left.value == 0 || right.value == 0
          return TNull.new
        end
        return TNumeric.new(left.value / right.value)
      when TokenType::Mod
        if right.value == 0
          return TNull.new
        end
        return TNumeric.new(left.value.to_i64 % right.value.to_i64)
      when TokenType::Pow
        return TNumeric.new(left.value ** right.value)
      end
    end

    if left.is_a?(TString) && right.is_a?(TString)
      case operator
      when TokenType::Plus
        return TString.new("#{left}#{right}")
      end
    end

    if left.is_a?(TString) && !right.is_a?(TString)
      case operator
      when TokenType::Plus
        return TString.new("#{left}#{right}")
      when TokenType::Mult

        # Check if the right side is a TNumeric
        if right.is_a?(TNumeric)
          return TString.new(left.value * right.value.to_i64)
        end
      end
    end

    if !left.is_a?(TString) && right.is_a?(TString)
      case operator
      when TokenType::Plus
        return TString.new("#{left}" + "#{right}")
      when TokenType::Mult

        # Check if the left side is a TNumeric
        if left.is_a?(TNumeric)
          return TString.new(right.value * left.value.to_i64)
        end
      end
    end

    raise RunTimeError.new("Invalid types or values inside binary expression")
  end

  # Perform a comparison
  def exec_comparison_expression(node, stack)

    # Resolve the left and right side
    left = exec_expression(node.left, stack)
    right = exec_expression(node.right, stack)
    operator = node.operator

    # Search for a operator overload on comparison expressions
    operator_name = case operator
    when TokenType::Greater
      "__greater"
    when TokenType::Less
      "__less"
    when TokenType::GreaterEqual
      "__greaterequal"
    when TokenType::LessEqual
      "__lessequal"
    when TokenType::Equal
      "__equal"
    when TokenType::Not
      "__notequal"
    else
      nil
    end

    if operator_name.is_a? String
      prop = redirect_property(left, operator_name, stack)
      if prop.is_a? TFunc
        return exec_function(prop, [right] of BaseType, left)
      end
    end

    # When comparing TNumeric's
    if left.is_a?(TNumeric) && right.is_a?(TNumeric)

      # Different types of operators
      case operator
      when TokenType::Greater
        return TBoolean.new(left.value > right.value)
      when TokenType::Less
        return TBoolean.new(left.value < right.value)
      when TokenType::GreaterEqual
        return TBoolean.new(left.value >= right.value)
      when TokenType::LessEqual
        return TBoolean.new(left.value <= right.value)
      when TokenType::Equal
        return TBoolean.new(left.value == right.value)
      when TokenType::Not
        return TBoolean.new(left.value != right.value)
      end
    end

    # When comparing TBools
    if left.is_a?(TBoolean) && right.is_a?(TBoolean)
      case operator
      when TokenType::Equal
        return TBoolean.new(left.value == right.value)
      when TokenType::Not
        return TBoolean.new(left.value != right.value)
      end
    end

    # When comparing strings
    if left.is_a?(TString) && right.is_a?(TString)
      case operator
      when TokenType::Greater
        return TBoolean.new(left.value.size > right.value.size)
      when TokenType::Less
        return TBoolean.new(left.value.size < right.value.size)
      when TokenType::GreaterEqual
        return TBoolean.new(left.value.size >= right.value.size)
      when TokenType::LessEqual
        return TBoolean.new(left.value.size <= right.value.size)
      when TokenType::Equal
        return TBoolean.new(left.value == right.value)
      when TokenType::Not
        return TBoolean.new(left.value != right.value)
      end
    end

    # When comparing TFunc
    if left.is_a?(TFunc) && right.is_a?(TFunc)
      case operator
      when TokenType::Equal
        return TBoolean.new(left == right)
      when TokenType::Not
        return TBoolean.new(left != right)
      end
    end

    # When comparing TClass
    if left.is_a?(TClass) && right.is_a?(TClass)
      case operator
      when TokenType::Equal
        return TBoolean.new(left == right)
      when TokenType::Not
        return TBoolean.new(left != right)
      end
    end

    # When comparing TObject
    if left.is_a?(TObject) && right.is_a?(TObject)
      case operator
      when TokenType::Equal
        return TBoolean.new(left == right)
      when TokenType::Not
        return TBoolean.new(left != right)
      end
    end

    if left.is_a? TNull

      case operator
      when TokenType::Equal

        if right.is_a? TBoolean
          return TBoolean.new(!right.value)
        end

        return TBoolean.new(right.is_a? TNull)
      when TokenType::Not

        if right.is_a? TBoolean
          return TBoolean.new(right.value)
        end

        return TBoolean.new(!right.is_a?(TNull))
      end
    end

    if right.is_a? TNull
      case operator
      when TokenType::Equal

        if left.is_a? TBoolean
          return TBoolean.new(left.value)
        end

        return TBoolean.new(left.is_a? TNull)
      when TokenType::Not

        if left.is_a? TBoolean
          return TBoolean.new(!left.value)
        end

        return TBoolean.new(!left.is_a?(TNull))
      end
    end

    # If the left side is bool
    if left.is_a?(TBoolean) && !right.is_a?(TBoolean)
      case operator
      when TokenType::Equal
        return TBoolean.new(left.value == eval_bool(right, stack))
      when TokenType::Not
        return TBoolean.new(left.value != eval_bool(right, stack))
      end
    end

    if !left.is_a?(TBoolean) && right.is_a?(TBoolean)
      case operator
      when TokenType::Equal
        return TBoolean.new(right.value == eval_bool(left, stack))
      when TokenType::Not
        return TBoolean.new(right.value != eval_bool(left, stack))
      end
    end

    return TBoolean.new(false)
  end

  def exec_and(node, stack)
    left = eval_bool(exec_expression(node.left, stack), stack)
    if left
      return TBoolean.new(eval_bool(exec_expression(node.right, stack), stack))
    else
      return TBoolean.new(false)
    end
  end

  def exec_or(node, stack)
    left = exec_expression(node.left, stack)
    right = exec_expression(node.right, stack)

    left_bool = eval_bool(left, stack)
    right_bool = eval_bool(right, stack)

    if left_bool
      return left
    else
      return right
    end
  end

  # Execute an if statement
  def exec_if_statement(node, stack)

    # Resolve the test expression
    test_result = eval_bool(exec_expression(node.test, stack), stack)

    # Run the respective handler
    if test_result
      return exec_block(node.consequent, Stack.new(stack))
    else
      alternate = node.alternate
      if alternate.is_a?(IfStatement)
        return exec_if_statement(alternate, stack)
      elsif node.alternate.is_a?(Block)
        return exec_block(alternate, Stack.new(stack))
      end
    end

    # Sanity check
    return TNull.new
  end

  # Executes a while node
  def exec_while_statement(node, stack)
    last_result = TNull.new
    begin
      while eval_bool(exec_expression(node.test, stack), stack)
        last_result = exec_block(node.consequent, Stack.new(stack))
      end
    rescue e : Events::Break
    end
    return last_result
  end

  # Redirect an internal method to InternalFunctions
  macro internal_method(fname, path = nil)
    if name.value == "{{fname.id}}"
      {% if path == nil %}
        return InternalFunctions.{{fname.id}}(arguments, stack)
      {% else %}
        return InternalFunctions{{path}}(arguments, stack)
      {% end %}
    end
  end

  # Directly bind an internal method
  macro bind_internal_method(fname, method)
    if name.value == "{{fname.id}}"
      return {{method}}
    end
  end

  # Executes a call expression
  def exec_call_expression(node, stack)

    # Reserve the context variable
    context = nil

    # Resolve all arguments
    arguments = [] of BaseType
    node.argumentlist.children.each do |argument|
      arguments << exec_expression(argument, stack)
    end

    # the default context for the function
    context = nil

    # Get the identifier of the call expression
    # If the identifier is an IdentifierLiteral we first check
    # if it's a call to "call_internal"
    # we are redirecting this
    identifier = node.identifier
    if identifier.is_a? IdentifierLiteral

      # Check for the "call_internal" name
      if identifier.name == "call_internal"

        unless arguments.size > 0
          raise RunTimeError.new("call_internal expected at least 1 argumen.")
        end

        name = arguments[0]
        if name.is_a? TString

          # IO Methods
          internal_method :stdout_print, ::STDOUT.print
          internal_method :stdout_write, ::STDOUT.write
          internal_method :stderr_print, ::STDERR.print
          internal_method :stderr_write, ::STDERR.write
          internal_method :stdin_gets, ::STDIN.gets
          internal_method :stdin_getc, ::STDIN.getc

          # Various language features
          bind_internal_method :require, InternalFunctions.require(arguments, stack, @session, @initial_stack.file.not_nil!)
          bind_internal_method :include, InternalFunctions.include(arguments, stack, @session, @initial_stack.file.not_nil!)
          bind_internal_method :time_ms, TNumeric.new(Time.now.epoch_ms.to_f64)

          # Misc. methods
          internal_method :length
          internal_method :array_of_size
          internal_method :array_insert
          internal_method :array_delete
          internal_method :unpack
          internal_method :colorize
          internal_method :exit
          internal_method :typeof
          internal_method :to_numeric
          internal_method :trim
          internal_method :sleep
          internal_method :ord
          internal_method :math
          internal_method :getvalue
          internal_method :setvalue
          bind_internal_method :eval, InternalFunctions.eval(arguments, stack, @session)

          raise RunTimeError.new("Internal function call to '#{name.value}' not implemented!")
        else
          raise RunTimeError.new("The first argument to call_internal has to be a string.")
        end
      else
        target = stack.get(identifier.name)
      end
    elsif identifier.is_a? MemberExpression

      # We have to manually resolve a member expression in this case
      # because we are interested in the identifier part
      #
      # identifier.member()
      #    ^- what we want

      # Resolve the identifier
      me_identifier = exec_expression(identifier.identifier, stack)
      target = redirect_property(me_identifier, identifier.member.name, stack)
      context = me_identifier
    else
      target = exec_expression(identifier, stack)
    end

    # Different handlers for different data types
    if target.is_a? TClass
      return exec_object_instantiation(target, arguments, stack)
    elsif target.is_a? TFunc

      # Get the context if it was not set before
      context = target.parent_stack.get("self") unless context
      return exec_function(target, arguments, context)
    else
      raise RunTimeError.new("#{identifier} is not a function!")
    end
  end

  # Executes a member expression
  def exec_member_expression(node, stack)
    identifier = exec_expression(node.identifier, stack)
    return redirect_property(identifier, node.member.name, stack);
  end

  def exec_index_expression(node, stack)
    identifier = exec_expression(node.identifier, stack)

    # Check if there is at least 1 item in the index expression
    unless node.argumentlist.children.size > 0
      raise RunTimeError.new("Missing expression in index expression")
    end

    # Array index lookup
    if identifier.is_a? TArray

      # Resolve the identifier
      member = exec_expression(node.argumentlist.children[0], stack)

      # Typecheck
      if member.is_a?(TNumeric)

        # Check for out-of-bounds error
        index_i64 = member.value.to_i64
        if index_i64 > identifier.value.size - 1 || index_i64 < 0
          return TNull.new
        end

        # Return the value from the index
        return identifier.value[index_i64]
      else
        raise RunTimeError.new("Invalid type #{member.class} for array index expression")
      end
    elsif identifier.is_a? TString

      # Resolve the identifier
      member = exec_expression(node.argumentlist.children[0], stack)

      # Typecheck
      if member.is_a?(TNumeric)

        # Check for out-of-bounds error
        index_i64 = member.value.to_i64
        if index_i64 > identifier.value.size - 1 || index_i64 < 0
          return TNull.new
        end

        # Return the value from the index
        return TString.new(identifier.value[index_i64].to_s)
      else
        raise RunTimeError.new("Invalid type #{member.class} for string index expression")
      end
    else

      # Search for the the __member function
      prop = redirect_property(identifier, "__member", stack)
      if prop.is_a? TFunc

        # Resolve all children
        arguments = [] of BaseType
        node.argumentlist.children.each do |child|
          arguments << exec_expression(child, stack)
        end

        # Execute the __member function
        return exec_function(prop, arguments, identifier)
      end
    end

    raise RunTimeError.new("Could not perform index expression on #{identifier}")
  end

  # Redirects a property from a literal to one of the languages primitive classes
  # The result will be returned
  def redirect_property(identifier, propname : String, stack)

    # If this is an object
    if identifier.is_a? TObject

      # Check if the object contains the propname
      if identifier.stack.contains(propname)
        return identifier.stack.get(propname, false)
      end
    end

    # Check the stack for an object specific to the current identifier
    # For example, if the identifier is of type TNumeric
    # we will search for an object called Numeric
    # This is defined in the classname method on CharlyTypes
    [identifier.class.to_s, "Object"].uniq.each do |identifier_name|
      if @session.primitives.defined(identifier_name)
        primitiveobject = @session.primitives.get(identifier_name)

        # Typecheck
        if primitiveobject.is_a? TObject

          # Check if the object contains the prop
          if primitiveobject.stack.contains propname
            return primitiveobject.stack.get(propname, false)
          end
        end
      end
    end

    return TNull.new
  end

  # Executes *function*, passing it *arguments*
  # inside *stack*
  # *function* is of type TFunc
  # *arguments* is an actual array of RunTimeType values
  def exec_function(function : TFunc, arguments : Array(BaseType), context)

    # The stack in which the function runs
    function_stack = Stack.new(function.parent_stack)

    # Get the identities of the arguments that are required
    argument_ids = [] of String
    function.argumentlist.children.map { |argument|
      if argument.is_a? IdentifierLiteral
        argument_ids << argument.name
      end
    }.compact

    function_stack.write("__arguments", TArray.new(arguments), declaration: true, constant: true, force: true)
    function_stack.write("self", context, declaration: true, constant: true, force: true)

    # Write the argument to the function stack
    arguments.each_with_index do |arg, index|

      # Check for index out of bounds
      unless index < argument_ids.size
        break
      end

      # Write the argument into the stack
      id = argument_ids[index]
      function_stack.write(id, arg, true)
    end

    # Check if the correct amount of arguments was passed
    if arguments.size < argument_ids.size
      raise RunTimeError.new("Function expected #{argument_ids.size} argument(s), got #{arguments.size}")
    end

    # Execute the block
    begin
      return exec_block(function.block, function_stack)
    rescue e : Events::Return
      return e.payload
    rescue e : Events::Break
      raise RunTimeError.new("Invalid break statement")
    end
  end

  # Create an instance of a given class
  def exec_object_instantiation(classliteral, arguments, stack)

    # The stack for the object
    object_stack = Stack.new(classliteral.parent_stack)

    # The object
    object = TObject.new object_stack

    # Inject the self keyword into the class block
    object_stack.write("self", object, declaration: true, constant: true, force: true)
    object_stack.write("instance_type", classliteral, declaration: true, constant: true, force: true)

    # Execute the class block inside the object_stack
    begin
      exec_block(classliteral.block, object_stack)
    rescue e : Events::Return
      raise RunTimeError.new("Invalid return statement")
    rescue e : Events::Break
      raise RunTimeError.new("Invalid break statement")
    end


    # Search for the constructor of the class
    # and execute it in the object_stack if it was found
    if object_stack.contains("constructor")
      function = object_stack.get "constructor"

      # Bind the self identifier
      if function.is_a? TFunc
        exec_function(function, arguments, object)
        object_stack.delete("constructor")
      end
    end

    # Create a new TObject and store the object_stack in it
    return object
  end

  def exec_literal(node, stack)
    case node
    when .is_a? NumericLiteral
      return TNumeric.new(node.value)
    when .is_a? StringLiteral
      return TString.new(node.value)
    when .is_a? BooleanLiteral
      return TBoolean.new(node.value)
    when .is_a? FunctionLiteral
      return TFunc.new(node.argumentlist, node.block, stack)
    when .is_a? ArrayLiteral

      # Resolve all children first
      children = [] of BaseType
      node.children.map do |child|
        children << exec_expression(child, stack)
      end
      return TArray.new(children)
    when .is_a? ClassLiteral
      return TClass.new(node.block, stack)
    when .is_a? NullLiteral
      return TNull.new
    end

    raise RunTimeError.new("Invalid literal found #{node.class}")
  end

  # Executes a container literal
  def exec_container_literal(node, stack)
    classliteral = TClass.new(node.block, stack)
    return exec_object_instantiation(classliteral, [] of BaseType, stack)
  end

  # Executes a block and catches any catchable exception
  def exec_try_catch(node, stack)

    # The stack in which the catch block will be run in
    catch_stack = Stack.new(stack)

    begin
      return exec_block(node.try_block, Stack.new(stack))
    rescue e : BaseException
      io = MemoryIO.new
      e.to_s(io)
      catch_stack.write(node.exception_name.name, TString.new(io.to_s), declaration: true)
    rescue e : Events::Throw
      catch_stack.write(node.exception_name.name, e.payload, declaration: true)
    end

    return exec_block(node.catch_block, catch_stack)
  end

  # Returns the boolean representation of a value
  def eval_bool(value, stack)
    case value
    when .is_a? TNumeric
      return value.value != 0_f64
    when .is_a? TBoolean
      return value.value
    when .is_a? Bool
      return value
    else
      return false
    end
  end

  def exec_return_statement(node, stack)
    return_value = TNull.new
    if !(tmp = node.expression).is_a? Empty
      return_value = exec_expression(node.expression, stack)
    end

    raise Events::Return.new(return_value)
  end

  def exec_throw_statement(node, stack)
    throw_value = exec_expression(node.expression, stack)
    raise Events::Throw.new(throw_value)
  end

  def exec_break_statement(node, stack)
    raise Events::Break.new(TNull.new)
  end
end
