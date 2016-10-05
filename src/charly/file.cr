abstract class VirtualFile
  property filename : String
  property fullpath : String
  property fulldirectorypath : String
  property directory : String
  property size : UInt64
  property content : String

  def initialize
    @filename = nil
    @fullpath = nil
    @fulldirectorypath = nil
    @directory = nil
    @size = nil
    @content = nil
  end

  # Yields each line of the file
  def each_line
    @content.each_line do |line|
      yield line
    end
  end

  def to_s
    @content
  end
end

# A virtual file
class EvalFile < VirtualFile
  def initialize(content)
    @filename = "virtual-#{Time.new}.charly"
    @fullpath = "/virtual/#{@filename}"
    @fulldirectorypath = "/virtual"
    @directory = "virtual"
    @size = content.length
    @content = content
  end
end

# A real file that exists on the filesystem
class RealFile < VirtualFile
  def initialize(path)
    @filename = File.basename path
    @fullpath = File.expand_path path
    @fulldirectorypath = File.dirname @fullpath
    @directory = File.dirname path
    @size = File.size path
    @content = File.read path
  end
end
