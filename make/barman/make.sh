echo ">>> Making barman"
FILE_FROM="./src/includes/dockerfile/Barman-2.3.part.Dockerfile"

for VALS in "PG_CLIENT_VERSION=9.6;PG_CLIENT_PACKAGE_VERSION=9.6" "PG_CLIENT_VERSION=10;PG_CLIENT_PACKAGE_VERSION=10.2"; do

    PG_CLIENT_VERSION=`echo $VALS | cut -d ";" -f2 | cut -d '=' -f2`

    echo ">>>>>> Making BARMAN_VERSION=2.3;$VALS"
    FILE_TO="./src/Barman-2.3-Postgres-$PG_CLIENT_VERSION.Dockerfile"
    VALS="$VALS;BARMAN_VERSION=2.3-2.pgdg80+1"
    flush $FILE_TO
    template $FILE_FROM $FILE_TO $VALS
done
