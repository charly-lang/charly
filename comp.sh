
# Reset the terminal
clear

# Set some needed variables
export CHARLYDIR=./src/charly/std-lib

# Build the interpreter
crystal build src/charly.cr -o bin/charly

# Execute the interpeter with the given arguments
time bin/charly $@
