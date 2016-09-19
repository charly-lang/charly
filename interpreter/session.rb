require_relative "../misc/Helper.rb"

class Session
  attr_accessor :files, :returnvalues
  def initialize
    @files = []
    @returnvalues = {}
  end

  # Check if a given file was already included
  def has_file(fullpath)
    found = false
    @files.each do |file|
      unless found
        found = file.fullpath == fullpath
      end
    end
    found
  end

  def return_value_of_file(fullpath)
    @returnvalues[fullpath]
  end

  def add_return_value(fullpath, value)
    @returnvalues[fullpath] = value
  end
end
