-- Manual validation for grouped grouped-subquery bridge pushdown feeding a
-- local window stage.
--
-- Prerequisites:
-- 1. PostgreSQL database monet_test exists.
-- 2. search_path schema monet contains imported TPC-H foreign tables.

SET search_path TO monet;

-- The grouped supplier-period CTE should plan as a Foreign Scan, while the
-- downstream window stage remains local.
EXPLAIN (VERBOSE, COSTS OFF)
WITH fornecedor_periodo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name                        AS nacao,
        r.r_name                        AS regiao,
        EXTRACT(YEAR FROM l.l_shipdate) AS ano,
        SUM(l.l_extendedprice)          AS faturamento,
        AVG(l.l_quantity)               AS qtd_media,
        SUM(l.l_quantity)               AS qtd_total
    FROM supplier s
    JOIN nation n   ON n.n_nationkey = s.s_nationkey
    JOIN region r   ON r.r_regionkey = n.n_regionkey
    JOIN lineitem l ON l.l_suppkey = s.s_suppkey
    GROUP BY 1, 2, 3, 4, 5
),
variacao AS (
    SELECT *,
        LAG(faturamento) OVER (
            PARTITION BY s_suppkey ORDER BY ano
        ) AS fat_ano_anterior,
        faturamento - LAG(faturamento) OVER (
            PARTITION BY s_suppkey ORDER BY ano
        ) AS variacao_abs,
        ROUND(
            100.0 * (
                faturamento
                - LAG(faturamento) OVER (PARTITION BY s_suppkey ORDER BY ano)
            )
            / NULLIF(
                LAG(faturamento) OVER (PARTITION BY s_suppkey ORDER BY ano),
                0
            ),
            2
        ) AS variacao_pct
    FROM fornecedor_periodo
)
SELECT *
FROM variacao
WHERE variacao_pct < -15
  AND ano >= 1995
ORDER BY variacao_pct ASC
LIMIT 150;

-- Execution should succeed and return 11 columns, with the grouped bridge
-- remote scan providing the 8 base grouped columns that feed the local
-- WindowAgg.
WITH fornecedor_periodo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name                        AS nacao,
        r.r_name                        AS regiao,
        EXTRACT(YEAR FROM l.l_shipdate) AS ano,
        SUM(l.l_extendedprice)          AS faturamento,
        AVG(l.l_quantity)               AS qtd_media,
        SUM(l.l_quantity)               AS qtd_total
    FROM supplier s
    JOIN nation n   ON n.n_nationkey = s.s_nationkey
    JOIN region r   ON r.r_regionkey = n.n_regionkey
    JOIN lineitem l ON l.l_suppkey = s.s_suppkey
    GROUP BY 1, 2, 3, 4, 5
),
variacao AS (
    SELECT *,
        LAG(faturamento) OVER (
            PARTITION BY s_suppkey ORDER BY ano
        ) AS fat_ano_anterior,
        faturamento - LAG(faturamento) OVER (
            PARTITION BY s_suppkey ORDER BY ano
        ) AS variacao_abs,
        ROUND(
            100.0 * (
                faturamento
                - LAG(faturamento) OVER (PARTITION BY s_suppkey ORDER BY ano)
            )
            / NULLIF(
                LAG(faturamento) OVER (PARTITION BY s_suppkey ORDER BY ano),
                0
            ),
            2
        ) AS variacao_pct
    FROM fornecedor_periodo
)
SELECT *
FROM variacao
WHERE variacao_pct < -15
  AND ano >= 1995
ORDER BY variacao_pct ASC
LIMIT 10;