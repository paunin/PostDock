echo ">>> Making travis"

FILE_FROM="./src/includes/travis/travis.part.yml"
FILE_HEADER="./src/includes/travis/header.part.yml"
FILE_TO=".travis.yml"

template $FILE_HEADER $FILE_TO

export TEST_COMBINATIONS=(`ls -r docker-compose | grep '.yml' | grep -v 'extended' | xargs -I % basename % '.yml'`)
template $FILE_FROM $FILE_TO
