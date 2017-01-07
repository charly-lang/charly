find . -name ".DS_Store" | xargs rm
find . -name "**/*.swp" | xargs rm
find . -name "**/*.swo" | xargs rm
rm -rf bin
rm -rf doc
