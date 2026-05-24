/*
 * pg_monetdb--1.0--1.1.sql
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

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
