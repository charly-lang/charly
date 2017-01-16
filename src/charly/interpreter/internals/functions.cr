require "../**"

module Charly::Internals

  charly_api "function_bind", function : TFunc, context : BaseType, bound_arguments : TArray do
    function = function.dup
    function.bound_arguments = function.bound_arguments.dup

    function.bound_context = context

    bound_arguments.value.each do |item|
      function.bound_arguments << item
    end

    return function
  end

  charly_api "is_internal", function : BaseType do
    return TBoolean.new function.is_a?(TInternalFunc)
  end

end
