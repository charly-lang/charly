class Location
  attr_reader :file, :row

  def initialize(file, row)
    @file = file
    @row = row
  end

  # Return the filename of the location
  def filename
    @file.filename
  end

  def to_s
    "#{filename}:#{row}"
  end
end
