require "./session.cr"
require "./stack/stack.cr"
require "../file.cr"

module Charly::Interpreter::Require
  extend self

  CORE_MODULES = [
    "io",
    "unit-test",
    "math",
    "repl"
  ]

  def require(filename, session, prelude, primitives, userfile, use_cache = true)
  end

  def resolve(filename, current_dir)
  end

  def load_as_file(path)
  end

  def load_as_directory(path)
  end
end
