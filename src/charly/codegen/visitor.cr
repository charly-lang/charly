require "llvm"

module Charly
  class CodeGenVisitor
    property module : LLVM::Module
    property main_function_collection : LLVM::FunctionCollection
    property builder : LLVM::Builder
    property named_values : Hash(String, LLVM::Value)

    def initialize(name : String)
      @module = LLVM::Module.new(name)
      @main_function_collection = LLVM::FunctionCollection.new(@module)
      @builder = LLVM::Builder.new
      @named_values = {} of String => LLVM::Value

      # TODO: Dynamic target triple based on current system
      @module.target = "x86_64-apple-macosx10.12.0"
    end

    def visit(node : Block)
      node.children.each_with_index do |child, index|
        visit child
      end

      return LLVM.int LLVM::Int32, 0
    end

    def visit(node : VariableInitialisation)
      case node.expression
      when FunctionLiteral
        codegen_function_literal node.expression
      else
        var = @builder.alloca(LLVM::Int32, node.identifier.name)
        value = visit node.expression
        result = @builder.store value, var
        @named_values[node.identifier.name] = value
        result
      end
    end

    def visit(node : VariableAssignment)
      case (identifier = node.identifier)
      when IdentifierLiteral
        unless @named_values.has_key? identifier.name
          raise Exception.new("Unknown variable #{identifier.name} during assignment")
        end

        var = @named_values[identifier.name]
        value = visit node.expression
        @builder.store value, var
      else
        raise Exception.new("Can't assign to non identifier literal")
      end
    end

    def visit(node : NumericLiteral)
      LLVM.int LLVM::Int32, node.value
    end

    def visit(node : BinaryExpression)

      left = visit node.left
      right = visit node.right

      case node.operator
      when TokenType::Plus
        return @builder.add(left, right, "add")
      when TokenType::Minus
        return @builder.sub(left, right, "sub")
      when TokenType::Mult
        return @builder.mul(left, right, "mul")
      when TokenType::Divd
        return @builder.sdiv(left, right, "div")
      end

      raise Exception.new("Visiting #{node.operator} is not implemented")
    end

    def visit(node : IdentifierLiteral)
      if @named_values.has_key? node.name
        value = @named_values[node.name]
        return value
      end

      raise Exception.new("Unknown variable #{node.name} during variable load")
    end

    def visit(node : NullLiteral)
      LLVM.int LLVM::Int32, 0
    end

    def visit(node : ReturnStatement)
      value = visit node.expression
      @builder.ret(value)
    end

    def visit(node : CallExpression)
      unless (identifier = node.identifier).is_a? IdentifierLiteral
        raise Exception.new("Calling non-identifiers is not supported yet")
      end

      # codegen arguments
      arguments = [] of LLVM::Value
      node.argumentlist.each do |argument|
        arguments << visit argument
      end

      # Check if the method exists
      unless function = @main_function_collection[identifier.name]?
        raise Exception.new("Unknown function #{identifier.name}")
      end

      # codegen call expression
      @builder.call(function, arguments)
    end

    def visit(node)
      raise Exception.new("Visiting #{node.class} is not implemented")
    end

    def codegen_function_literal(node : FunctionLiteral)

      arguments = [] of LLVM::Type
      node.argumentlist.each do |arg|
        arguments << LLVM::Int32
      end

      @main_function_collection.add(node.name.not_nil!, arguments, LLVM::Int32, false) do |function|
        backup_named_values = @named_values
        @named_values = {} of String => LLVM::Value

        # Append arguments
        i = 0
        while i < function.params.size
          function.params[i].tap do |argument|
            if (arg = node.argumentlist[i]).is_a? IdentifierLiteral
              argument.name = arg.name
              @named_values[arg.name] = argument
            end
          end

          i += 1
        end

        function_collection = LLVM::BasicBlockCollection.new function
        function_collection.append("entry") do |builder|
          backup_builder = @builder
          @builder = builder

          visit(node.block)

          @builder = backup_builder
          @named_values = backup_named_values
        end
      end

      LLVM.int LLVM::Int32, 0
    end

    def codegen_function_literal(node)
      raise Exception.new("#{node} is not a function literal")
    end

    def dump_llvm
      @module.to_s
    end

    def dump_llvm(io)
      io << dump_llvm
    end
  end
end
