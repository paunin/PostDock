echo ">>> Making travis"

FILE_FROM="./src/includes/travis/travis.part.yml"
FILE_TO=".travis.yml"

export TEST_COMBINATIONS=(`ls -r docker-compose | grep '.yml' | xargs -I % basename % '.yml'`) 
template $FILE_FROM $FILE_TO


