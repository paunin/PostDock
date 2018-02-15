echo ">>> Making postgres"

FILE_FROM='./src/includes/docker-compose/docker-compose.yml'
for POSTGRES_VERSION in 9.5 9.6 10.2; do
    for PGPOOL_VERSION in 3.3 3.6; do
        for BARMAN_VERSION in 2.3; do
            echo ">>> Making POSTGRES_VERSION=$POSTGRES_VERSION PGPOOL_VERSION = $PGPOOL_VERSION BARMAN_VERSION=$BARMAN_VERSION"

            VALS="POSTGRES_VERSION=$POSTGRES_VERSION;PGPOOL_VERSION=$PGPOOL_VERSION;BARMAN_VERSION=$BARMAN_VERSION;REPMGR_VERSION=3.2"
            FILE_TO="./docker-compose/postgres-${POSTGRES_VERSION}_pgpool-${PGPOOL_VERSION}_barman-${BARMAN_VERSION}.yml"
            flush $FILE_TO
            template $FILE_FROM $FILE_TO $VALS
        done
    done
done