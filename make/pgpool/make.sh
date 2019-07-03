echo ">>> Making pgpool"

for VALS in "PGPOOL_VERSION=3.3 PGPOOL_PACKAGE_VERSION=3.3.4-1.pgdg70+1" \
            "PGPOOL_VERSION=3.6 PGPOOL_PACKAGE_VERSION=3.6.7-1.pgdg90+1" \
            "PGPOOL_VERSION=3.7 PGPOOL_PACKAGE_VERSION=3.7.5-2.pgdg90+1";  do
    eval $VALS

    for PG_CLIENT_VERSION in 9.6 10 11; do
        VALS="$VALS PG_CLIENT_VERSION=$PG_CLIENT_VERSION PG_CLIENT_LATEST=1"

        FILE_FROM="./src/includes/dockerfile/Pgpool-$PGPOOL_VERSION.part.Dockerfile"
        FILE_TO="./src/Pgpool-$PGPOOL_VERSION-Postgres-$PG_CLIENT_VERSION.Dockerfile"

        template $FILE_FROM $FILE_TO $VALS
    done
done
unset PGPOOL_VERSION PGPOOL_PACKAGE_VERSION VALS
