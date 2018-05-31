# Script to build final Dockerfile-s for different versions of components
set -e

BUILD_NUMBER=`date`
SYSTEM_TO_MAKE="$1"

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
    echo -n ">>>>>> "
    if [ "$CONFIGS" == "" ];then
        echo "(no configs)"
    else
        echo "CONFIGS: $CONFIGS"
    fi
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
for SYSTEM_PATH in `find ./make/* -maxdepth 1 -type d`; do
    SYSTEM=`basename $SYSTEM_PATH`
    if [ "$SYSTEM_TO_MAKE" != "" ] && [ "$SYSTEM_TO_MAKE" != "$SYSTEM" ]; then
        echo "> Skipping $SYSTEM as it's not required to build (SYSTEM_TO_MAKE=$SYSTEM_TO_MAKE)"
        continue
    fi
    echo "> Making $SYSTEM ($SYSTEM_PATH)"
    source $SYSTEM_PATH/make.sh
done
