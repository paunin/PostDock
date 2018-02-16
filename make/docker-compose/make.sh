echo ">>> Making docker-compose"

FILE_FROM='./src/includes/docker-compose/docker-compose.yml'
for POSTGRES_VERSION in 9.5 9.6 10.2; do
    for REPMGR_VERSION in 3.2; do
        for PGPOOL_VERSION in 3.3 3.6; do
            for BARMAN_VERSION in 2.3; do
                
                # For postgres 9.5 we can use client 9.6
                if [[ "$POSTGRES_VERSION" = "9.5" ]];then 
                    PGPOOL_POSTGRES_CLIENT_VERSION="9.6"
                    BARMAN_POSTGRES_CLIENT_VERSION="9.6"
                else
                    PGPOOL_POSTGRES_CLIENT_VERSION="$POSTGRES_VERSION"
                    BARMAN_POSTGRES_CLIENT_VERSION="$POSTGRES_VERSION"
                fi

                VALS="POSTGRES_VERSION=$POSTGRES_VERSION;PGPOOL_VERSION=$PGPOOL_VERSION;BARMAN_VERSION=$BARMAN_VERSION;REPMGR_VERSION=$REPMGR_VERSION;PGPOOL_POSTGRES_CLIENT_VERSION=$PGPOOL_POSTGRES_CLIENT_VERSION;BARMAN_POSTGRES_CLIENT_VERSION=$BARMAN_POSTGRES_CLIENT_VERSION"
                echo ">>>>>> Making $VALS"

                FILE_TO="./docker-compose/postgres-${POSTGRES_VERSION}_pgpool-${PGPOOL_VERSION}_barman-${BARMAN_VERSION}.yml"
                flush $FILE_TO
                template $FILE_FROM $FILE_TO $VALS
            done
        done
    done
done