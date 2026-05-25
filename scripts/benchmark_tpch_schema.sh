#!/usr/bin/env bash

set -euo pipefail

TARGET_SCHEMA=${TARGET_SCHEMA:-monet}
TARGET_PORT=${TARGET_PORT:-5433}
TARGET_DB=${TARGET_DB:-monet_test}
OUTPUT_TSV=${OUTPUT_TSV:-}

if [[ -z "$OUTPUT_TSV" ]]; then
	OUTPUT_TSV="tpch_regression_${TARGET_SCHEMA}_pg19.tsv"
fi

tmp_output=$(mktemp)
trap 'rm -f "$tmp_output"' EXIT

TARGET_SCHEMA="$TARGET_SCHEMA" \
TARGET_PORT="$TARGET_PORT" \
TARGET_DB="$TARGET_DB" \
	./scripts/run_tpch_all_sql.sh > "$tmp_output"

LC_ALL=C awk -v schema="$TARGET_SCHEMA" '
	BEGIN {
		print "query\tstatus\ttime_ms\tshape\tnotes";
		query = 0;
	}
	/Execution Time:/ {
		query++;
		time_ms = $(NF-1);
		gsub(",", ".", time_ms);
		printf "Q%02d\tOK\t%.3f\tBENCH\tfull all.sql run on PostgreSQL 19 schema %s\n", query, time_ms, schema;
	}
' "$tmp_output" > "$OUTPUT_TSV"

LC_ALL=C awk -F '\t' '
	NR == 1 {
		next;
	}
	{
		sum += $3;
		count++;
	}
	END {
		printf "queries=%d\n", count;
		printf "total_ms=%.3f\n", sum;
		if (count > 0)
			printf "avg_ms=%.3f\n", sum / count;
	}
' "$OUTPUT_TSV"