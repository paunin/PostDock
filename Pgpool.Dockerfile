FROM debian:jessie
ENV DOCKERIZE_VERSION v0.2.0

RUN echo deb http://debian.xtdv.net/debian jessie main > /etc/apt/sources.list && apt-get update

RUN apt-get install -y libffi-dev libssl-dev pgpool2 wget
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY ./bin_pgpool /usr/local/bin/pgpool
COPY ./configs_pgpool /var/pgpool_configs

RUN chmod +x -R /usr/local/bin/pgpool

CMD ["/usr/local/bin/pgpool/entrypoint.sh"]