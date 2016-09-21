require_relative "Helper.rb"

# Represents a single file
class VirtualFile
  attr_accessor :filename, :fullpath, :fulldirectorypath, :directory, :size, :content

  def [](i)
    @content[i]
  end

  def each_line
    @content.each_line do |line|
      yield line
    end
  end

  def to_s
    @content
  end
end

# Reads a file from the filesystem
# Initializer needs the path to the file
class RealFile < VirtualFile
  def initialize(path)
    @filename = File.basename path
    @fullpath = File.absolute_path path
    @fulldirectorypath = File.dirname @fullpath
    @directory = File.dirname path
    @size = File.size path

    # Logging and actual file reading
    @content = File.open(path, "r").read
  end
end

# A virtual file
# *filename* can be a name that will then be given to the file
class EvalFile < VirtualFile
  def initialize(content, filename = nil)
    @filename = filename || "virtual-#{Time.new}.charly"
    @fullpath = "/virtual/#{@filename}"
    @fulldirectorypath = "/virtual"
    @directory = "virtual"
    @size = content.length
    @content = content
  end
end
