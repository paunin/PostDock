echo ">>> Making barman"

echo ">>>>>> Making v2.3"
FILE_FROM="./src/includes.Dockerfile/Barman-2.3.part.Dockerfile"
FILE_TO="./src/Barman-2.3.Dockerfile"
flush $FILE_TO
template $FILE_FROM $FILE_TO 'BARMAN_VERSION=2.3-2.pgdg80+1'