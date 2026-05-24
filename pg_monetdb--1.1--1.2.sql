/*
 * pg_monetdb--1.1--1.2.sql
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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

COMMENT ON FUNCTION pg_monetdb_query_to_array(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and parses each raw row into a text array for simple scalar result sets';

COMMENT ON FUNCTION monet_query_to_array(name, text)
IS 'executes an arbitrary SQL query on the MonetDB server and parses each raw row into a text array for simple scalar result sets';
