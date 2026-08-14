#!/bin/sh
set -e

# The upstream mysql:8.4 entrypoint refuses to start an uninitialized
# database without one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD,
# or MYSQL_RANDOM_ROOT_PASSWORD, but its error message gives no hint that
# this is a Railway service variable. Fail fast with guidance instead of
# falling through to the generic upstream error and a silent restart loop.
if [ -z "$MYSQL_ROOT_PASSWORD" ] && [ -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ] && [ -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
  if [ ! -d "/var/lib/mysql/mysql" ]; then
    cat >&2 <<-'EOF'

	[Entrypoint] MYSQL_ROOT_PASSWORD is not set.

	This template requires a root password before the first deploy:
	  1. Open your Railway project -> this service -> Variables.
	  2. Add MYSQL_ROOT_PASSWORD and generate a secret value.
	  3. Redeploy the service.

	See README.md for details.

EOF
    exit 1
  fi
fi

exec docker-entrypoint.sh "$@"
