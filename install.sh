sudo -v

mkdir -p bin
crystal build src/charly.cr --release -o bin/charly

sudo cp bin/charly /usr/bin/charly

echo "Don't forget to set \$CHARLYDIR to $(pwd)/src/charly/std-lib"
