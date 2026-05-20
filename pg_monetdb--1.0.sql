/* pg_monetdb--1.0.sql */

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

COMMENT ON FUNCTION pg_monetdb_execute(name, text)
IS 'executes an arbitrary SQL statement with no results on the MonetDB server';

-- TINYINT
CREATE DOMAIN TINYINT AS SMALLINT CHECK(VALUE >= -127 AND VALUE <= 127);
-- CLOB
CREATE DOMAIN CLOB AS TEXT;
-- STRING
CREATE DOMAIN STRING AS TEXT;
-- URL
CREATE DOMAIN URL AS TEXT;