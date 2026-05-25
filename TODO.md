# TODO

Atualizado em 2026-05-25.

## Notas recentes

- A via experimental para `INNER JOIN LATERAL` escalar foi publicada em `main`, junto com o script [sql/lateral_scalar_rewrite_manual.sql](sql/lateral_scalar_rewrite_manual.sql) e a nota de uso com `session_preload_libraries=pg_monetdb` no README.
- O README agora tambem deixa explicito que `WITH ... AS MATERIALIZED` nao e sintaxe valida no MonetDB; por isso, esse boundary precisa continuar local no PostgreSQL.
- `BLOB` agora esta documentado como suportado via `bytea`.
- `HUGEINT` agora esta suportado via dominio PostgreSQL sobre `numeric(39,0)` e importado como `hugeint`, com faixa valida de `-2^127 + 1` a `2^127 - 1`.
- O repro de cohort-retention com `primeiro_pedido` / `atividade_mensal` / `retidos` e `JOIN ... ON` no `cohort_size` saiu do TODO; esse shape ja esta com pushdown no estado atual.

## Pendencias reais

### 1. Revisar lifecycle de conexao em `monetdb_execute`

- Status: aberto
- Contexto: `monetdb_execute` abre uma conexao MAPI propria com `mapi_connect()` e fecha no fim com `mapi_close_handle()` + `mapi_destroy()`, sem passar pelo gerenciamento central de conexoes em `connection.c`.
- Sintoma lembrado: havia suspeita de perda/instabilidade de conexao em chamadas de `monetdb_execute`.
- Direcao de investigacao: confirmar se o problema era reconnect excessivo, descarte prematuro de handle/conexao, ou falta de reaproveitamento/tratamento uniforme de erro em relacao ao caminho normal do FDW.
- Arquivo principal: `monetdb_fdw.c`, funcao `monetdb_execute()`.

### 2. Corrigir o problema local de build com `.bc`

- Status: aberto
- Sintoma: `make USE_PGXS=1 PG_CONFIG=/usr/lib/postgresql/19/bin/pg_config` pode falhar com `Operation not permitted` ao gerar `monetdb_fdw.bc`.
- Impacto: atrapalha o ciclo de rebuild/validacao e mascara se o binario instalado corresponde ao codigo atual.

### 3. Expandir a cobertura e a documentacao de `INTERVAL`

- Status: aberto
- Contexto: o MonetDB aceita formas qualificadas como `INTERVAL MONTH`, `INTERVAL DAY` e `INTERVAL SECOND`, expostas no catalogo como `month_interval`, `day_interval` e `sec_interval`.
- Estado atual confirmado: `IMPORT FOREIGN SCHEMA` ja mapeia esses casos para PostgreSQL como `interval month`, `interval day` e `interval second`, e o round-trip local para essas tres familias ja esta validado.
- Lacuna real remanescente:
	- varios qualificadores do MonetDB que usam `sec_interval` ainda perdem fidelidade na importacao, porque hoje entram no PostgreSQL como `interval second` em vez de preservar `DAY TO SECOND`, `HOUR TO MINUTE`, etc.
- Direcao de investigacao: decidir se vale preservar o qualificador original na importacao, e ampliar a regressao para cobrir explicitamente os demais qualificadores que caem na familia `sec_interval`.

### 4. Generalizar a reescrita de `INNER JOIN LATERAL` sem depender de preload

- Status: futuro; workaround e modo experimental ja documentados
- Contexto: hoje o pushdown automatico do padrao `JOIN LATERAL (SELECT 0.2 * AVG(...) ...) aq ON outer_col < aq.threshold` funciona quando `pg_monetdb` esta carregado antes da primeira query FDW da sessao, por exemplo com `session_preload_libraries=pg_monetdb` ou `LOAD 'pg_monetdb'`.
- Estado atual seguro: o workaround em `WHERE outer_col < (SELECT 0.2 * AVG(...) ...)` segue valido, e o README ja documenta a opcao experimental com preload.
- Direcao futura: se quisermos remover a dependencia de preload, a normalizacao precisa acontecer em um ponto do planner que nao dependa do carregamento lazy da biblioteca na primeira query FDW.

## Itens removidos deste TODO

- `avg_quantity_per_part` deixou de ser pendencia ativa; o caso esta verde no estado atual e fica apenas como guard-rail tecnico.
- O caso de cohort-retention `retidos` saiu das pendencias reais porque o shape atual com `JOIN cohort_size ... ON` ja esta com pushdown.
- As notas de `MATERIALIZED`, `LATERAL` com preload e `BLOB` suportado migraram para o README e nao precisam mais ficar abertas como pendencia de documentacao.
- O acompanhamento de `HUGEINT` como aresta aberta saiu do TODO depois da correcao da faixa valida para `-2^127 + 1` ate `2^127 - 1`, que e o intervalo suportado pelo MonetDB.
- A analise de `INTERVAL` mostrou que o parser e o catalogo do MonetDB suportam as formas qualificadas; a conversao dedicada de leitura/escrita para as familias importadas (`interval month`, `interval day`, `interval second`) ja foi implementada.
- O estudo `FILTER` vs `CASE WHEN` saiu do TODO porque o pushdown de `FILTER` agora ja funciona corretamente no estado atual.
- O acompanhamento de `BLOB` saiu do TODO porque o suporte ja foi consolidado no codigo, na documentacao e nos SQLs de validacao.