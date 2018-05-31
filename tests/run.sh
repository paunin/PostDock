#!/bin/bash

if [[ "$NO_COLOURS" != "1" ]]; then
    RESTORE='\033[0m'
    RED='\033[00;31m' GREEN='\033[00;32m' YELLOW='\033[00;33m' BLUE='\033[00;34m' PURPLE='\033[00;35m' CYAN='\033[00;36m'
fi

TESTS_SUCCEED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

TESTS_NAMES=$1

if [[ "$TESTS_NAMES" != "" ]]; then
    TESTS="$TESTS_NAMES"
    SHOW_OUTPUT=1
else
    TESTS=`ls -d ./tests/*/run.sh | cut -f3 -d'/'`
fi
if [[ "$TEST_COMBINATIONS" == "" ]]; then
    TEST_COMBINATIONS=`ls docker-compose | grep '.yml' | grep -v '^latest.yml$' | xargs -I % basename % '.yml'`
fi

FAILED_TESTS=()
echo -e "${BLUE}=====================PostDock tests======================${RESTORE}"
for TEST_COMBINATION in $TEST_COMBINATIONS; do
    echo -e "${CYAN}[$TEST_COMBINATION]${RESTORE}"
    COMPOSE_FILE="./docker-compose/$TEST_COMBINATION.yml"
    if [[ ! -f $COMPOSE_FILE ]]; then
        echo -e "${YELLOW}File for combination $TEST_COMBINATION ($COMPOSE_FILE) can't be found! Skipping combination!${RESTORE}"
        TESTS_SKIPPED=$((TESTS_SKIPPED+1))
    fi
    export COMPOSE_FILE
    
    if [ "$SKIP_BUILD" == "1" ]; then
        echo ">>> Skipping environment preparation! (SKIP_BUILD=$SKIP_BUILD)"
    else
        echo ">>> Preparing environment:"
        docker-compose down -v && docker-compose build --no-cache > /dev/null
    fi
    
    for TEST in $TESTS; do
        echo -n ">>> Running test $TEST:"
        
        if [[ "$DEBUG" == "1"  ]]; then
            echo -e " ${BLUE}>>>>>>${RESTORE}"
            ./tests/$TEST/run.sh
            TEST_EXIT_CODE=$?
            echo -ne "${BLUE}<<<<<<${RESTORE}"
        else
            TEST_OUTPUT=$(./tests/$TEST/run.sh 2>&1)
            TEST_EXIT_CODE=$?
        fi

        case "$TEST_EXIT_CODE" in
            "0" )
                echo -e "${GREEN} Passed ${RESTORE}"
                TESTS_SUCCEED=$((TESTS_SUCCEED+1))
                ;;
            * )
                echo -e "${RED} Failed ${RESTORE}" "(Output: '${RED}$TEST_OUTPUT${RESTORE}')" 
                TESTS_FAILED=$((TESTS_FAILED+1))
                FAILED_TESTS+=("$TEST_COMBINATION > $TEST")
        esac

        if [[ "$NO_CLEANUP" != "1" ]]; then
            echo ">>> Tear down environment:"
            docker-compose down -v
            sleep 10
        fi
    done
done

echo -e "${BLUE}=========================================================${RESTORE}"
echo -e "${GREEN}>>> Passed: $TESTS_SUCCEED${RESTORE}"
echo -e "${RED}>>> Failed: $TESTS_FAILED${RESTORE}"
printf '   >>> %s\n' "${FAILED_TESTS[@]}"
echo -e "${BLUE}=========================================================${RESTORE}"

exit $TESTS_FAILED