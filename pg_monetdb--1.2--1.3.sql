/*
 * pg_monetdb--1.2--1.3.sql
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

CREATE FUNCTION pg_monetdb_query_to_jsonb(server name, statement text, column_names text[]) RETURNS SETOF jsonb
LANGUAGE SQL STRICT
AS $$
    SELECT jsonb_object($3, arr)
    FROM pg_monetdb_query_to_array($1, $2) AS q(arr)
$$;

CREATE FUNCTION monet_query_to_jsonb(server name, statement text, column_names text[]) RETURNS SETOF jsonb
LANGUAGE SQL STRICT
AS $$
    SELECT *
    FROM pg_monetdb_query_to_jsonb($1, $2, $3)
$$;

COMMENT ON FUNCTION pg_monetdb_query_to_jsonb(name, text, text[])
IS 'executes an arbitrary SQL query on the MonetDB server and maps each parsed row to a jsonb object using the provided column names';

COMMENT ON FUNCTION monet_query_to_jsonb(name, text, text[])
IS 'executes an arbitrary SQL query on the MonetDB server and maps each parsed row to a jsonb object using the provided column names';
