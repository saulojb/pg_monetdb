<!--
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

# pg_monetdb v1.3.0

pg_monetdb v1.3.0 is a stability and usability release for PostgreSQL-to-MonetDB workloads. This release improves SQL helper coverage, fixes bytea/BLOB interoperability, strengthens grouped and upper-relation pushdown planning across newer PostgreSQL versions, and adds PGXN packaging metadata.

## Highlights

- Added SQL-callable remote query helpers:
  - `monet_query(server, statement)` for raw text rows
  - `monet_query_to_array(server, statement)` for simple scalar row parsing
  - `monet_query_to_jsonb(server, statement, column_names)` for JSON-shaped results
- Fixed MonetDB BLOB interoperability for PostgreSQL `bytea` reads, writes, and parameterized predicates.
- Improved `monetdb_execute` behavior for SQL-visible remote execution.
- Fixed grouped pushdown regressions and upper-relation deparsing issues seen on PostgreSQL 18 and 19.
- Added packaged extension upgrade path through `1.3` and PGXN metadata in `META.json`.
- Normalized source headers to canonical MPL 2.0 notice wording.

## Compatibility

- PostgreSQL 14 and newer are declared in PGXN metadata.
- Validated in this development cycle against PostgreSQL 15, 16, 17, 18, and 19.
- README currently documents support through PostgreSQL 19 and MonetDB 11.56.

## Planner and Pushdown Improvements

- Restored grouped bridge handling for aggregate consumers.
- Fixed PostgreSQL 19 deparsing for `ORDER BY` over grouped upper-relation chains.
- Implemented whole-query pushdown planner path improvements.
- Preserved planning stability for grouped CTE and reused-CTE scenarios exercised during validation.

## SQL Helper Additions

Use `monet_query` when you want raw MonetDB rows returned as text:

```sql
SELECT *
FROM monet_query('foreign_server', $$SELECT name, age FROM emp$$);
```

Use `monet_query_to_array` for simple positional parsing:

```sql
SELECT *
FROM monet_query_to_array('foreign_server', $$SELECT name, age FROM emp$$);
```

Use `monet_query_to_jsonb` when you want named columns in JSON form:

```sql
SELECT *
FROM monet_query_to_jsonb(
    'foreign_server',
    $$SELECT name, age FROM emp$$,
    ARRAY['name', 'age']
);
```

## Validation Summary

This release was validated with:

- extension build and install via PGXS
- extension upgrade path through `1.3`
- `sql/all.sql`
- manual `EXPLAIN` and `EXPLAIN ANALYZE` checks for grouped pushdown, CTE reuse, whole-query pushdown, and ordered upper-rel planning
- live checks for `monet_query`, `monet_query_to_array`, and `monet_query_to_jsonb`
- bytea/BLOB write and read probes against MonetDB-backed foreign tables

## Packaging Notes

- Release tag: `v1.3.0`
- Extension default version: `1.3`
- PGXN metadata file: `META.json`

## Upgrade

Existing installations can upgrade with:

```sql
ALTER EXTENSION pg_monetdb UPDATE TO '1.3';
```