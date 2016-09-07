require_relative "Helper.rb"

# Represents a single file
class VirtualFile
  attr_reader :filename,
              :fullpath,
              :directory,
              :size,
              :content

  # Create a file from a real file existing on the file system
  def initialize(path)
    # Set basic attributes
    @filename = File.basename path
    @fullpath = File.absolute_path path
    @directory = File.dirname path
    @size = File.size path

    dlog "Reading source file: #{path}"
    @content = File.open(path, "r").read
  end

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
