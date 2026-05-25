#!/usr/bin/env bash

set -euo pipefail

PG_RUNNER=${PG_RUNNER:-"sudo -n -u postgres"}
TARGET_PORT=${TARGET_PORT:-5433}
TARGET_DB=${TARGET_DB:-monet_test}
TARGET_SCHEMA=${TARGET_SCHEMA:-monet}

if [[ ! "$TARGET_SCHEMA" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
	printf 'TARGET_SCHEMA must be a simple SQL identifier, got: %s\n' "$TARGET_SCHEMA" >&2
	exit 1
fi

read -r -a pg_runner_cmd <<< "$PG_RUNNER"

sed "0,/^set search_path to monet;$/s//set search_path to ${TARGET_SCHEMA};/" sql/all.sql |
	"${pg_runner_cmd[@]}" psql -X -v ON_ERROR_STOP=1 -p "$TARGET_PORT" -d "$TARGET_DB"