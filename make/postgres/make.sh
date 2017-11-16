echo ">>> Making postgres"

FILE_FROM='./includes.Dockerfile/Postgres-9.5-9.6.part.Dockerfile'
FILE_FROM_EXT='./includes.Dockerfile/Postgres-extended-9.5-9.6.part.Dockerfile'
for POSTGRES_VERSION in 9.5 9.6; do
    echo ">>> Making v.$POSTGRES_VERSION"
    
    VALS="POSTGRES_VERSION=$POSTGRES_VERSION"
    FILE_TO="./Postgres-$POSTGRES_VERSION.Dockerfile"
    
    flush $FILE_TO
    template $FILE_FROM $FILE_TO $VALS
    
    echo ">>> Making v.$POSTGRES_VERSION extended"
    FILE_TO_EXT="./Postgres-extended-$POSTGRES_VERSION.Dockerfile"
    flush $FILE_TO_EXT

    template $FILE_FROM $FILE_TO_EXT $VALS
    template $FILE_FROM_EXT $FILE_TO_EXT
done