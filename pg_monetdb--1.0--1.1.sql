/* pg_monetdb--1.0--1.1.sql */

CREATE FUNCTION pg_monetdb_query(server name, statement text) RETURNS SETOF text
AS 'MODULE_PATHNAME', 'monet_query'
LANGUAGE C STRICT;

CREATE FUNCTION monet_query(server name, statement text) RETURNS SETOF text
AS 'MODULE_PATHNAME', 'monet_query'
LANGUAGE C STRICT;

COMMENT ON FUNCTION pg_monetdb_query(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and returns raw result rows as text';

COMMENT ON FUNCTION monet_query(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and returns raw result rows as text';
