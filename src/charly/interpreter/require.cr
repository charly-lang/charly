require "./session.cr"
require "../exceptions.cr"
require "./stack/stack.cr"
require "../file.cr"

module Charly::Interpreter::Require
  include CharlyExceptions
  extend self

  CORE_MODULES = [
    "io",
    "unit-test",
    "math",
    "repl"
  ]

  def include(filename, session, userfile, use_cache = true)
    path = resolve(filename, userfile.fulldirectorypath)
    could_include_as_file = load_as_file(path, session, use_cache)

    if could_include_as_file.is_a?(BaseType)
      if use_cache
        session.cached_require_calls[path] = could_include_as_file
      end

      return could_include_as_file
    end

    # filepath = File.expand_path(filepath)
    raise RunTimeError.new("Could not load #{filename}")
  end

  def resolve(filename, current_dir)

    # Check if it's a core-module
    if CORE_MODULES.includes? filename
      return ENV["CHARLYDIR"] + "/#{filename}.charly"
    end

    # If it's a relative path
    if filename.starts_with?("./") ||
      filename.starts_with?("../")
      return current_dir + "/#{filename}"
    end

    # Absolute paths
    if filename.starts_with?("/")
      return filename
    end

    raise RunTimeError.new("Can't find #{filename}")
  end

  def load_as_file(path, session, use_cache)

    # Check if there is a cache entry for this file
    if use_cache && session.cached_require_calls.has_key?(path)
      return load_from_cache(path, session)
    end

    # Check if the path is accessable
    if File.exists?(path) && File.readable?(path)
      include_file = RealFile.new(path)
      include_stack = Stack.new(session.prelude)
      interpreter = InterpreterFascade.new(session)
      result = interpreter.execute_file(include_file, include_stack)
      return include_stack.get("export")
    end

    return nil
  end

  def load_from_cache(path, session)
    entry = session.cached_require_calls[path]

    if entry.is_a? BaseType
      return entry
    end

    return TNull.new
  end
end
