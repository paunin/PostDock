#!/usr/bin/env bash
set -x
set -e

EXTENSIONS="$1"
apt-get update
echo "> Will install extensions: $EXTENSIONS"
dir=$(pwd)
for EXTENSION in $EXTENSIONS;
do
    echo ">>> Installing now $EXTENSION"
    source /extensions_installer/extensions/$EXTENSION/install.sh
    cd $dir
done
apt-get clean