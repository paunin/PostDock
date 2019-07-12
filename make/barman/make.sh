echo ">>> Making barman"

for VALS in "BARMAN_VERSION=2.3 BARMAN_PACKAGE_VERSION=2.3-2.pgdg90+1"\
            "BARMAN_VERSION=2.4 BARMAN_PACKAGE_VERSION=2.4-1.pgdg90+1"; do
    eval $VALS

    for PG_CLIENT_VERSION in 9.6 10 11; do
        VALS="BARMAN_VERSION=$BARMAN_VERSION PG_CLIENT_VERSION=$PG_CLIENT_VERSION PG_CLIENT_LATEST=1"
        FILE_FROM="./src/includes/dockerfile/Barman-$BARMAN_VERSION.part.Dockerfile"
        FILE_TO="./src/Barman-$BARMAN_VERSION-Postgres-$PG_CLIENT_VERSION.Dockerfile"

        template $FILE_FROM $FILE_TO $VALS
    done
done
