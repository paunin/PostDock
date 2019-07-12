echo ">>> Making docker-compose"

FILE_FROM='./src/includes/docker-compose/docker-compose.yml'
for POSTGRES_VERSION in 9.5 9.6 10 11; do
    for POSTGRES_EXTENDED in '' '1'; do
        for REPMGR_VERSION in 3.2 4.0; do
            for PGPOOL_VERSION in 3.3 3.6 3.7; do
                for BARMAN_VERSION in 2.3 2.4; do
                    # postgres 11 and repmgr 3.2 are not compatible
                    if [[ "$POSTGRES_VERSION" = "11" ]] && [[ "$REPMGR_VERSION" = "3.2" ]];then
                        continue
                    fi
                    # For postgres 9.5 we can use client 9.6
                    if [[ "$POSTGRES_VERSION" = "9.5" ]];then
                        PGPOOL_POSTGRES_CLIENT_VERSION="9.6"
                        BARMAN_POSTGRES_CLIENT_VERSION="9.6"
                    else
                        PGPOOL_POSTGRES_CLIENT_VERSION="$POSTGRES_VERSION"
                        BARMAN_POSTGRES_CLIENT_VERSION="$POSTGRES_VERSION"
                    fi
                    FILE_EXTENDED_SUFFIX=""
                    if [[ "$POSTGRES_EXTENDED" == "1" ]];then
                        FILE_EXTENDED_SUFFIX="-extended"
                    fi
                    VALS="POSTGRES_EXTENDED=$POSTGRES_EXTENDED FILE_EXTENDED_SUFFIX=$FILE_EXTENDED_SUFFIX POSTGRES_VERSION=$POSTGRES_VERSION PGPOOL_VERSION=$PGPOOL_VERSION BARMAN_VERSION=$BARMAN_VERSION REPMGR_VERSION=$REPMGR_VERSION PGPOOL_POSTGRES_CLIENT_VERSION=$PGPOOL_POSTGRES_CLIENT_VERSION BARMAN_POSTGRES_CLIENT_VERSION=$BARMAN_POSTGRES_CLIENT_VERSION"

                    FILE_TO="./docker-compose/postgres${FILE_EXTENDED_SUFFIX}-${POSTGRES_VERSION}_repmgr-${REPMGR_VERSION}_pgpool-${PGPOOL_VERSION}_barman-${BARMAN_VERSION}.yml"
                    template $FILE_FROM $FILE_TO $VALS
                done
            done
        done
    done
done
