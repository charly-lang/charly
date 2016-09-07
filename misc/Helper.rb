$debug = ARGV.include? '--log'

class Time
  def to_ms
    (self.to_f * 1000.0).to_i
  end
end

class String
  def indent(amount, prefix)
    self.each_line.map {|line|
      (prefix * amount) + line
    }.join ""
  end
end

$starttime = Time.now.to_ms
def dlog(message)
  puts "|#{Time.now.to_ms - $starttime}| #{message}" if $debug
end
dlog "Starting up!"
