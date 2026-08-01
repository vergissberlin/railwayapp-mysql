FROM mysql:8.4

ENV MYSQL_DATABASE=app

EXPOSE 3306

HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" --silent || exit 1
