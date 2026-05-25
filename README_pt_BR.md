[English README](README.md) | [README 中文](README_cn.md)

## pg_monetdb

<p align="center">
        <img src="docs/images/capa.png" alt="Capa do pg_monetdb" width="960">
</p>

pg_monetdb é um fork de monetdb_fdw focado em pushdown mais forte para formatos de consultas analíticas derivados de cargas no estilo TPC-H e TPC-DS.

Este fork se apoia nos excelentes projetos oracle_fdw (https://github.com/laurenz/oracle_fdw.git) e postgres_fdw (https://www.postgresql.org/docs/current/postgres-fdw.html).

Ele também inclui suporte a `HUGEINT` do MonetDB, `BLOB` do MonetDB e round trip parcial de `INTERVAL`. As famílias de interval totalmente validadas são `interval month`, `interval day` e `interval second`; qualificadores do MonetDB suportados por `sec_interval` ainda são importados para o PostgreSQL como `interval second`, então o qualificador original ainda não é preservado.

### Agradecimento ao Upstream

Repositório upstream: https://github.com/HaloTech-Co-Ltd/MonetDB_fdw

Agradecimento especial aos mantenedores e contribuidores de `monetdb_fdw`, base do trabalho upstream sobre o qual este fork foi construído.

### Benchmark

Tempos locais de TPC-H versionados no repositório, obtidos a partir de uma execução real sobre tabelas heap do PostgreSQL no schema `pg` e da execução correspondente via `pg_monetdb` no schema `monet`, ambos em PostgreSQL 19:

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

Neste benchmark versionado de PostgreSQL 19, `pg_monetdb` conclui o total do TPC-H cerca de `9.91x` mais rápido que a baseline local em heap, uma redução de aproximadamente `89.9%`.

`Pushdown` aparece como `Full` quando o artefato atual de PostgreSQL 19 é um plano `FS` puro e como `Partial` quando a forma ainda inclui trabalho `LOCAL_*`, `INITPLAN` ou `MIXED`.

Esses totais são reproduzíveis com `scripts/load_pg18_heap_into_pg19.sh`, `scripts/run_tpch_all_sql.sh` e `scripts/benchmark_tpch_schema.sh`.

Observação importante: `tpch_regression_baseline.tsv` continua no repositório como um artefato histórico de FDW, mas não é um benchmark somente de heap do PostgreSQL e não deve ser lido como comparação direta entre heap e FDW.

Ambiente usado para os totais versionados de PostgreSQL 19 acima:

* SO: Ubuntu 26.04 LTS (Resolute Raccoon), kernel `7.0.0-15-generic`
* CPU: AMD Ryzen 7 5800H with Radeon Graphics, 16 threads
* Memória: 38.5 GiB RAM
* PostgreSQL usado no benchmark acima: `postgres (PostgreSQL) 19devel (Ubuntu 19~~devel-3~20260525.0815.g0b8fa5fd37b.pgdg26.04+1)`

### Matriz de Validação

O repositório também carrega artefatos versionados de regressão TPC-H para PostgreSQL 15 até 19:

* `tpch_regression_pg15.tsv`
* `tpch_regression_pg16.tsv`
* `tpch_regression_pg17.tsv`
* `tpch_regression_pg18.tsv`
* `tpch_regression_pg19.tsv`

Esses artefatos são a referência versionada da matriz de validação cross-version atual, cobrindo PostgreSQL 15, 16, 17, 18 e 19.

### Sistemas Operacionais e Versões de Banco Suportados

* RHEL 8/9, CentOS 8/9, Ubuntu
* Halo 1.0.14, 1.0.16
* PostgreSQL 15, 16, 17, 18, 19
* MonetDB 11.56

### Cookbook

#### Instalação

Instalação rápida oficial do MonetDB: https://www.monetdb.org/easy-setup/

Se o MonetDB foi instalado a partir de pacotes padrão da distribuição, um valor comum para `MONETDB_HOME` é:

```sh
export MONETDB_HOME=/usr
```

* Build via PGXS

```sh
export USE_PGXS=1
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git
cd pg_monetdb
make && make install
```

* Build dentro de uma árvore de código-fonte do PostgreSQL

```sh
export MONETDB_HOME=<MonetDB installation path>
export PATH=$MONETDB_HOME/bin:$PATH
export LD_LIBRARY_PATH=$MONETDB_HOME/lib64:$LD_LIBRARY_PATH
git clone https://github.com/saulojb/pg_monetdb.git <PostgreSQL contrib source path>/pg_monetdb
cd <PostgreSQL contrib source path>/pg_monetdb
make && make install
```

#### Tutorial Rápido

* Criar a extensão pg_monetdb

```sql
CREATE EXTENSION pg_monetdb;
```

* Criar o foreign server

```sql
CREATE SERVER foreign_server FOREIGN DATA WRAPPER pg_monetdb
OPTIONS (host '127.0.0.1', port '50000', dbname 'test');
```

* Criar o user mapping

```sql
CREATE USER MAPPING FOR CURRENT_USER SERVER foreign_server OPTIONS (user 'zm', password 'zm');
```

* Criar uma tabela de exemplo `emp` no MonetDB usando `pg_monetdb_execute`

```sql
SELECT pg_monetdb_execute('foreign_server', $$CREATE TABLE emp(
        name VARCHAR(20),
        age INTEGER
)$$);
```

* Criar a foreign table

```sql
CREATE FOREIGN TABLE emp(
        name VARCHAR(20),
        age INTEGER
)
SERVER foreign_server
OPTIONS (schema_name 'zm', table_name 'emp');
```

* Agora você pode consultar a tabela `emp` do MonetDB a partir do PostgreSQL

```sql
SELECT count(*) FROM emp;
```

* Para SQL remoto ad hoc, `monet_query` retorna linhas de texto cruas, enquanto as variantes auxiliares conseguem interpretar resultados escalares simples em arrays ou objetos JSON.

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

* OBS: você pode usar `IMPORT FOREIGN SCHEMA` para criar a foreign table de forma mais conveniente

```sql
DROP FOREIGN TABLE emp;
IMPORT FOREIGN SCHEMA "zm" limit to (emp) from server foreign_server into public;
```

#### Operações Suportadas

* INSERT
* DELETE
* UPDATE
* SELECT
* COPY
* TRUNCATE
* EXPLAIN
* IMPORT FOREIGN SCHEMA

#### Tipos Suportados

| Tipo | Suportado | Descrição |
| ---- | --------- | --------- |
| CHAR | Y | Ref PostgreSQL Doc |
| VARCHAR | Y | Ref PostgreSQL Doc |
| TEXT | Y | Ref PostgreSQL Doc. `TEXT(x)` não é suportado;<br />`TEXT(x)` vira `VARCHAR(x)` quando importado para o PostgreSQL |
| CLOB | Y | O tipo base é TEXT. `CLOB(x)` não é suportado;<br />`CLOB(x)` vira `VARCHAR(x)` quando importado para o PostgreSQL |
| STRING | Y | O tipo base é TEXT, `STRING(x)` não é suportado;<br />`STRING(x)` vira `VARCHAR(x)` quando importado para o PostgreSQL |
| BLOB | Y | O tipo base é `bytea`; domains sobre `bytea`, como `blob`, são suportados |
| BOOL | Y | Ref PostgreSQL Doc |
| TINYINT | Y | O tipo base é smallint |
| SMALLINT | Y | Ref PostgreSQL Doc |
| INTEGER | Y | Ref PostgreSQL Doc |
| BIGINT | Y | Ref PostgreSQL Doc |
| HUGEINT | Y | Mapeado para um domínio PostgreSQL `HUGEINT` sobre `numeric(39,0)` com faixa de `-2^127 + 1` a `2^127 - 1` |
| DECIMAL | Y | NUMERIC |
| REAL | Y | Ref PostgreSQL Doc |
| DOUBLE PRECISION | Y | Ref PostgreSQL Doc |
| FLOAT | Y | Ref PostgreSQL Doc |
| DATE | Y | Ref PostgreSQL Doc |
| TIME | Y | Ref PostgreSQL Doc |
| TIME WITH TIME ZONE | Y | Ref PostgreSQL Doc |
| TIMESTAMP | Y | Ref PostgreSQL Doc |
| TIMESTAMP WITH TIME ZONE | Y | Ref PostgreSQL Doc |
| INTERVAL YEAR | Y | Importado como PostgreSQL `interval month`; o round trip é tratado pela família month-based de interval do MonetDB |
| INTERVAL YEAR TO MONTH | Y | Importado como PostgreSQL `interval month`; o round trip é tratado pela família month-based de interval do MonetDB |
| INTERVAL MONTH | Y | Importado como PostgreSQL `interval month`; round trip validado por `IMPORT FOREIGN SCHEMA` |
| INTERVAL DAY | Y | Importado como PostgreSQL `interval day`; o FDW normaliza o armazenamento bruto em segundos do MonetDB na leitura e na escrita |
| INTERVAL DAY TO HOUR | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL DAY TO MINUTE | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL DAY TO SECOND | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL HOUR | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL HOUR TO MINUTE | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL HOUR TO SECOND | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL MINUTE | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL MINUTE TO SECOND | Partial | O MonetDB armazena isso em `sec_interval`; ao importar para o PostgreSQL vira `interval second`, então o qualificador original não é mantido |
| INTERVAL SECOND | Y | Importado como PostgreSQL `interval second`; round trip validado por `IMPORT FOREIGN SCHEMA` |
| JSON | Y | Ref PostgreSQL Doc |
| UUID | Y | Ref PostgreSQL Doc |
| URL | Y | O tipo base é TEXT |
| INET | Y | Ref PostgreSQL Doc |

Veja os casos de teste em [type_support.sql](./sql/type_support.sql)

Estado atual para intervals do MonetDB: o engine remoto aceita formas qualificadas como `INTERVAL MONTH`, `INTERVAL DAY` e `INTERVAL SECOND`, que aparecem nos metadados do MonetDB como `month_interval`, `day_interval` e `sec_interval`. `IMPORT FOREIGN SCHEMA` mapeia essas famílias para `interval month`, `interval day` e `interval second` no PostgreSQL, e pg_monetdb agora faz a formatação de escrita e a normalização de leitura necessárias para round trips ponta a ponta nessas famílias importadas. A limitação restante é a fidelidade do qualificador para tipos do MonetDB apoiados em `sec_interval`: formas como `INTERVAL DAY TO SECOND` são importadas atualmente como `interval second` no PostgreSQL, então a família de armazenamento funciona, mas o qualificador original ainda não é preservado.

#### Validação Manual

Para validação do planner contra um banco PostgreSQL existente com tabelas TPC-H importadas para o schema `monet`, veja [materialized_cte_manual.sql](./sql/materialized_cte_manual.sql).

Observação importante: o MonetDB não aceita a sintaxe ANSI de CTE `MATERIALIZED` / `NOT MATERIALIZED`. Por isso, pg_monetdb não consegue fazer pushdown de uma cláusula PostgreSQL `WITH ... AS MATERIALIZED (...)` como SQL remoto equivalente. O comportamento seguro já validado é manter essa fronteira de materialização local no PostgreSQL.

Invocação típica:

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/materialized_cte_manual.sql
```

Para validação do caso de ponte entre subconsulta agrupada e etapa local de janela acima de um CTE agrupado com pushdown, veja [grouped_bridge_window_manual.sql](./sql/grouped_bridge_window_manual.sql).

Invocação típica:

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/grouped_bridge_window_manual.sql
```

Para consultas com `INNER JOIN LATERAL` em que a subconsulta lateral é apenas um agregado correlacionado escalar, o comportamento atual do pg_monetdb é manter o join externo local. Nesse padrão específico, um rewrite para `WHERE` escalar correlacionado é um workaround seguro e já consegue pushdown completo. Veja [lateral_scalar_rewrite_manual.sql](./sql/lateral_scalar_rewrite_manual.sql).

Invocação típica:

```sh
sudo -n -u postgres psql -X -p 5433 -d monet_test -f sql/lateral_scalar_rewrite_manual.sql
```

Opcao experimental:

Se a sessão backend fizer preload de `pg_monetdb` antes da primeira query FDW, o experimento atual com planner hook pode normalizar automaticamente esse padrão exato de agregado escalar com `INNER JOIN LATERAL` e produzir o mesmo plano com pushdown total. Uma forma de testar esse comportamento é:

```sh
sudo -n -u postgres env PGOPTIONS='-c session_preload_libraries=pg_monetdb' \
        psql -X -p 5433 -d monet_test -f sql/lateral_scalar_rewrite_manual.sql
```

Este é um fluxo experimental. Sem preload na sessão, a primeira query FDW de um backend ainda pode deixar passar o rewrite e manter a forma original de `JOIN LATERAL` local. Executar `LOAD 'pg_monetdb'` antes da primeira query FDW também basta para ativar o mesmo caminho do planner nessa sessão backend.

Exemplo de rewrite:

```sql
-- Forma original com INNER JOIN LATERAL
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

-- Rewrite escalar correlacionado recomendado para pushdown
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

Esse rewrite só é recomendado para o caso de `INNER JOIN LATERAL` em que o lado lateral retorna uma única linha com agregado escalar correlacionado na relação externa e o predicado do join apenas compara colunas externas com esse resultado escalar.

#### Limites

Primary Key é obrigatória para operações DELETE e UPDATE.