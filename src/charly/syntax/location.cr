require "../../file.cr"

class Location
  property pos : Int32
  property row : Int32
  property column : Int32
  property length : Int32
  property passed_return : Bool
  property file : VirtualFile?

  def initialize(@pos = 0, @row = 0, @column = 0, @length = 0, @passed_return = false)
  end

  def to_s(io)
    io << "#{@file.try &.filename}:"
    io << "#{@row}:#{@column}".ljust(9, ' ')
  end
end
