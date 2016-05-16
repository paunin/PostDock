FROM debian:jessie

RUN echo deb http://debian.xtdv.net/debian jessie main > /etc/apt/sources.list && apt-get update

RUN apt-get install -y libffi-dev libssl-dev pgpool2

COPY ./bin_pgpool /usr/local/bin/pgpool
COPY ./configs_pgpool /var/pgpool_configs

RUN chmod +x -R /usr/local/bin/pgpool

ENV SEARCH_PRIMARY_NODE_TIMEOUT 10

CMD ["/usr/local/bin/pgpool/entrypoint.sh"]