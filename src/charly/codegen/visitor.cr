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

      @main_function_collection.add("main", [] of LLVM::Type, LibLLVM.int8_type, false) do |function|
        function_collection = LLVM::BasicBlockCollection.new function
        function_collection.append("entry") do |builder|
          @builder = builder
        end
      end
    end

    def visit(node : Block)
      node.children.each_with_index do |child, index|
        visit child
      end

      return LLVM.int LLVM::Int1, 0
    end

    def visit(node : VariableInitialisation)
      case node.expression
      when FunctionLiteral
        codegen_function_literal node.expression
      else
        var = @builder.alloca(LLVM::Double, node.identifier.name)
        value = visit node.expression
        result = @builder.store value, var
        @named_values[node.identifier.name] = var
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
      LLVM.double node.value
    end

    def visit(node : BinaryExpression)
      case node.operator
      when TokenType::Plus
        return @builder.fadd(visit(node.left), visit(node.right), "fadd")
      when TokenType::Minus
        return @builder.fsub(visit(node.left), visit(node.right), "fadd")
      when TokenType::Mult
        return @builder.fmul(visit(node.left), visit(node.right), "fadd")
      when TokenType::Divd
        return @builder.fdiv(visit(node.left), visit(node.right), "fadd")
      end

      raise Exception.new("Visiting #{node.operator} is not implemented")
    end

    def visit(node : IdentifierLiteral)
      if @named_values.has_key? node.name
        value = @named_values[node.name]
        return @builder.load value, node.name
      end

      raise Exception.new("Unknown variable #{node.name} during variable load")
    end

    def visit(node : NullLiteral)
      LLVM.double 0_f64
    end

    def visit(node : ReturnStatement)
      value = visit node.expression
      @builder.ret(value)
    end

    def visit(node)
      raise Exception.new("Visiting #{node.class} is not implemented")
    end

    def codegen_function_literal(node : FunctionLiteral)
      @main_function_collection.add(node.name.not_nil!, [] of LLVM::Type, LibLLVM.double_type, false) do |function|
        function_collection = LLVM::BasicBlockCollection.new function
        function_collection.append("entry") do |builder|
          backup_builder = @builder
          backup_named_values = @named_values
          @builder = builder
          @named_values = {} of String => LLVM::Value

          visit(node.block)

          @builder = backup_builder
          @named_values = backup_named_values
        end
      end

      LLVM.double 0_f64
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
