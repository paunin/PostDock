ARG EXTENSIONS="pg_repack pglogical pgosm postgis pgl_ddl_deploy pg_nominatim"
COPY ./pgsql/extensions/bin/ /extensions_installer/
RUN chmod -R +x /extensions_installer/ && bash /extensions_installer/install.sh "$EXTENSIONS"
