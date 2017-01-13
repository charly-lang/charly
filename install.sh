sudo -v

mkdir -p bin
crystal build src/charly.cr --release --stats -o bin/charly

sudo cp bin/charly /usr/local/bin/charly

echo ""
echo "Don't forget to set \$CHARLYDIR to $(pwd)"
echo "You have to add the following line to your shell config file (.bashrc, .zshrc, etc)"
echo ""
echo "export CHARLYDIR="$(pwd)
