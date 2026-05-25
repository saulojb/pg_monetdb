<!--
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

# pg_monetdb v1.4.0

pg_monetdb v1.4.0 is a feature and packaging release for PostgreSQL-to-MonetDB analytical workloads. This release adds MonetDB `HUGEINT` support, validates interval-family round trips for imported MonetDB interval families, refreshes the project documentation and multilingual READMEs, and aligns PGXN metadata with the current packaging state.

## Highlights

- Added MonetDB `HUGEINT` support through a PostgreSQL `HUGEINT` domain over `numeric(39,0)`.
- Added MonetDB interval-family round trips for imported `interval month`, `interval day`, and `interval second` families.
- Documented MonetDB `BLOB`, `HUGEINT`, and partial `INTERVAL` support in the main README and translated READMEs.
- Added reproducible checked-in PostgreSQL 19 benchmark artifacts comparing local heap execution against `pg_monetdb` on TPC-H.
- Refreshed PGXN packaging metadata and release documentation for the current 1.4 package state.

## Compatibility

- PGXN metadata now declares PostgreSQL 15 and newer.
- Validated in this development cycle against PostgreSQL 15, 16, 17, 18, and 19.
- README currently documents support through PostgreSQL 19 and MonetDB 11.56.

## Type and FDW Improvements

- Imported MonetDB `HUGEINT` columns now map to a PostgreSQL domain with the validated range `-2^127 + 1` to `2^127 - 1`.
- Deparsing and type aliasing preserve MonetDB-facing type names for supported domain-backed imports.
- MonetDB interval families backed by `month_interval`, `day_interval`, and `sec_interval` now have validated read/write normalization for imported PostgreSQL interval families.
- Remaining interval limitation is qualifier fidelity for MonetDB types backed by `sec_interval`, which still import as PostgreSQL `interval second` rather than preserving the original qualifier.

## Benchmark and Documentation

- Added reproducible helper scripts for loading local PostgreSQL heap TPC-H tables and benchmarking `sql/all.sql` against heap and FDW schemas.
- Added checked-in PostgreSQL 19 benchmark artifacts for both local heap and `pg_monetdb` runs.
- Updated README positioning to reflect that `pg_monetdb` is a fork of `monetdb_fdw` focused on stronger analytical pushdown.
- Added upstream acknowledgement for `monetdb_fdw` and synchronized English, Chinese, and Brazilian Portuguese documentation.

## Validation Summary

This release was validated with:

- extension build and install via PGXS
- extension upgrade path through `1.4`
- `sql/all.sql`
- `sql/type_support.sql`
- manual `EXPLAIN` and `EXPLAIN ANALYZE` checks for grouped pushdown, materialized CTE handling, and lateral scalar rewrite behavior
- live checks for MonetDB `HUGEINT` limits and interval-family round trips against MonetDB-backed foreign tables
- checked-in PostgreSQL 19 TPC-H benchmark reproduction scripts and artifacts

## Packaging Notes

- Release tag: `v1.4.0`
- Extension default version: `1.4`
- PGXN metadata file: `META.json`

## Upgrade

Existing installations can upgrade with:

```sql
ALTER EXTENSION pg_monetdb UPDATE TO '1.4';
```