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

# Colored output
def colorize(text, color_code)
  if !ARGV.include? "--nocolor"
    "\e[#{color_code}m#{text}\e[0m"
  else
    text
  end
end
def grey(text); colorize(text, 30) end
def red(text); colorize(text, 31) end
def green(text); colorize(text, 32) end
def yellow(text); colorize(text, 33) end
def blue(text); colorize(text, 34) end
def violet(text); colorize(text, 35) end
def cyan(text); colorize(text, 36) end
def white(text); colorize(text, 37) end

$starttime = Time.now.to_ms
def dlog(message)
  time = colorize('%04s' % (Time.now.to_ms - $starttime), 32)
  puts "|#{time}| #{message}" if $debug
end
dlog "Starting up!"
