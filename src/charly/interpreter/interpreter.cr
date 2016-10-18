require "../syntax/ast/ast.cr"
require "./stack/stack.cr"
require "./types.cr"
require "./session.cr"
require "./event.cr"
require "./internal-functions.cr"

# Execute the AST by recursively traversing it's nodes
class Interpreter
  include CharlyTypes
  property initial_stack : Stack
  property program_result : BaseType
  property session : Session

  def initialize(programs, stack, session)
    @initial_stack = stack
    @session = session
    @program_result = exec_programs(programs, stack)
  end

  # Execute a bunch of programs, each having access to a shared top stack
  def exec_programs(programs, stack)
    last_result = TNull.new
    programs.map do |program|
      last_result = exec_program(program, stack)
    end
    last_result
  end

  # Executes *program* inside *stack*
  def exec_program(program, stack)
    global = TObject.new(stack)
    stack.write("self", global, declaration: true, constant: true, force: true)
    stack.write("program", global, declaration: true, constant: true, force: true)
    stack.write("export", TNull.new, declaration: true)

    begin
      exec_block(program.children[0], stack)
    rescue Events::Return
      raise "Invalid return statement"
    rescue Events::Break
      raise "Invalid break statement"
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

    if node.is_a? Group
      return exec_expression(node.children[0], stack)
    end

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

    if node.is_a? LogicalExpression
      return exec_logical_expression(node, stack)
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

    if node.is_a? NullLiteral
      return TNull.new
    end

    if node.is_a? ReturnStatement
      return exec_return_statement(node, stack)
    end

    if node.is_a? BreakStatement
      return exec_break_statement(node, stack)
    end

    if node.is_a? NANLiteral
      return TNumeric.new(Float64::NAN)
    end

    raise "Unknown node encountered #{node} #{stack}"
  end

  # Initializes a variable in the current stack
  # The value is set to TNull
  def exec_variable_declaration(node, stack)
    value = TNull.new
    identifier = node.identifier
    if identifier.is_a?(IdentifierLiteral)
      identifier_value = identifier.value
      if identifier_value.is_a?(String)
        stack.write(identifier_value, value, true)
      end
    end
    return value
  end

  # Saves value to a given variable in the current stack
  def exec_variable_initialisation(node, stack, constant = false)

    # Resolve the value
    value = exec_expression(node.expression, stack)

    # Check for the identifier
    identifier = node.identifier
    if identifier.is_a? IdentifierLiteral
      identifier_value = identifier.value
      if identifier_value.is_a? String

        if value.is_a? BaseType
          stack.write(identifier_value, value, declaration: true, constant: constant)
        end
      end
    end
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
      identifier = exec_expression(identifier.not_nil!, stack)

      # Only TObjects are allowed
      unless identifier.is_a?(TObject)
        raise "#{identifier} is not an object"
      end

      # Typecheck the member
      unless member.is_a?(IdentifierLiteral)
        raise "Member node is not an identifier. You've found a bug in the interpeter."
      end

      identifier.stack.write(member.value.as(String), value, true, false)
      return value
    elsif identifier.is_a? IndexExpression

      # Get some values
      member = identifier.member.not_nil!
      identifier = identifier.identifier.not_nil!

      # Resolve the identifier
      identifier = exec_expression(identifier, stack)

      # Only TArray and TString allowed
      if identifier.is_a? TArray

        # Check that there is at least 1 expression
        unless member.children.size > 0
          raise "Missing index for array index expression"
        end

        # Resolve the member
        member = exec_expression(member.children[0], stack)

        # Typecheck the member
        if member.is_a?(TNumeric)

          # Out-of-bounds check
          if member.value < 0 || member.value > identifier.value.size - 1
            raise "Index out of bounds!"
          end

          # Write to the index
          identifier.value[member.value.to_i64] = value
          return value
        else
          raise "Can't use #{member} in array index expression."
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
    else

      if identifier.is_a?(IdentifierLiteral)

        identifier_value = identifier.value
        if identifier_value.is_a?(String)

          # Check that the value is a BaseType
          if value.is_a? BaseType
            stack.write(identifier_value, value)
          end
        end
      end
    end

    return value
  end

  # Extracts the value of a variable from the current stack
  def exec_identifier_literal(node, stack)
    stack.get(node.value)
  end

  def exec_unary_expression(node, stack)

    # Resolve the right side
    operator = node.operator
    right = exec_expression(node.right, stack)

    # Search for a operator overload on comparison expressions
    operator_name = case node.operator
    when MinusOperator
      "__uminus"
    when NotOperator
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

    case operator
    when MinusOperator
      if right.is_a? TNumeric
        return TNumeric.new(-right.value)
      end
    when NotOperator
      return TBoolean.new(!eval_bool(right, stack))
    end

    raise "Invalid operator or right-hand-side in unary expression"
  end

  def exec_binary_expression(node, stack)

    # Resolve the left and right side
    operator = node.operator
    left = exec_expression(node.left, stack)
    right = exec_expression(node.right, stack)

    # Search for a operator overload on binary expressions
    operator_name = case operator
    when PlusOperator
      "__plus"
    when MinusOperator
      "__minus"
    when MultOperator
      "__mult"
    when DivdOperator
      "__divd"
    when ModOperator
      "__mod"
    when PowOperator
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
      when PlusOperator
        return TNumeric.new(left.value + right.value)
      when MinusOperator
        return TNumeric.new(left.value - right.value)
      when MultOperator
        if left.value == 0 || right.value == 0
          return TNumeric.new(0)
        end
        return TNumeric.new(left.value * right.value)
      when DivdOperator
        if left.value == 0 || right.value == 0
          return TNull.new
        end
        return TNumeric.new(left.value / right.value)
      when ModOperator
        if right.value == 0
          return TNull.new
        end
        return TNumeric.new(left.value.to_i64 % right.value.to_i64)
      when PowOperator
        return TNumeric.new(left.value ** right.value)
      end
    end

    if left.is_a?(TString) && right.is_a?(TString)
      case operator
      when PlusOperator
        return TString.new("#{left}" + "#{right}")
      end
    end

    if left.is_a?(TString) && !right.is_a?(TString)
      case operator
      when PlusOperator
        return TString.new("#{left}" + "#{right}")
      when MultOperator

        # Check if the right side is a TNumeric
        if right.is_a?(TNumeric)
          return TString.new(left.value * right.value.to_i64)
        end
      end
    end

    if !left.is_a?(TString) && right.is_a?(TString)
      case operator
      when PlusOperator
        return TString.new("#{left}" + "#{right}")
      when MultOperator

        # Check if the left side is a TNumeric
        if left.is_a?(TNumeric)
          return TString.new(right.value * left.value.to_i64)
        end
      end
    end

    raise "Invalid types or values inside binary expression"
  end

  # Perform a comparison
  def exec_comparison_expression(node, stack)

    # Resolve the left and right side
    left = exec_expression(node.left, stack)
    right = exec_expression(node.right, stack)
    operator = node.operator

    # Search for a operator overload on comparison expressions
    operator_name = case operator
    when GreaterOperator
      "__greater"
    when LessOperator
      "__less"
    when GreaterEqualOperator
      "__greaterequal"
    when LessEqualOperator
      "__lessequal"
    when EqualOperator
      "__equal"
    when NotOperator
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
      when GreaterOperator
        return TBoolean.new(left.value > right.value)
      when LessOperator
        return TBoolean.new(left.value < right.value)
      when GreaterEqualOperator
        return TBoolean.new(left.value >= right.value)
      when LessEqualOperator
        return TBoolean.new(left.value <= right.value)
      when EqualOperator
        return TBoolean.new(left.value == right.value)
      when NotOperator
        return TBoolean.new(left.value != right.value)
      end
    end

    # When comparing TBools
    if left.is_a?(TBoolean) && right.is_a?(TBoolean)
      case operator
      when EqualOperator
        return TBoolean.new(left.value == right.value)
      when NotOperator
        return TBoolean.new(left.value != right.value)
      end
    end

    # When comparing strings
    if left.is_a?(TString) && right.is_a?(TString)
      case operator
      when GreaterOperator
        return TBoolean.new(left.value.size > right.value.size)
      when LessOperator
        return TBoolean.new(left.value.size < right.value.size)
      when GreaterEqualOperator
        return TBoolean.new(left.value.size >= right.value.size)
      when LessEqualOperator
        return TBoolean.new(left.value.size <= right.value.size)
      when EqualOperator
        return TBoolean.new(left.value == right.value)
      when NotOperator
        return TBoolean.new(left.value != right.value)
      end
    end

    # When comparing TFunc
    if left.is_a?(TFunc) && right.is_a?(TFunc)
      case operator
      when EqualOperator
        return TBoolean.new(left == right)
      when NotOperator
        return TBoolean.new(left != right)
      end
    end

    # When comparing TClass
    if left.is_a?(TClass) && right.is_a?(TClass)
      case operator
      when EqualOperator
        return TBoolean.new(left == right)
      when NotOperator
        return TBoolean.new(left != right)
      end
    end

    # When comparing TObject
    if left.is_a?(TObject) && right.is_a?(TObject)
      case operator
      when EqualOperator
        return TBoolean.new(left == right)
      when NotOperator
        return TBoolean.new(left != right)
      end
    end

    # If both sides are TNull
    if left.is_a?(TNull) && right.is_a?(TNull)
      case operator
      when EqualOperator
        return TBoolean.new(true)
      when NotOperator
        return TBoolean.new(false)
      end
    end

    # If the left side is bool
    if left.is_a?(TBoolean) && !right.is_a?(TBoolean)
      case operator
      when EqualOperator
        return TBoolean.new(left.value == eval_bool(right, stack))
      when NotOperator
        return TBoolean.new(left.value != eval_bool(right, stack))
      end
    end

    if !left.is_a?(TBoolean) && right.is_a?(TBoolean)
      case operator
      when EqualOperator
        return TBoolean.new(right.value == eval_bool(left, stack))
      when NotOperator
        return TBoolean.new(right.value != eval_bool(left, stack))
      end
    end

    return TBoolean.new(false)
  end

  def exec_logical_expression(node, stack)
    case (op = node.operator)
    when ANDOperator
      left = eval_bool(exec_expression(node.left, stack), stack)
      if left
        return TBoolean.new(eval_bool(exec_expression(node.right, stack), stack))
      else
        return TBoolean.new(false)
      end
    when OROperator
      left = exec_expression(node.left, stack)
      right = exec_expression(node.right, stack)

      left_bool = eval_bool(left, stack)
      right_bool = eval_bool(right, stack)

      if left_bool
        return left
      else
        return right
      end
    else
      raise "Unknown logical operator #{op}"
    end
  end

  # Execute an if statement
  def exec_if_statement(node, stack)

    # Resolve the test expression
    test = node.test
    if test.is_a?(ASTNode)
      test_result = eval_bool(exec_expression(node.test, stack), stack)
    else
      return TNull.new
    end

    # Run the respective handler
    if test_result
      consequent = node.consequent
      if consequent.is_a?(Block)
        return exec_block(consequent, Stack.new(stack))
      end
    else
      alternate = node.alternate
      if alternate.is_a?(ASTNode)
        if alternate.is_a?(IfStatement)
          return exec_if_statement(alternate, stack)
        elsif node.alternate.is_a?(Block)
          return exec_block(alternate, Stack.new(stack))
        end
      end
    end

    # Sanity check
    return TNull.new
  end

  # Executes a while node
  def exec_while_statement(node, stack)

    # Typecheck
    test = node.test
    consequent = node.consequent

    if test.is_a?(ASTNode) && consequent.is_a?(ASTNode)
      last_result = TNull.new
      begin
        while eval_bool(exec_expression(test, stack), stack)
          last_result = exec_block(consequent, Stack.new(stack))
        end
      rescue e : Events::Break
      end
      return last_result
    else
      return TNull.new
    end
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
    argumentlist = node.argumentlist
    if argumentlist.is_a? ExpressionList
      argumentlist.each do |argument|
        arguments << exec_expression(argument, stack)
      end
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
      if identifier.value == "call_internal"

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

          raise "Internal function call to '#{name.value}' not implemented!"
        else
          raise "The first argument to call_internal has to be a string."
        end
      else
        target = stack.get(identifier.value)
      end
    elsif identifier.is_a? MemberExpression

      # We have to manually resolve a member expression in this case
      # because we are interested in the identifier part
      #
      # identifier.member()
      #    ^- what we want
      me_identifier = identifier.identifier
      me_member = identifier.member

      # Resolve the identifier
      me_identifier = exec_expression(me_identifier, stack)
      context = me_identifier

      if me_member.is_a?(IdentifierLiteral)
        target = redirect_property(me_identifier, me_member.value.as(String), stack)
        context = me_identifier
      else
        raise "Member node is not an identifier. You've found a bug in the interpeter."
      end
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
      raise "#{identifier} is not a function!"
    end
  end

  # Executes a member expression
  def exec_member_expression(node, stack)
    identifier = exec_expression(node.identifier, stack)
    member = node.member

    if member.is_a?(IdentifierLiteral)
      return redirect_property(identifier, member.value.as(String), stack);
    end

    return TNull.new
  end

  def exec_index_expression(node, stack)
    identifier = exec_expression(node.identifier, stack)
    member = node.member

    # Sanity check
    unless member.is_a? ASTNode
      raise "Member node is not an identifier. You've found a bug in the interpeter."
    end

    # Check if there is at least 1 item in the index expression
    unless member.children.size > 0
      raise "Missing expression in index expression"
    end

    # Array index lookup
    if identifier.is_a? TArray

      # Resolve the identifier
      member = exec_expression(member.children[0], stack)

      # Typecheck
      if member.is_a?(TNumeric)

        # Check for out-of-bounds error
        if member.value.to_i64 > identifier.value.size - 1 || member.value.to_i64 < 0
          return TNull.new
        end

        # Return the value from the index
        return identifier.value[member.value.to_i64]
      else
        raise "Invalid type #{member.class} for array index expression"
      end
    elsif identifier.is_a? TString

      # Resolve the identifier
      member = exec_expression(member.children[0], stack)

      # Typecheck
      if member.is_a?(TNumeric)

        # Check for out-of-bounds error
        if member.value.to_i64 > identifier.value.size - 1 || member.value.to_i64 < 0
          return TNull.new
        end

        # Return the value from the index
        return TString.new(identifier.value[member.value.to_i64].to_s)
      else
        raise "Invalid type #{member.class} for string index expression"
      end
    else

      # Search for the the __member function
      prop = redirect_property(identifier, "__member", stack)
      if prop.is_a? TFunc

        # Resolve all children
        arguments = [] of BaseType
        member.children.each do |child|
          arguments << exec_expression(child, stack)
        end

        # Execute the __member function
        return exec_function(prop, arguments, identifier)
      end
    end

    raise "Could not perform index expression on #{identifier}"
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

    # Check if there is a parent stack
    if (parent_stack = function.parent_stack).is_a? Stack
      function_stack = Stack.new(parent_stack)
    else
      raise "Could not find a valid stack for the function to run in. You've found a bug in the interpreter."
    end

    # Get the identities of the arguments that are required
    argument_ids = function.argumentlist.map { |argument|
      if argument.is_a? IdentifierLiteral && argument.value.is_a? String
        result = argument.value
      end
    }.compact

    function_stack.write("__arguments", TArray.new(arguments), declaration: true, constant: true, force: true)
    function_stack.write("self", context, declaration: true, constant: true, force: true)

    # Write the argument to the function stack
    arguments.each_with_index do |arg, index|

      # Check for index out of bounds
      unless index < argument_ids.size
        next
      end

      # Write the argument into the stack
      id = argument_ids[index]
      if id.is_a? String
        function_stack.write(id, arg, true)
      end
    end

    # Check if the correct amount of arguments was passed
    if arguments.size < argument_ids.size
      raise "Function expected #{argument_ids.size} argument(s), got #{arguments.size}"
    end

    # Execute the block
    begin
      return exec_block(function.block, function_stack)
    rescue e : Events::Return
      return e.payload
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

    # Execute the class block inside the object_stack
    exec_block(classliteral.block, object_stack)

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
      value = node.value
      if value.is_a?(String)
        return TNumeric.new(value.to_f)
      end
    when .is_a? StringLiteral
      value = node.value
      if value.is_a?(String)
        return TString.new(value)
      end
    when .is_a? BooleanLiteral
      value = node.value
      if value.is_a?(String)
        return TBoolean.new(value == "true")
      end
    when .is_a? FunctionLiteral
      argumentlist = node.argumentlist
      block = node.block

      if argumentlist.is_a? ASTNode && block.is_a? Block
        return TFunc.new(argumentlist.children, block, stack, !!node.anonymous)
      end
    when .is_a? ArrayLiteral

      # Resolve all children first
      children = [] of BaseType
      node.children.map do |child|
        children << exec_expression(child, stack)
      end
      return TArray.new(children)
    when .is_a? ClassLiteral
      block = node.block

      if block.is_a? Block
        return TClass.new(block, stack)
      end
    when .is_a? NullLiteral
      return TNull.new
    end

    raise "Invalid literal found #{node.class}"
  end

  # Executes a container literal
  def exec_container_literal(node, stack)

    # Check if there is a block
    if (block = node.block).is_a? Block
      classliteral = TClass.new(block, stack)
      return exec_object_instantiation(classliteral, [] of BaseType, stack)
    end

    return TNull.new
  end

  # Returns the boolean representation of a value
  def eval_bool(value, stack)

    bool = false
    case value
    when .is_a? TNumeric
      bool = value.value != 0_f64
    when .is_a? TBoolean
      bool = value.value
    when .is_a? TString
      bool = true
    when .is_a? TFunc
      bool = true
    when .is_a? TObject
      bool = true
    when .is_a? TClass
      bool = true
    when .is_a? TArray
      bool = true
    when .is_a? TNull
      bool = false
    when .is_a? Bool
      bool = value
    end
    bool
  end

  def exec_return_statement(node, stack)
    return_value = TNull.new
    if (tmp = node.expression).is_a? ASTNode
      return_value = exec_expression(node.expression, stack)
    end

    raise Events::Return.new(return_value)
  end

  def exec_break_statement(node, stack)
    raise Events::Break.new
  end
end
