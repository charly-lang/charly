require "colorize"
require "./lexer/location.cr"

class ErrorPresenter

  # Properties we need from the outside
  property file : VirtualFile
  property row : Int32
  property column : Int32
  property pos : Int32
  property length : Int32

  def initialize(location)

    unless (file = location.file).is_a? VirtualFile
      raise "ErrorPresenter could not find valid file"
    end

    @file = file
    @row = location.row
    @column = location.column
    @pos = location.pos
    @length = location.length
  end

  def present

    # The range we want to color red
    column_range = (@column..(@column + @length - 1))

    # The range of rows we want to print
    print_range = ((@row - 2)..(@row))
    nocolor_range = ((@row - 2)..(@row - 1))

    # Iterate over all lines
    io = MemoryIO.new(@file.content)
    ln = 1
    io.each_line do |line|

      # Skip over lines we don't want to print
      unless print_range === ln
        ln += 1
        next
      end

      # If we reached the end of the lines
      # we want to print, break
      if ln > @row
        break
      end

      # Print the line number
      print "#{ln}.".colorize(:yellow)
      print " "

      # The lines we simply want to
      if nocolor_range === ln
        print line
      else

        # This is the offending row
        c = 1
        line.each_char do |char|

          if column_range === c
            print char.colorize(:white).back(:red)
          else
            print char
          end

          c += 1
        end
      end

      # Increment the row counter
      ln += 1
    end

    # Show a nice arrow for terminals
    # that don't support coloring
    print " " * "#{@row}".size
    print "  "
    (@column - 1).times do
      print '~'.colorize(:red)
    end
    print '^'.colorize(:red)
    print '\n'
  end
end
