# Don Morehouse
#Thanks for letting me check out your code!! - Jasmine
#More Forks
require_relative './prompters'
require_relative './world'


LINE = "*" * 79
CLEAR = `tput clear`

def line
  puts LINE
  puts
end

def show_wait_cursor(seconds,fps=10)
  chars = %w[| / - \\]
  delay = 1.0/fps
  (seconds*fps).round.times{ |i|
    print chars[i % chars.length]
    sleep delay
    print "\b"
  }
end

message = <<EOL


Welcome to a Wyncode Fort Lauderdale Cohort 5 Voter Simulation!

This program creates politicians and voters.

Assumptions:
* Both voters and politicians have a first and last name.
* Politicians have a political party.
* Voters have a political leaning.
* Each politician name and each voter name must be unique.
* It is possible to have a politician and a voter with the same name.

EOL

puts CLEAR
puts Messages::colorize(message, :black, :white)
show_wait_cursor(1)
puts Messages::colorize("Press a key to continue…", :green, :black)
gets
puts CLEAR
world = WorldUserInterface.new
world.wait_for_answer :main_menu
