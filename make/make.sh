# Script to build final Dockerfile-s for different versions of components
set -e

function flush {
    FILE="$1"
    echo '
##########################################################################
##   AUTO-GENERATED FILE FROM ./includes.Dockerfile by ./make/make.sh   ##
##########################################################################
' > $FILE 

}

function template {
    TEMPLATE_FILE_FROM="$1"
    TEMPLATE_FILE_TO="$2"
    CONFIGS="$3"
    TMP_FILE="/tmp/make.postdock.tmp"
    TMP_FILE_PART="/tmp/make.postdock.tmp.part"
    
    cp -f $TEMPLATE_FILE_FROM $TMP_FILE

    IFS=';' read -ra CONFIG_PAIRS <<< "$CONFIGS"
    for CONFIG_PAIR in "${CONFIG_PAIRS[@]}"
    do
        IFS='=' read -ra CONFIG <<< "$CONFIG_PAIR"
        VAR="${CONFIG[0]}"
        VAL="${CONFIG[1]}"
        sed -e "s/{{\ *$VAR\ *}}/$VAL/g" $TMP_FILE > $TMP_FILE_PART
        mv -f $TMP_FILE_PART ${TMP_FILE}
    done

    cat $TMP_FILE >> $TEMPLATE_FILE_TO
    rm -f $TMP_FILE 
}

for SYSTEM in `find ./make/* -maxdepth 1 -type d`; do
    source $SYSTEM/make.sh
done
