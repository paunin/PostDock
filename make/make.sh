# Script to build final Dockerfile-s for different versions of components
set -e

BUILD_NUMBER=`date`

function flush {
    MARKER_LINE="BUILD_NUMBER=$BUILD_NUMBER"
    FILE="$1"
    if [[ `grep "$MARKER_LINE" $FILE | wc -l | tr -d ' '` == "0" ]]; then
        echo "
##########################################################################
##                         AUTO-GENERATED FILE                          ##
##               $MARKER_LINE              ##
##########################################################################
" > $FILE 
    fi
}

function template {
    TEMPLATE_FILE_FROM="$1"
    TEMPLATE_FILE_TO="$2"
    CONFIGS="${@:3}"
    flush $TEMPLATE_FILE_TO

    echo ">>>>>> $CONFIGS"
    eval "$CONFIGS" mo $TEMPLATE_FILE_FROM >> $TEMPLATE_FILE_TO
}
    
# Getting templates processor
if [ ! -f "tmp/mo" ]; then
    echo "> Getting Mustache template processor Mo"
    mkdir tmp
    curl -sSL https://git.io/get-mo > tmp/mo
    chmod +x tmp/mo
fi

. ./tmp/mo
# Making
for SYSTEM in `find ./make/* -maxdepth 1 -type d`; do
    echo "> Processing $SYSTEM"
    source $SYSTEM/make.sh
done
