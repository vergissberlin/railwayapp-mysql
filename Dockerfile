FROM mysql:26.7

ENV MYSQL_DATABASE=app

COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

EXPOSE 3306

HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" --silent || exit 1

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]
CMD ["mysqld"]
