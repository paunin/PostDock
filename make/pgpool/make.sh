echo ">>> Making pgpool"

FILE_FROM='./src/includes.Dockerfile/Pgpool-3.3-3.6.part.Dockerfile'

echo ">>>>>> Making v3.3"
FILE_TO="./src/Pgpool-3.3.Dockerfile"
flush $FILE_TO
template $FILE_FROM $FILE_TO 'PGPOOL_VERSION=3.3.4\\*'

echo ">>>>>> Making v3.6"
FILE_TO="./src/Pgpool-3.6.Dockerfile"
flush $FILE_TO
template $FILE_FROM $FILE_TO 'PGPOOL_VERSION=3.6\\*'