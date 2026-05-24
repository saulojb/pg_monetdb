/*
 * pg_monetdb--1.2.sql
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_monetdb" to load this file. \quit

CREATE FUNCTION pg_monetdb_handler()
RETURNS fdw_handler
AS 'MODULE_PATHNAME', 'monetdb_fdw_handler'
LANGUAGE C STRICT;

CREATE FUNCTION monetdb_fdw_handler()
RETURNS fdw_handler
AS 'MODULE_PATHNAME', 'monetdb_fdw_handler'
LANGUAGE C STRICT;

CREATE FOREIGN DATA WRAPPER pg_monetdb
  HANDLER pg_monetdb_handler;

CREATE FUNCTION pg_monetdb_execute(server name, statement text) RETURNS void
AS 'MODULE_PATHNAME', 'monetdb_execute'
LANGUAGE C STRICT;

CREATE FUNCTION monetdb_execute(server name, statement text) RETURNS void
AS 'MODULE_PATHNAME', 'monetdb_execute'
LANGUAGE C STRICT;

CREATE FUNCTION pg_monetdb_query(server name, statement text) RETURNS SETOF text
AS 'MODULE_PATHNAME', 'monet_query'
LANGUAGE C STRICT;

CREATE FUNCTION monet_query(server name, statement text) RETURNS SETOF text
AS 'MODULE_PATHNAME', 'monet_query'
LANGUAGE C STRICT;

CREATE FUNCTION pg_monetdb_query_to_array(server name, statement text) RETURNS SETOF text[]
LANGUAGE SQL STRICT
AS $$
    SELECT ARRAY(
        SELECT btrim(value, ' "')
        FROM unnest(
            regexp_split_to_array(
                regexp_replace(raw_line, '^\[\s*|\s*\]$', '', 'g'),
                '\s*,\s*'
            )
        ) AS value
    )
    FROM pg_monetdb_query($1, $2) AS q(raw_line)
$$;

CREATE FUNCTION monet_query_to_array(server name, statement text) RETURNS SETOF text[]
LANGUAGE SQL STRICT
AS $$
    SELECT *
    FROM pg_monetdb_query_to_array($1, $2)
$$;

COMMENT ON FUNCTION pg_monetdb_execute(name, text)
IS 'executes an arbitrary SQL statement with no results on the MonetDB server';

COMMENT ON FUNCTION pg_monetdb_query(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and returns raw result rows as text';

COMMENT ON FUNCTION monet_query(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and returns raw result rows as text';

COMMENT ON FUNCTION pg_monetdb_query_to_array(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and parses each raw row into a text array for simple scalar result sets';

COMMENT ON FUNCTION monet_query_to_array(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and parses each raw row into a text array for simple scalar result sets';

-- TINYINT
CREATE DOMAIN TINYINT AS SMALLINT CHECK(VALUE >= -127 AND VALUE <= 127);
-- CLOB
CREATE DOMAIN CLOB AS TEXT;
-- STRING
CREATE DOMAIN STRING AS TEXT;
-- URL
CREATE DOMAIN URL AS TEXT;
