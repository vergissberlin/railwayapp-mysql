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

# Optional: import a SQL dump on the very first start of an empty data
# directory. Mirrors the same "is this already initialized?" check mysql's
# own entrypoint uses internally (presence of the "mysql" system schema),
# so we never attempt a download/decode against an already-initialized
# volume, and never re-import on restarts even if the variables stay set.
MYSQL_DATADIR="/var/lib/mysql"
MYSQL_INITDB_DIR="/docker-entrypoint-initdb.d"
MYSQL_DUMP_STAGING="/tmp/mysql-init-dump.bin"

if [ ! -d "$MYSQL_DATADIR/mysql" ]; then
  if [ -n "$MYSQL_INIT_DUMP_URL" ] || [ -n "$MYSQL_INIT_DUMP_BASE64" ]; then
    if [ -n "$MYSQL_INIT_DUMP_URL" ]; then
      if [ -n "$MYSQL_INIT_DUMP_BASE64" ]; then
        echo "[Entrypoint] Both MYSQL_INIT_DUMP_URL and MYSQL_INIT_DUMP_BASE64 are set; URL takes precedence, ignoring MYSQL_INIT_DUMP_BASE64." >&2
      fi
      echo "[Entrypoint] MYSQL_INIT_DUMP_URL set - fetching initial dump for first-time import..."
      if ! curl -fsSL -L --connect-timeout 10 --max-time 300 --retry 3 --retry-delay 2 \
             -o "$MYSQL_DUMP_STAGING" "$MYSQL_INIT_DUMP_URL"; then
        echo "[Entrypoint] ERROR: failed to download dump from MYSQL_INIT_DUMP_URL. Aborting startup rather than silently booting an empty database." >&2
        exit 1
      fi
    else
      echo "[Entrypoint] MYSQL_INIT_DUMP_BASE64 set - decoding initial dump for first-time import..."
      if ! printf '%s' "$MYSQL_INIT_DUMP_BASE64" | base64 -d > "$MYSQL_DUMP_STAGING" 2>/tmp/mysql-b64-err.log; then
        echo "[Entrypoint] ERROR: failed to base64-decode MYSQL_INIT_DUMP_BASE64 (invalid base64?). Aborting startup rather than silently booting an empty database." >&2
        cat /tmp/mysql-b64-err.log >&2 || true
        exit 1
      fi
    fi

    if [ ! -s "$MYSQL_DUMP_STAGING" ]; then
      echo "[Entrypoint] ERROR: resolved init dump is empty. Aborting startup rather than silently booting an empty database." >&2
      exit 1
    fi

    mkdir -p "$MYSQL_INITDB_DIR"
    if gzip -t "$MYSQL_DUMP_STAGING" 2>/dev/null; then
      mv "$MYSQL_DUMP_STAGING" "$MYSQL_INITDB_DIR/00-init-dump.sql.gz"
      echo "[Entrypoint] Placed gzip-compressed dump at $MYSQL_INITDB_DIR/00-init-dump.sql.gz (will be imported by mysql's native docker-entrypoint.sh)."
    else
      mv "$MYSQL_DUMP_STAGING" "$MYSQL_INITDB_DIR/00-init-dump.sql"
      echo "[Entrypoint] Placed plain-text dump at $MYSQL_INITDB_DIR/00-init-dump.sql (will be imported by mysql's native docker-entrypoint.sh)."
    fi
  fi
fi

exec docker-entrypoint.sh "$@"
