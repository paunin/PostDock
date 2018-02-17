echo ">>> Making postgres"

for POSTGRES_VERSION in 9.5 9.6 10.2; do
    for REPMGR_VERSION in 3.2; do
        FILE_FROM="./src/includes/dockerfile/Postgres-$POSTGRES_VERSION-Repmgr-$REPMGR_VERSION.part.Dockerfile"
        FILE_FROM_EXT="./src/includes/dockerfile/Postgres-extended-$POSTGRES_VERSION-Repmgr-$REPMGR_VERSION.part.Dockerfile"

        VALS="POSTGRES_VERSION=$POSTGRES_VERSION"
        FILE_TO="./src/Postgres-$POSTGRES_VERSION-Repmgr-$REPMGR_VERSION.Dockerfile"

        template $FILE_FROM $FILE_TO $VALS

        FILE_TO_EXT="./src/Postgres-extended-$POSTGRES_VERSION-Repmgr-$REPMGR_VERSION.Dockerfile"

        template $FILE_FROM $FILE_TO_EXT $VALS
        template $FILE_FROM_EXT $FILE_TO_EXT
    done
done