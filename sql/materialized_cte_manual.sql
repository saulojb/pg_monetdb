-- Manual validation for MATERIALIZED vs NOT MATERIALIZED grouped CTE planning.
--
-- Prerequisites:
-- 1. PostgreSQL database monet_test exists.
-- 2. search_path schema monet contains imported TPC-H foreign tables.

SET search_path TO monet;

-- NOT MATERIALIZED should inline and remain fully pushed down.
EXPLAIN (VERBOSE, COSTS OFF)
WITH avg_quantity_per_part AS NOT MATERIALIZED (
    SELECT l_partkey, 0.2 * avg(l_quantity) AS avg_qty
    FROM lineitem
    JOIN part ON p_partkey = l_partkey
    WHERE p_brand = 'Brand#23'
      AND p_container = 'MED BOX'
    GROUP BY l_partkey
)
SELECT sum(l_extendedprice) / 7.0 AS avg_yearly
FROM lineitem
JOIN part ON p_partkey = l_partkey
JOIN avg_quantity_per_part avgq ON avgq.l_partkey = p_partkey
WHERE p_brand = 'Brand#23'
  AND p_container = 'MED BOX'
  AND l_quantity < avgq.avg_qty;

-- MATERIALIZED should preserve a local CTE boundary and local aggregate.
EXPLAIN (VERBOSE, COSTS OFF)
WITH avg_quantity_per_part AS MATERIALIZED (
    SELECT l_partkey, 0.2 * avg(l_quantity) AS avg_qty
    FROM lineitem
    JOIN part ON p_partkey = l_partkey
    WHERE p_brand = 'Brand#23'
      AND p_container = 'MED BOX'
    GROUP BY l_partkey
)
SELECT sum(l_extendedprice) / 7.0 AS avg_yearly
FROM lineitem
JOIN part ON p_partkey = l_partkey
JOIN avg_quantity_per_part avgq ON avgq.l_partkey = p_partkey
WHERE p_brand = 'Brand#23'
  AND p_container = 'MED BOX'
  AND l_quantity < avgq.avg_qty;

-- Both forms should return the same rounded result.
WITH avg_quantity_per_part AS NOT MATERIALIZED (
    SELECT l_partkey, 0.2 * avg(l_quantity) AS avg_qty
    FROM lineitem
    JOIN part ON p_partkey = l_partkey
    WHERE p_brand = 'Brand#23'
      AND p_container = 'MED BOX'
    GROUP BY l_partkey
)
SELECT 'not_materialized_q17_like' AS case_name,
       round((sum(l_extendedprice) / 7.0)::numeric, 3) AS result
FROM lineitem
JOIN part ON p_partkey = l_partkey
JOIN avg_quantity_per_part avgq ON avgq.l_partkey = p_partkey
WHERE p_brand = 'Brand#23'
  AND p_container = 'MED BOX'
  AND l_quantity < avgq.avg_qty;

WITH avg_quantity_per_part AS MATERIALIZED (
    SELECT l_partkey, 0.2 * avg(l_quantity) AS avg_qty
    FROM lineitem
    JOIN part ON p_partkey = l_partkey
    WHERE p_brand = 'Brand#23'
      AND p_container = 'MED BOX'
    GROUP BY l_partkey
)
SELECT 'materialized_q17_like' AS case_name,
       round((sum(l_extendedprice) / 7.0)::numeric, 3) AS result
FROM lineitem
JOIN part ON p_partkey = l_partkey
JOIN avg_quantity_per_part avgq ON avgq.l_partkey = p_partkey
WHERE p_brand = 'Brand#23'
  AND p_container = 'MED BOX'
  AND l_quantity < avgq.avg_qty;