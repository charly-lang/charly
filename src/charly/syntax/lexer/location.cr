require "../../file.cr"

class Location
  property row : Int32
  property column : Int32
  property length : Int32
  property passed_return : Bool
  property file : VirtualFile?

  def initialize
    @row = 0
    @column = 0
    @length = 0
    @passed_return = false
  end
end
