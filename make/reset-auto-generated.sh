#!/bin/bash

if [ ! -f ./make/make.sh ]; then
    echo "Must run in the root of the repository."
    exit 1
fi

if [ -z $1 ]; then
    echo "Usage $0 (reset|delete|restore)"
    exit 1
fi

if [ $1 == "reset " ]; then
    # Discards local changes in the AUTO-GENERATED files (makes easier to check real changes)
    for FILE in `grep -rl "AUTO-GENERATED FILE"  . | egrep -v "./make/make.sh"  `; do 
        git checkout -- $FILE
    done 
elif [ $1 == "delete " ]; then
    FILES=`grep -rl "AUTO-GENERATED FILE"  . | egrep -v "./make/make.sh"  `
    tar zcvf bkp-auto-generated-files.tar.gz $FILES 
    if [ $? -eq 0 ]; then 
        rm $FILES
    fi
elif [ $1 == "restore " ]; then
    tar zxvf bkp-auto-generated-files.tar.gz
fi
