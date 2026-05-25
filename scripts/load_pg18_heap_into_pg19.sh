#!/usr/bin/env bash

set -euo pipefail

PG_RUNNER=${PG_RUNNER:-"sudo -n -u postgres"}
SRC_PORT=${SRC_PORT:-5432}
SRC_DB=${SRC_DB:-tpch}
SRC_SCHEMA=${SRC_SCHEMA:-pg}
DST_PORT=${DST_PORT:-5433}
DST_DB=${DST_DB:-monet_test}
DST_SCHEMA=${DST_SCHEMA:-pg}

if [[ "$SRC_SCHEMA" != "$DST_SCHEMA" ]]; then
	printf 'SRC_SCHEMA (%s) and DST_SCHEMA (%s) must match for this loader.\n' \
		"$SRC_SCHEMA" "$DST_SCHEMA" >&2
	exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
chmod 755 "$tmpdir"

schema_dump="$tmpdir/schema.sql"
data_dump="$tmpdir/data.sql"

read -r -a pg_runner_cmd <<< "$PG_RUNNER"

"${pg_runner_cmd[@]}" pg_dump --no-owner --no-privileges --schema-only \
	-p "$SRC_PORT" -d "$SRC_DB" -n "$SRC_SCHEMA" > "$schema_dump"
"${pg_runner_cmd[@]}" pg_dump --no-owner --no-privileges --data-only \
	-p "$SRC_PORT" -d "$SRC_DB" -n "$SRC_SCHEMA" > "$data_dump"
chmod 644 "$schema_dump" "$data_dump"

"${pg_runner_cmd[@]}" psql -X -v ON_ERROR_STOP=1 -p "$DST_PORT" -d "$DST_DB" \
	-c "DROP SCHEMA IF EXISTS \"$DST_SCHEMA\" CASCADE;"
"${pg_runner_cmd[@]}" psql -X -v ON_ERROR_STOP=1 -p "$DST_PORT" -d "$DST_DB" \
	-f "$schema_dump"
"${pg_runner_cmd[@]}" psql -X -v ON_ERROR_STOP=1 -p "$DST_PORT" -d "$DST_DB" \
	-f "$data_dump"
"${pg_runner_cmd[@]}" psql -X -v ON_ERROR_STOP=1 -p "$DST_PORT" -d "$DST_DB" \
	-c "ANALYZE \"$DST_SCHEMA\".customer; ANALYZE \"$DST_SCHEMA\".lineitem; ANALYZE \"$DST_SCHEMA\".nation; ANALYZE \"$DST_SCHEMA\".orders; ANALYZE \"$DST_SCHEMA\".part; ANALYZE \"$DST_SCHEMA\".partsupp; ANALYZE \"$DST_SCHEMA\".region; ANALYZE \"$DST_SCHEMA\".supplier;"
"${pg_runner_cmd[@]}" psql -X -P pager=off -p "$DST_PORT" -d "$DST_DB" \
	-c "SELECT 'customer' AS table_name, count(*) AS rows FROM \"$DST_SCHEMA\".customer UNION ALL SELECT 'lineitem', count(*) FROM \"$DST_SCHEMA\".lineitem UNION ALL SELECT 'nation', count(*) FROM \"$DST_SCHEMA\".nation UNION ALL SELECT 'orders', count(*) FROM \"$DST_SCHEMA\".orders UNION ALL SELECT 'part', count(*) FROM \"$DST_SCHEMA\".part UNION ALL SELECT 'partsupp', count(*) FROM \"$DST_SCHEMA\".partsupp UNION ALL SELECT 'region', count(*) FROM \"$DST_SCHEMA\".region UNION ALL SELECT 'supplier', count(*) FROM \"$DST_SCHEMA\".supplier ORDER BY 1;"