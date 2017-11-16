ARG EXTENSIONS="pgosm postgis nominatim"
COPY ./pgsql/extensions/bin/ /extensions_installer/
RUN chmod -R +x /extensions_installer/ && bash /extensions_installer/install.sh "$EXTENSIONS"