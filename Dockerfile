FROM mysql:8.4

# curl is required by docker-entrypoint-wrapper.sh for the optional
# first-init dump import (MYSQL_INIT_DUMP_URL). mysql:8.4 is built on
# Oracle Linux 9 (oraclelinux9-slim) and uses microdnf, not apt/apk.
# gzip is already installed by the upstream image (used for its native
# *.sql.gz support), reused here for our own compression detection.
RUN if ! command -v curl >/dev/null 2>&1; then microdnf install -y curl-minimal; fi \
 && microdnf clean all

ENV MYSQL_DATABASE=app

COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

EXPOSE 3306

HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" --silent || exit 1

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]
CMD ["mysqld"]
