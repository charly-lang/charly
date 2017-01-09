require "../**"

module Charly::Internals

  charly_api "function_bind", function : TFunc, context : BaseType, bound_arguments : TArray do
    function = function.dup

    function.bound_context = context
    function.bound_arguments = bound_arguments.value

    return function
  end

  charly_api "is_internal", function : BaseType do
    return TBoolean.new function.is_a?(TInternalFunc)
  end

end
