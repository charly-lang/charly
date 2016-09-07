# Represents a single file
class VirtualFile
  attr_reader :filename,
              :fullpath,
              :directory,
              :size,
              :virtual,
              :content

  # Create a file from a real file existing on the file system
  def self.new_from_path(path)

    # Set basic attributes
    @filename = File.basename path
    @fullpath = File.absolute_path path
    @directory = File.dirname path
    @size = File.size path
    @virtual = false
    @content = File.open(path, "r").read
  end

  # Creates a new virtual file from a given string
  def self.new_from_string(string)

    # Set basic attributes
    timestamp = Time.now.getutc
    @filename = "VIRTUAL-#{timestamp}"
    @fullpath = "/VIRTUAL/VIRTUAL-#{timestamp}"
    @directory = "/VIRTUAL"
    @size = string.size
    @virtual = true
    @content = string
  end

  def [](i)
    @content[i]
  end

  def each_line
    @content.each_line do |line|
      yield line
    end
  end
end
