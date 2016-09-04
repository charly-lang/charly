class String
  def indent(amount, prefix)
    self.each_line.map {|line|
      (prefix * amount) + line
    }.join ""
  end
end

class Time
  def to_ms
    (self.to_f * 1000.0).to_i
  end
end
