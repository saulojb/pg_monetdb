# TODO

Atualizado em 2026-05-22.

## Pendencias de planner/deparser

### 1. Revisar lifecycle de conexao em `monetdb_execute`

- Status: aberto
- Contexto: `monetdb_execute` abre uma conexao MAPI propria com `mapi_connect()` e fecha no fim com `mapi_close_handle()` + `mapi_destroy()`, sem passar pelo gerenciamento central de conexoes em `connection.c`.
- Sintoma lembrado: havia suspeita de perda/instabilidade de conexao em chamadas de `monetdb_execute`.
- Direcao de investigacao: confirmar se o problema era reconnect excessivo, descarte prematuro de handle/conexao, ou falta de reaproveitamento/tratamento uniforme de erro em relacao ao caminho normal do FDW.
- Arquivo principal: `monetdb_fdw.c`, funcao `monetdb_execute()`.

### 2. Cohort-retention `retidos` ainda falha em PG19

- Status: aberto
- Shape de referencia:

```sql
WITH primeiro_pedido_atividade AS (...),
atividade_mensal AS (...),
retidos AS (
    SELECT cohort_mes, meses_desde_aquisicao,
           COUNT(DISTINCT c_custkey) AS clientes_ativos
    FROM atividade_mensal
    GROUP BY 1, 2
)
SELECT count(*)
FROM retidos;
```

- Sintoma: `ERRO: variable not found in subplan target lists`
- Estado seguro atual: manter a regra conservadora de nested pushdown apenas para o caso validado `orders JOIN primeiro_pedido`; nao reabrir heuristicas locais em `MonetDB_GetForeignPlan()` para este shape.
- Direcao de investigacao: depurar o planner/setrefs de `ForeignScan` relid `0` em grouped bridges aninhadas, em vez de continuar ajustando somente `tlist`/`fdw_scan_tlist` localmente.
- Validacoes que devem continuar verdes:
  - `sql/materialized_cte_manual.sql`
  - `sql/grouped_bridge_window_manual.sql`
  - `WITH primeiro_pedido ... SELECT count(*) FROM orders JOIN primeiro_pedido`

### 3. `avg_quantity_per_part` / join com grouped subquery

- Status: adiado para investigacao futura, mas HEAD atual esta passando
- Contexto: experimentos locais em `deparse.c` e `monetdb_fdw.c` chegaram a regredir o caso `avg_quantity_per_part` com grouped subquery join, mas o branch foi restaurado para o estado seguro e a query exata voltou para um unico `Foreign Scan`.
- Proxima investigacao util se voltar a falhar: comparar o mapeamento entre `fdw_scan_tlist` e `ForeignScan.plan.targetlist` no caso joined `aq` contra o caminho grouped bridge simples que ja funciona.
- Observacao: tratar isso como guard-rail tecnico, nao como bug aberto em HEAD.

## Pendencias de suporte

### 4. Medir ganho real da reescrita de cohort-retention

- Status: bloqueado pelo item 2
- Objetivo: comparar custo/tempo entre o shape atual misto local/remoto e a versao reescrita quando ela estiver estavel.

### 5. Corrigir o problema local de build com `.bc`

- Status: aberto
- Sintoma: `make USE_PGXS=1 PG_CONFIG=/usr/lib/postgresql/19/bin/pg_config` pode falhar com `Operation not permitted` ao gerar `monetdb_fdw.bc`.
- Impacto: atrapalha o ciclo de rebuild/validacao e mascara se o binario instalado corresponde ao codigo atual.