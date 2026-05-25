[English version](README.md)

## pg\_monetdb

pg\_monetdb 是基于 Foreign Data Wrapper （FDW） 技术的 PostgreSQL 扩展，可以用来增强`PostgreSQL`的分析能力。
本项目基于优秀的`postgres_fdw`[https://www.postgresql.org/docs/current/postgres-fdw.html](https://www.postgresql.org/docs/current/postgres-fdw.html)和 `oracle_fdw`([https://github.com/laurenz/oracle\_fdw.git](https://github.com/laurenz/oracle_fdw.git))项目。


* RHEL 8/9、CentOS 8/9，Ubuntu
* 羲和（Halo）数据库 1.0.14, 1.0.16
* PostgreSQL 14至18版本
* MonetDB 11.55.5（last）


在PGXS上构建

```sh
export USE_PGXS=1
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git
cd pg_monetdb
make && make install
```

在PostgreSQL的源代码目录编译安装

```sh
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git <PostgreSQL contrib source path>/pg_monetdb
cd <PostgreSQL contrib source path>/pg_monetdb
make && make install
```

#### 快速上手

* 创建pg_monetdb拓展插件

  ```sql
  CREATE EXTENSION pg_monetdb;
  ```
* 创建外部服务器

  ```sql
  CREATE SERVER foreign_server FOREIGN DATA WRAPPER pg_monetdb
  OPTIONS (host '127.0.0.1', port '50000', dbname 'test');
  ```
* 创建用户映射

  ```sql
  CREATE USER MAPPING FOR CURRENT_USER SERVER foreign_server OPTIONS (user 'zm', password 'zm');
  ```
* 在MonetDB中创建一张名为emp的表，这里我们可以使用`pg\_monetdb\_execute`帮助我们快速实现

  ```sql
    SELECT pg_monetdb_execute('foreign_server', $$CREATE TABLE emp(
        name VARCHAR(20),
        age INTEGER
  )$$);
  ```
* 创建外部表

  ```sql
  CREATE FOREIGN TABLE emp(
        name VARCHAR(20),
        age INTEGER
  )
  SERVER foreign_server
  OPTIONS (schema_name 'zm', table_name 'emp');
  ```
* 完成上述操作之后，便可以在PostgreSQL中查询MonetDB的emp表中数据了

  ```sql
  SELECT COUNT(*) FROM emp;
  ```
* 一种更为快捷的创建外部表的方法是`IMPORT FOREIGN SCHEMA`([https://www.postgresql.org/docs/current/sql-importforeignschema.html](https://www.postgresql.org/docs/current/sql-importforeignschema.html))

  ```sql
  DROP FOREIGN TABLE emp;
  IMPORT FOREIGN SCHEMA "zm" limit to (emp) from server foreign_server into public;
  ```

####支持语句

* INSERT
* DELETE
* UPDATE
* SELECT
* COPY
* TRUNCATE
* EXPLAIN
* IMPORT FOREIGN SCHEMA

以及相关的RETURNING语句。

#### 类型


| 类型名称                     | 是否支持 | 额外描述                                                                                                            |
| ---------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------- |
| CHAR                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| VARCHAR                      | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| TEXT                         | 支持     | 请参考PostgreSQL官方文档，不支持TEXT(x)这样的使用方式，在执行IMPORT FOREIGN SCHEMA时，原有的TEXT(x)会变成VARCHAR(x) |
| CLOB                         | 支持     | 本质上是TEXT的DOMAIN，不支持CLOB(x)这样的使用方式，在执行IMPORT FOREIGN SCHEMA时，原有的CLOB(x)会变成VARCHAR(x)     |
| STRING                       | 支持     | 本质上是TEXT的DOMAIN，不支持STRING(x)这样的使用方式，在执行IMPORT FOREIGN SCHEMA时，原有的STRING(x)会变成VARCHAR(x) |
| BLOB                         | 支持     | 本质上是 `bytea`；基于 `bytea` 的 DOMAIN（如 `blob`）也受支持                                                       |
| BOOL                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| TINYINT                      | 支持     | 本质上是SMALLINT的DOMAIN，大小范围-127至127                                                                         |
| SMALLINT                     | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| INTEGER                      | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| BIGINT                       | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| HUGEINT                      | 支持     | 映射为 PostgreSQL 上基于 `numeric(39,0)` 的 `HUGEINT` DOMAIN，取值范围为 `-2^127 + 1` 到 `2^127 - 1`            |
| DECIMAL                      | 支持     | 内部均会转换成NUMERIC，请参考PostgreSQL官方文档                                                                     |
| REAL                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| DOUBLE PRECISION             | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| FLOAT                        | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| DATE                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| TIME                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| TIME WITH TIME ZONE          | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| TIMESTAMP                    | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| TIMESTAMP WITH TIME ZONE     | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| INTERVAL YEAR                | 支持     | 导入为 PostgreSQL 的 `interval month`，通过 MonetDB 的 month-based interval family 实现 round-trip                  |
| INTERVAL YEAR TO MONTH       | 支持     | 导入为 PostgreSQL 的 `interval month`，通过 MonetDB 的 month-based interval family 实现 round-trip                  |
| INTERVAL MONTH               | 支持     | 导入为 PostgreSQL 的 `interval month`，已通过 `IMPORT FOREIGN SCHEMA` 验证 round-trip                               |
| INTERVAL DAY                 | 支持     | 导入为 PostgreSQL 的 `interval day`，FDW 会在读写两侧归一化 MonetDB 的原始秒数存储                                 |
| INTERVAL DAY TO HOUR         | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL DAY TO MINUTE       | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL DAY TO SECOND       | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL HOUR                | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL HOUR TO MINUTE      | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL HOUR TO SECOND      | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL MINUTE              | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL MINUTE TO SECOND    | 部分支持 | MonetDB 将其存为 `sec_interval`；导入 PostgreSQL 时会落为 `interval second`，原始 qualifier 不保留                |
| INTERVAL SECOND              | 支持     | 导入为 PostgreSQL 的 `interval second`，已通过 `IMPORT FOREIGN SCHEMA` 验证 round-trip                              |
| JSON                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| UUID                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |
| URL                          | 支持     | 本质上是TEXT的DOMAIN                                                                                                |
| INET                         | 支持     | 请参考PostgreSQL官方文档                                                                                            |

相关类型测试内容详见[type\_support.sql](./sql/type_support.sql)

当前 MonetDB 的 INTERVAL 支持状态如下：远端引擎接受 `INTERVAL MONTH`、`INTERVAL DAY`、`INTERVAL SECOND` 等带 qualifier 的形式，并在元数据中暴露为 `month_interval`、`day_interval`、`sec_interval`。`IMPORT FOREIGN SCHEMA` 会把这些 family 映射为 PostgreSQL 的 `interval month`、`interval day`、`interval second`，而 pg_monetdb 现在已经补齐了这些已导入 family 的写入格式化和读取归一化，因此 month/day/second 这三类可以完成端到端 round-trip。当前剩余限制是 qualifier fidelity：凡是 MonetDB 落到 `sec_interval` 的类型，例如 `INTERVAL DAY TO SECOND`，导入 PostgreSQL 后目前会统一表现为 `interval second`，存储 family 可用，但原始 qualifier 不会被保留。

#### 限制

由于是参考了oracle\_fdw来实现的功能，所以当使用DELETE、UPDATE语句时，要求远端MonetDB的表中存在主键，

同时需要在PostgreSQL中需要将对应的字段相应的标识一下，可以使用如下语句设置

```
ALTER FOREIGN TABLE tab ALTER col OPTIONS (ADD key 'true');
```

更加推荐使用`IMPORT FOREIGN SCHEMA`，因为它在辅助导入外部表会自动标识相关主键字段。
