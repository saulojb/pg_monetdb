-- Manual validation for a scalar-correlated rewrite of a LATERAL aggregate.
--
-- The JOIN LATERAL form below is semantically valid, but today pg_monetdb
-- keeps the outer join local. The scalar-correlated WHERE form is equivalent
-- for this INNER JOIN pattern and is already pushdown-friendly.

SET search_path TO monet;

\echo 'LATERAL baseline: expected to stay local above remote scans'
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS)
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

\echo 'Scalar-correlated rewrite: expected to become a single Foreign Scan'
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS)
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