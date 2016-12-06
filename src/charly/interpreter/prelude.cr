module Charly
  class PreludeLoader
    def self.load(path, arguments, flags)
      scope = Scope.new

      scope.write("ARGV", load_arguments(arguments), Flag::INIT | Flag::CONSTANT)
      scope.write("IFLAGS", load_flags(flags), Flag::INIT | Flag::CONSTANT)
      scope.write("ENV", load_env, Flag::INIT | Flag::CONSTANT)

      scope
    end

    private def self.load_arguments(arguments)
      argv = [] of BaseType
      arguments.each do |arg|
        argv << TString.new arg
      end
      TArray.new argv
    end

    private def self.load_flags(flags)
      iflags = [] of BaseType
      flags.each do |flag|
        iflags << TString.new flag
      end
      TArray.new iflags
    end

    private def self.load_env
      object = TObject.new
      ENV.each do |key, value|
        object.data.write(key, TString.new(value), Flag::INIT | Flag::CONSTANT)
      end
      object
    end
  end
end
