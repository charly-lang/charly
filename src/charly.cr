require "./charly/file.cr"
require "./charly/interpreter/fascade.cr"
require "./charly/interpreter/session.cr"
require "option_parser"

module Charly

  flags = [] of String
  filename = "main.charly" # default name for the input file
  arguments = [] of CharlyTypes::BaseType

  available_flags = <<-FLAGS

  Flags:
      ast                              Display AST's of parsed programs
      tokens                           Display tokens of parsed programs
      noexec                           Disable execution
      noprelude                        Don't load the prelude file
      stackdump                        Dump the top-level stack at the end of execution
  FLAGS

  OptionParser.parse! do |opts|
    opts.banner = "Usage: charly [options] filename [arguments]"
    opts.on("-f FLAG", "--flag FLAG", "Set a flag") { |flag|
      flags << flag
    }
    opts.on("-h", "--help", "Show this help") {
      puts opts
      puts available_flags
      exit
    }
    opts.on("-v", "--version", "Show the version number") {
      puts "0.0.0"
      exit
    }
    opts.invalid_option {} # ignore
    opts.unknown_args do |before_dash|
      if before_dash.size == 0
        puts "Missing filename"
        puts opts
        puts available_flags
        exit 1
      end

      filename = before_dash.to_a.shift
      before_dash.each do |arg|
        arguments << CharlyTypes::TString.new(arg)
      end

      # If the filename is repl, expand the path to the repl.charly file
      if filename == "repl"
        filename = ENV["CHARLYDIR"] + "/repl.charly"
      end
    end
  end

  # The current session
  session = Session.new

  # Create a stack that contains the results of the standard library
  prelude_stack = Stack.new nil
  userfile_stack = Stack.new prelude_stack

  # Write the export variable into the user stack
  userfile_stack.write("export", CharlyTypes::TNull.new, declaration: true)

  # Write the arguments into the prelude stack
  prelude_stack.write("ARGV", CharlyTypes::TArray.new(arguments), true)

  # Write the flags into the prelude stack
  iflags = [] of CharlyTypes::BaseType
  flags.each do |flag|
    iflags << CharlyTypes::TString.new(flag)
  end
  prelude_stack.write("IFLAGS", CharlyTypes::TArray.new(iflags), true)

  # Get a InterpreterFascade
  interpreter = InterpreterFascade.new(session, flags)

  # Execute the prelude
  unless flags.includes? "noprelude"
    interpreter.execute_file(RealFile.new(ENV["CHARLYDIR"] + "/prelude.charly"), prelude_stack)
  end

  # Execute the userfile
  result = interpreter.execute_file(RealFile.new(filename), userfile_stack)

  # If the stackdump flag was set
  # display the userstack at the end of execution
  if flags.includes? "stackdump"
    puts userfile_stack
  end
end
