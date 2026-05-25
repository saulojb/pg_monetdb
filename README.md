[Chinese README](README_cn.md)

## pg_monetdb

pg_monetdb is a fork of monetdb_fdw focused on stronger pushdown for analytical query shapes derived from TPC-H and TPC-DS-style workloads.

This fork builds on the excellent oracle_fdw (https://github.com/laurenz/oracle_fdw.git) and postgres_fdw (https://www.postgresql.org/docs/current/postgres-fdw.html) projects.

It also includes support for MonetDB `HUGEINT`, MonetDB `BLOB`, and partial `INTERVAL` round trips. The fully validated interval families are `interval month`, `interval day`, and `interval second`; MonetDB qualifiers backed by `sec_interval` still import into PostgreSQL as `interval second`, so the original qualifier is not preserved yet.

### Benchmark

Checked-in local TPC-H totals from a real PostgreSQL heap run on schema `pg` and the matching `pg_monetdb` run on schema `monet`, both on PostgreSQL 19:

| Engine            | Artifact                       | Total TPC-H Time | Total TPC-H Time (s) |
| ----------------- | ------------------------------ | ---------------- | -------------------- |
| PostgreSQL heap   | `tpch_regression_heap_pg19.tsv`  | 13500.269 ms     | 13.500 s             |
| `pg_monetdb`      | `tpch_regression_monet_pg19.tsv` | 1362.447 ms      | 1.362 s              |

In this checked-in PostgreSQL 19 benchmark, `pg_monetdb` finishes the TPC-H total about `9.91x` faster than the local heap baseline, a reduction of about `89.9%`.

These totals are reproducible with `scripts/load_pg18_heap_into_pg19.sh`, `scripts/run_tpch_all_sql.sh`, and `scripts/benchmark_tpch_schema.sh`.

Important note: `tpch_regression_baseline.tsv` is still kept in the repository as a historical FDW artifact, but it is not a PostgreSQL heap-only benchmark and should not be read as a direct heap-vs-FDW comparison.

Benchmark environment used for the checked-in PostgreSQL 19 totals above:

* OS: Ubuntu 26.04 LTS (Resolute Raccoon), kernel `7.0.0-15-generic`
* CPU: AMD Ryzen 7 5800H with Radeon Graphics, 16 threads
* Memory: 38.5 GiB RAM
* PostgreSQL used for the benchmark total above: `postgres (PostgreSQL) 19devel (Ubuntu 19~~devel-3~20260525.0815.g0b8fa5fd37b.pgdg26.04+1)`

### Validation Matrix

The repository also carries versioned TPC-H regression artifacts for PostgreSQL 15 through 19:

* `tpch_regression_pg15.tsv`
* `tpch_regression_pg16.tsv`
* `tpch_regression_pg17.tsv`
* `tpch_regression_pg18.tsv`
* `tpch_regression_pg19.tsv`

Those artifacts are the checked-in reference for the current cross-version validation matrix, covering PostgreSQL 15, 16, 17, 18, and 19.

### Supported OS & Database Versions

* RHEL 8/9, CentOS 8/9, Ubuntu
* Halo 1.0.14, 1.0.16
* PostgreSQL 14, 15, 16, 17, 18, 19
* MonetDB 11.56

### Cookbook

#### Installation

* Build as PGXS

```sh
export USE_PGXS=1
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git
cd pg_monetdb
make && make install
```

* Build in a source tree of PostgreSQL

```sh
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git <PostgreSQL contrib source path>/pg_monetdb
cd <PostgreSQL contrib source path>/pg_monetdb
make && make install
```

#### Quick Tutorial

* Create pg_monetdb extension

```sql
CREATE EXTENSION pg_monetdb;
```

* Create foreign server

```sql
CREATE SERVER foreign_server FOREIGN DATA WRAPPER pg_monetdb
OPTIONS (host '127.0.0.1', port '50000', dbname 'test');
```

* Create user mapping

```sql
CREATE USER MAPPING FOR CURRENT_USER SERVER foreign_server OPTIONS (user 'zm', password 'zm');
```

* Create table (emp for a example) in MonetDB using pg_monetdb_execute function

```sql
SELECT pg_monetdb_execute('foreign_server', $$CREATE TABLE emp(
        name VARCHAR(20),
        age INTEGER
)$$);
```

* Create foreign table

```sql
CREATE FOREIGN TABLE emp(
        name VARCHAR(20),
        age INTEGER
)
SERVER foreign_server
OPTIONS (schema_name 'zm', table_name 'emp');
```

* Now you can query the MonetDB emp table in PostgreSQL

```sql
SELECT count(*) FROM emp;
```

* For ad hoc remote SQL, `monet_query` returns raw text rows, while the helper variants can parse simple scalar result sets into arrays or JSON objects.

```sql
SELECT * FROM monet_query('foreign_server', $$SELECT name, age FROM emp$$);

SELECT * FROM monet_query_to_array('foreign_server', $$SELECT name, age FROM emp$$);

SELECT *
FROM monet_query_to_jsonb(
        'foreign_server',
        $$SELECT name, age FROM emp$$,
        ARRAY['name', 'age']
);
```

* NOTE: you can IMPORT FOREIGN SCHEMA to create foreign table for convenient

```sql
DROP FOREIGN TABLE emp;
IMPORT FOREIGN SCHEMA "zm" limit to (emp) from server foreign_server into public;
```

#### Supported Operations

* INSERT
* DELETE
* UPDATE
* SELECT
* COPY
* TRUNCATE
* EXPLAIN
* IMPORT FOREIGN SCHEMA

#### Supported Types


| Type                         | Supported | Description                                                                                                               |
| ---------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------- |
| CHAR                         | Y         | Ref PostgreSQL Doc                                                                                                        |
| VARCHAR                      | Y         | Ref PostgreSQL Doc                                                                                                        |
| TEXT                         | Y         | Ref PostgreSQL Doc. TEXT(x) is not supported,<br />TEXT(x) will transform to VARCHAR(x) when imported into PostgreSQL    |
| CLOB                         | Y         | Base type is TEXT. CLOB(x) is not supported,<br />CLOB(x) will transform to VARCHAR(x) when imported into PostgreSQL     |
| STRING                       | Y         | Base type is TEXT, STRING(x) is not supported,<br />STRING(x) will transform to VARCHAR(x) when imported into PostgreSQL |
| BLOB                         | Y         | Base type is `bytea`; domains over `bytea` such as `blob` are supported                                                  |
| BOOL                         | Y         | Ref PostgreSQL Doc                                                                                                        |
| TINYINT                      | Y         | Base type is smallint                                                                                                     |
| SMALLINT                     | Y         | Ref PostgreSQL Doc                                                                                                        |
| INTEGER                      | Y         | Ref PostgreSQL Doc                                                                                                        |
| BIGINT                       | Y         | Ref PostgreSQL Doc                                                                                                        |
| HUGEINT                      | Y         | Mapped to a PostgreSQL `HUGEINT` domain over `numeric(39,0)` with range `-2^127 + 1` to `2^127 - 1`                  |
| DECIMAL                      | Y         | NUMERIC                                                                                                                   |
| REAL                         | Y         | Ref PostgreSQL Doc                                                                                                        |
| DOUBLE PRECISION             | Y         | Ref PostgreSQL Doc                                                                                                        |
| FLOAT                        | Y         | Ref PostgreSQL Doc                                                                                                        |
| DATE                         | Y         | Ref PostgreSQL Doc                                                                                                        |
| TIME                         | Y         | Ref PostgreSQL Doc                                                                                                        |
| TIME WITH TIME ZONE          | Y         | Ref PostgreSQL Doc                                                                                                        |
| TIMESTAMP                    | Y         | Ref PostgreSQL Doc                                                                                                        |
| TIMESTAMP WITH TIME ZONE     | Y         | Ref PostgreSQL Doc                                                                                                        |
| INTERVAL YEAR                | Y         | Imported as PostgreSQL `interval month`; round-trip support is handled through MonetDB's month-based interval family      |
| INTERVAL YEAR TO MONTH       | Y         | Imported as PostgreSQL `interval month`; round-trip support is handled through MonetDB's month-based interval family      |
| INTERVAL MONTH               | Y         | Imported as PostgreSQL `interval month`; round-trip validated through `IMPORT FOREIGN SCHEMA`                            |
| INTERVAL DAY                 | Y         | Imported as PostgreSQL `interval day`; FDW normalizes MonetDB's raw-second storage on read and write                     |
| INTERVAL DAY TO HOUR         | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL DAY TO MINUTE       | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL DAY TO SECOND       | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL HOUR                | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL HOUR TO MINUTE      | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL HOUR TO SECOND      | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL MINUTE              | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL MINUTE TO SECOND    | Partial   | MonetDB stores this in `sec_interval`; imported as PostgreSQL `interval second`, so the original qualifier is not kept   |
| INTERVAL SECOND              | Y         | Imported as PostgreSQL `interval second`; round-trip validated through `IMPORT FOREIGN SCHEMA`                           |
| JSON                         | Y         | Ref PostgreSQL Doc                                                                                                        |
| UUID                         | Y         | Ref PostgreSQL Doc                                                                                                        |
| URL                          | Y         | Base type is TEXT                                                                                                         |
| INET                         | Y         | Ref PostgreSQL Doc                                                                                                        |

Test case please reference [type\_support.sql](./sql/type_support.sql)

Current status for MonetDB intervals: the remote engine accepts qualified interval forms such as `INTERVAL MONTH`, `INTERVAL DAY`, and `INTERVAL SECOND`, which surface in MonetDB metadata as `month_interval`, `day_interval`, and `sec_interval`. `IMPORT FOREIGN SCHEMA` maps those families to PostgreSQL `interval month`, `interval day`, and `interval second`, and pg_monetdb now performs the write-side formatting and read-side normalization needed for end-to-end round trips on those imported families. The remaining limitation is qualifier fidelity for MonetDB types backed by `sec_interval`: forms such as `INTERVAL DAY TO SECOND` are currently imported as PostgreSQL `interval second`, so the storage family works but the original qualifier is not preserved.

#### Manual Validation

For planner validation against an existing PostgreSQL database with imported TPC-H foreign tables in schema `monet`, see [materialized_cte_manual.sql](./sql/materialized_cte_manual.sql).

Important note: MonetDB does not accept the ANSI `MATERIALIZED` / `NOT MATERIALIZED` CTE syntax. Because of that, pg_monetdb cannot push down a PostgreSQL `WITH ... AS MATERIALIZED (...)` clause as equivalent remote SQL. The validated safe behavior is to keep the materialization boundary local in PostgreSQL.

Typical invocation:

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/materialized_cte_manual.sql
```

For grouped grouped-subquery bridge validation with a local window stage above a pushed-down grouped CTE, see [grouped_bridge_window_manual.sql](./sql/grouped_bridge_window_manual.sql).

Typical invocation:

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/grouped_bridge_window_manual.sql
```

For `INNER JOIN LATERAL` queries whose lateral subquery is just a scalar correlated aggregate, current pg_monetdb behavior is to keep the outer join local. In that specific pattern, a scalar-correlated `WHERE` rewrite is a safe workaround and can already push down fully. See [lateral_scalar_rewrite_manual.sql](./sql/lateral_scalar_rewrite_manual.sql).

Typical invocation:

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/lateral_scalar_rewrite_manual.sql
```

Experimental option:

If the backend session preloads `pg_monetdb` before the first FDW query, the current planner-hook experiment can normalize this exact `INNER JOIN LATERAL` scalar-aggregate pattern automatically and produce the same fully pushed-down plan. One way to test that behavior is:

```sh
sudo -n -u postgres env PGOPTIONS='-c session_preload_libraries=pg_monetdb' \
        psql -X -p 5433 -d monet_test -f sql/lateral_scalar_rewrite_manual.sql
```

This is an experimental workflow. Without session preload, the first FDW query in a backend can still miss the rewrite and keep the original `JOIN LATERAL` shape local. Explicit `LOAD 'pg_monetdb'` before the first FDW query is also sufficient to activate the same planner path in that backend session.

Example rewrite:

```sql
-- Original INNER JOIN LATERAL form
SELECT
        SUM(l.l_extendedprice) / 7.0 AS avg_yearly
FROM
        part p
        JOIN lineitem l ON l.l_partkey = p.p_partkey
        JOIN LATERAL (
                SELECT 0.2 * AVG(l2.l_quantity) AS threshold
                FROM lineitem l2
                WHERE l2.l_partkey = p.p_partkey
        ) aq ON l.l_quantity < aq.threshold
WHERE
        p.p_brand = 'Brand#23'
        AND p.p_container = 'MED BOX';

-- Recommended scalar-correlated rewrite for pushdown
SELECT
        SUM(l.l_extendedprice) / 7.0 AS avg_yearly
FROM
        part p
        JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE
        p.p_brand = 'Brand#23'
        AND p.p_container = 'MED BOX'
        AND l.l_quantity < (
                SELECT 0.2 * AVG(l2.l_quantity)
                FROM lineitem l2
                WHERE l2.l_partkey = p.p_partkey
        );
```

This rewrite is recommended only for the `INNER JOIN LATERAL` case where the lateral side returns a single scalar aggregate row correlated on the outer relation and the join predicate only compares outer columns against that scalar result.

#### Limits

Primary Key is required for DELETE and UPDATE operations.
