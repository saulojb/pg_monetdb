[English version](README.md) | [README em português brasileiro](README_pt_BR.md)

## pg_monetdb

<p align="center">
  <img src="docs/images/capa.png" alt="pg_monetdb cover" width="960">
</p>

pg_monetdb 是 monetdb_fdw 的一个分支，重点增强了面向 TPC-H 和 TPC-DS 风格分析型查询的 pushdown 能力。

这个分支建立在优秀的 oracle_fdw (https://github.com/laurenz/oracle_fdw.git) 和 postgres_fdw (https://www.postgresql.org/docs/current/postgres-fdw.html) 项目之上。

当前还支持 MonetDB `HUGEINT`、MonetDB `BLOB`，以及部分 `INTERVAL` round trip。已经完成验证的 interval family 包括 `interval month`、`interval day` 和 `interval second`；凡是 MonetDB 端以 `sec_interval` 为底层的限定 interval，目前导入 PostgreSQL 后仍会表现为 `interval second`，因此原始 qualifier 暂时还不能保留。

### 上游致谢

上游仓库地址：https://github.com/HaloTech-Co-Ltd/MonetDB_fdw

特别感谢 `monetdb_fdw` 的维护者和贡献者，这个分支正是建立在他们的上游工作基础之上。

### 基准测试

下面的 TPC-H 结果来自仓库内已提交的真实 PostgreSQL heap 基线测试（schema `pg`）以及与之对应的 `pg_monetdb` 测试（schema `monet`），两者都运行在 PostgreSQL 19 上：

| Query | PostgreSQL heap | `pg_monetdb` | Pushdown |
| ----- | --------------- | ------------ | -------- |
| Query 1 | 1272.074 ms | 139.990 ms | Full |
| Query 2 | 298.228 ms | 9.162 ms | Partial |
| Query 3 | 322.203 ms | 41.508 ms | Partial |
| Query 4 | 183.436 ms | 21.230 ms | Full |
| Query 5 | 559.401 ms | 23.874 ms | Full |
| Query 6 | 152.712 ms | 9.087 ms | Full |
| Query 7 | 2448.717 ms | 36.381 ms | Full |
| Query 8 | 246.125 ms | 35.699 ms | Full |
| Query 9 | 1645.422 ms | 68.392 ms | Full |
| Query 10 | 346.119 ms | 206.652 ms | Full |
| Query 11 | 109.532 ms | 39.043 ms | Partial |
| Query 12 | 278.782 ms | 11.945 ms | Full |
| Query 13 | 525.866 ms | 61.930 ms | Full |
| Query 14 | 123.599 ms | 4.649 ms | Full |
| Query 15 | 474.821 ms | 36.892 ms | Partial |
| Query 16 | 182.510 ms | 55.098 ms | Full |
| Query 17 | 596.631 ms | 28.372 ms | Full |
| Query 18 | 1888.438 ms | 39.790 ms | Full |
| Query 19 | 43.837 ms | 43.812 ms | Full |
| Query 20 | 253.526 ms | 350.296 ms | Partial |
| Query 21 | 1474.114 ms | 75.057 ms | Partial |
| Query 22 | 74.176 ms | 23.588 ms | Partial |
| Total | 13500.269 ms | 1362.447 ms | - |

在这份已提交的 PostgreSQL 19 基准中，`pg_monetdb` 跑完整套 TPC-H 的总时间约为本地 heap 基线的 `9.91x` 更快，整体下降约 `89.9%`。

当当前 PostgreSQL 19 工件中的计划形态是纯 `FS` 时，`Pushdown` 标记为 `Full`；如果仍然带有 `LOCAL_*`、`INITPLAN` 或 `MIXED` 工作，则标记为 `Partial`。

这些总计结果可以通过 `scripts/load_pg18_heap_into_pg19.sh`、`scripts/run_tpch_all_sql.sh` 和 `scripts/benchmark_tpch_schema.sh` 复现。

重要说明：仓库中保留的 `tpch_regression_baseline.tsv` 仍然只是历史 FDW 工件，它不是 PostgreSQL heap-only 基准，不能直接当作 heap 与 FDW 的对比结果来解读。

上面这些 PostgreSQL 19 已提交基准所使用的环境如下：

* 操作系统：Ubuntu 26.04 LTS (Resolute Raccoon)，内核 `7.0.0-15-generic`
* CPU：AMD Ryzen 7 5800H with Radeon Graphics，16 threads
* 内存：38.5 GiB RAM
* 上述基准所用 PostgreSQL 版本：`postgres (PostgreSQL) 19devel (Ubuntu 19~~devel-3~20260525.0815.g0b8fa5fd37b.pgdg26.04+1)`

### 验证矩阵

仓库中还保留了 PostgreSQL 15 到 19 的版本化 TPC-H 回归工件：

* `tpch_regression_pg15.tsv`
* `tpch_regression_pg16.tsv`
* `tpch_regression_pg17.tsv`
* `tpch_regression_pg18.tsv`
* `tpch_regression_pg19.tsv`

这些工件构成了当前跨版本验证矩阵的已提交参考，覆盖 PostgreSQL 15、16、17、18 和 19。

### 支持的操作系统与数据库版本

* RHEL 8/9, CentOS 8/9, Ubuntu
* Halo 1.0.14, 1.0.16
* PostgreSQL 15, 16, 17, 18, 19
* MonetDB 11.56

### 使用手册

#### 安装

MonetDB 官方快速安装入口：https://www.monetdb.org/easy-setup/

如果 MonetDB 是通过发行版默认软件包安装的，`MONETDB_HOME` 的常见取值可以是：

```sh
export MONETDB_HOME=/usr
```

* 以 PGXS 方式构建

```sh
export USE_PGXS=1
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git
cd pg_monetdb
make && make install
```

* 在 PostgreSQL 源码树中构建

```sh
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git <PostgreSQL contrib source path>/pg_monetdb
cd <PostgreSQL contrib source path>/pg_monetdb
make && make install
```

#### 快速教程

* 创建 pg_monetdb 扩展

```sql
CREATE EXTENSION pg_monetdb;
```

* 创建 foreign server

```sql
CREATE SERVER foreign_server FOREIGN DATA WRAPPER pg_monetdb
OPTIONS (host '127.0.0.1', port '50000', dbname 'test');
```

* 创建用户映射

```sql
CREATE USER MAPPING FOR CURRENT_USER SERVER foreign_server OPTIONS (user 'zm', password 'zm');
```

* 使用 `pg_monetdb_execute` 在 MonetDB 中创建示例表 `emp`

```sql
SELECT pg_monetdb_execute('foreign_server', $$CREATE TABLE emp(
  name VARCHAR(20),
  age INTEGER
)$$);
```

* 创建 foreign table

```sql
CREATE FOREIGN TABLE emp(
  name VARCHAR(20),
  age INTEGER
)
SERVER foreign_server
OPTIONS (schema_name 'zm', table_name 'emp');
```

* 之后就可以在 PostgreSQL 中查询 MonetDB 里的 `emp` 表

```sql
SELECT count(*) FROM emp;
```

* 对于临时执行的远端 SQL，`monet_query` 返回原始文本行，而辅助函数可以把简单标量结果解析成数组或 JSON 对象。

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

* 注意：也可以使用 `IMPORT FOREIGN SCHEMA` 更方便地创建 foreign table

```sql
DROP FOREIGN TABLE emp;
IMPORT FOREIGN SCHEMA "zm" limit to (emp) from server foreign_server into public;
```

#### 支持的操作

* INSERT
* DELETE
* UPDATE
* SELECT
* COPY
* TRUNCATE
* EXPLAIN
* IMPORT FOREIGN SCHEMA

#### 支持的类型

| 类型 | 支持情况 | 说明 |
| ---- | -------- | ---- |
| CHAR | Y | 参考 PostgreSQL 文档 |
| VARCHAR | Y | 参考 PostgreSQL 文档 |
| TEXT | Y | 参考 PostgreSQL 文档。`TEXT(x)` 不受支持；导入 PostgreSQL 时会转换为 `VARCHAR(x)` |
| CLOB | Y | 底层类型是 TEXT。`CLOB(x)` 不受支持；导入 PostgreSQL 时会转换为 `VARCHAR(x)` |
| STRING | Y | 底层类型是 TEXT。`STRING(x)` 不受支持；导入 PostgreSQL 时会转换为 `VARCHAR(x)` |
| BLOB | Y | 底层类型是 `bytea`；基于 `bytea` 的域类型如 `blob` 也受支持 |
| BOOL | Y | 参考 PostgreSQL 文档 |
| TINYINT | Y | 底层类型是 smallint |
| SMALLINT | Y | 参考 PostgreSQL 文档 |
| INTEGER | Y | 参考 PostgreSQL 文档 |
| BIGINT | Y | 参考 PostgreSQL 文档 |
| HUGEINT | Y | 映射为 PostgreSQL 上基于 `numeric(39,0)` 的 `HUGEINT` 域，范围为 `-2^127 + 1` 到 `2^127 - 1` |
| DECIMAL | Y | NUMERIC |
| REAL | Y | 参考 PostgreSQL 文档 |
| DOUBLE PRECISION | Y | 参考 PostgreSQL 文档 |
| FLOAT | Y | 参考 PostgreSQL 文档 |
| DATE | Y | 参考 PostgreSQL 文档 |
| TIME | Y | 参考 PostgreSQL 文档 |
| TIME WITH TIME ZONE | Y | 参考 PostgreSQL 文档 |
| TIMESTAMP | Y | 参考 PostgreSQL 文档 |
| TIMESTAMP WITH TIME ZONE | Y | 参考 PostgreSQL 文档 |
| INTERVAL YEAR | Y | 导入为 PostgreSQL `interval month`；round-trip 通过 MonetDB 的 month-based interval family 处理 |
| INTERVAL YEAR TO MONTH | Y | 导入为 PostgreSQL `interval month`；round-trip 通过 MonetDB 的 month-based interval family 处理 |
| INTERVAL MONTH | Y | 导入为 PostgreSQL `interval month`；已经通过 `IMPORT FOREIGN SCHEMA` 验证 round-trip |
| INTERVAL DAY | Y | 导入为 PostgreSQL `interval day`；FDW 会在读写时归一化 MonetDB 的原始秒数存储 |
| INTERVAL DAY TO HOUR | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL DAY TO MINUTE | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL DAY TO SECOND | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL HOUR | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL HOUR TO MINUTE | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL HOUR TO SECOND | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL MINUTE | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL MINUTE TO SECOND | Partial | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 后会表现为 `interval second`，原始 qualifier 不保留 |
| INTERVAL SECOND | Y | 导入为 PostgreSQL `interval second`；已经通过 `IMPORT FOREIGN SCHEMA` 验证 round-trip |
| JSON | Y | 参考 PostgreSQL 文档 |
| UUID | Y | 参考 PostgreSQL 文档 |
| URL | Y | 底层类型是 TEXT |
| INET | Y | 参考 PostgreSQL 文档 |

测试用例请参考 [type_support.sql](./sql/type_support.sql)

当前 MonetDB interval 支持状态如下：远端引擎接受 `INTERVAL MONTH`、`INTERVAL DAY`、`INTERVAL SECOND` 这类带 qualifier 的形式，并在 MonetDB 元数据中呈现为 `month_interval`、`day_interval`、`sec_interval`。`IMPORT FOREIGN SCHEMA` 会把这些 family 映射成 PostgreSQL 的 `interval month`、`interval day` 和 `interval second`，而 pg_monetdb 已经补齐这些已导入 family 所需的写入格式化与读取归一化逻辑，因此这些 family 已经可以完成端到端 round trip。当前剩余限制仍然是 qualifier fidelity：凡是 MonetDB 底层走 `sec_interval` 的类型，例如 `INTERVAL DAY TO SECOND`，导入 PostgreSQL 后目前仍统一表现为 `interval second`，因此底层 family 可用，但原始 qualifier 暂时不会保留。

#### 手工验证

如果你要针对已导入到 schema `monet` 的 TPC-H foreign tables，在现有 PostgreSQL 数据库上做 planner 验证，请参考 [materialized_cte_manual.sql](./sql/materialized_cte_manual.sql)。

重要说明：MonetDB 不接受 ANSI `MATERIALIZED` / `NOT MATERIALIZED` CTE 语法。因此 pg_monetdb 不能把 PostgreSQL 的 `WITH ... AS MATERIALIZED (...)` 子句等价下推成远端 SQL。当前已经验证的安全行为，是把 materialization boundary 保留在 PostgreSQL 本地。

典型执行方式：

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/materialized_cte_manual.sql
```

如果要验证“已下推 grouped CTE 之上再接本地 window stage”的 grouped bridge 场景，请参考 [grouped_bridge_window_manual.sql](./sql/grouped_bridge_window_manual.sql)。

典型执行方式：

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/grouped_bridge_window_manual.sql
```

对于 `INNER JOIN LATERAL` 且 lateral 子查询只是一个标量相关聚合的场景，当前 pg_monetdb 仍会把外层 join 保留在本地。在这个特定模式下，可以安全地改写成标量相关 `WHERE` 形式，并且已经可以完全下推。参考 [lateral_scalar_rewrite_manual.sql](./sql/lateral_scalar_rewrite_manual.sql)。

典型执行方式：

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/lateral_scalar_rewrite_manual.sql
```

实验性选项：

如果后端 session 在第一次 FDW 查询之前就预加载了 `pg_monetdb`，当前 planner-hook 实验实现可以自动规范化这个精确的 `INNER JOIN LATERAL` 标量聚合模式，并生成同样的 fully pushed-down plan。一个测试方式如下：

```sh
sudo -n -u postgres env PGOPTIONS='-c session_preload_libraries=pg_monetdb' \
  psql -X -p 5433 -d monet_test -f sql/lateral_scalar_rewrite_manual.sql
```

这是一个实验性工作流。如果没有 session preload，某个 backend 的第一条 FDW 查询仍然可能错过这次改写，并把原始 `JOIN LATERAL` 形态保留在本地。在该 backend session 的第一条 FDW 查询之前显式执行 `LOAD 'pg_monetdb'`，也能激活同一条 planner 路径。

改写示例：

```sql
-- 原始 INNER JOIN LATERAL 形式
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

-- 推荐的、可下推的标量相关 WHERE 改写
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

这里只推荐对这样一种 `INNER JOIN LATERAL` 形态使用该改写：lateral 侧只返回一行标量聚合结果，相关条件基于外层 relation，而且 join predicate 只是把外层列与该标量结果做比较。

#### 限制

DELETE 和 UPDATE 操作要求远端表存在 Primary Key。
