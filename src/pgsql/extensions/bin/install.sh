#!/usr/bin/env bash
set -x

EXTENSIONS="$1"
apt-get update
echo "> Will install extensions: $EXTENSIONS"

for EXTENSION in $EXTENSIONS;
do
    echo ">>> Installing now $EXTENSION"
    source /extensions_installer/extensions/$EXTENSION/install.sh
done
apt-get clean