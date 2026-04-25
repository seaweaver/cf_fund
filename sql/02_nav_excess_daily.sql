/*
Purpose:
  Export daily fund return, benchmark return and excess return versus 885001.

Parameters:
  start_dt/end_dt follow the note's window. Adjust if needed.
  benchmark_code defaults to 885001.WI. Confirm with 00_fund_scope_candidates.sql first.
*/

WITH params AS (
    SELECT '20210419' AS start_dt, '20260417' AS end_dt, '885001.WI' AS benchmark_code FROM dual
),
target_names AS (
    SELECT 'article' AS source_group, '华泰柏瑞量化智慧混合A' AS input_name, '华泰柏瑞量化智慧' AS search_key FROM dual UNION ALL
    SELECT 'article', '长城中证500指数增强A', '长城中证500指数增强' FROM dual UNION ALL
    SELECT 'article', '中欧数据挖掘混合A', '中欧数据挖掘' FROM dual UNION ALL
    SELECT 'article', '华夏智胜价值成长股票A', '华夏智胜价值成长' FROM dual UNION ALL
    SELECT 'article', '招商量化精选股票A', '招商量化精选' FROM dual UNION ALL
    SELECT 'article', '东方红京东大数据混合A', '东方红京东大数据' FROM dual UNION ALL
    SELECT 'article', '博道伍佰智航股票A', '博道伍佰智航' FROM dual UNION ALL
    SELECT 'article', '景顺长城创业板综指增强A', '景顺长城创业板综指增强' FROM dual UNION ALL
    SELECT 'article', '国金量化多策略混合A', '国金量化多策略' FROM dual UNION ALL
    SELECT 'holding', '招商量化精选A', '招商量化精选' FROM dual UNION ALL
    SELECT 'holding', '华夏新锦绣A', '华夏新锦绣' FROM dual UNION ALL
    SELECT 'holding', '大成景恒A', '大成景恒' FROM dual UNION ALL
    SELECT 'holding', '诺安多策略A', '诺安多策略' FROM dual UNION ALL
    SELECT 'holding', '建信灵活A', '建信灵活' FROM dual UNION ALL
    SELECT 'holding', '创金合信启富优选A', '创金合信启富优选' FROM dual
),
fund_scope AS (
    SELECT DISTINCT d.F_INFO_WINDCODE, d.F_INFO_NAME
    FROM target_names t
    JOIN ChinaMutualFundDescription d
      ON d.F_INFO_NAME LIKE '%' || t.search_key || '%'
      OR d.F_INFO_FULLNAME LIKE '%' || t.search_key || '%'
    WHERE d.F_INFO_NAME LIKE '%A%'
       OR d.F_INFO_FULLNAME LIKE '%A%'
),
fund_nav AS (
    SELECT
        s.F_INFO_WINDCODE,
        s.F_INFO_NAME,
        n.PRICE_DATE AS trade_dt,
        n.F_NAV_ADJUSTED AS adj_nav,
        n.F_NAV_UNIT AS unit_nav,
        n.F_NAV_ACCUMULATED AS accumulated_nav,
        n.F_PRT_NETASSET AS net_asset,
        n.F_NAV_ADJUSTED / NULLIF(LAG(n.F_NAV_ADJUSTED) OVER (
            PARTITION BY s.F_INFO_WINDCODE ORDER BY n.PRICE_DATE
        ), 0) - 1 AS fund_ret
    FROM fund_scope s
    JOIN ChinaMutualFundNAV n
      ON n.F_INFO_WINDCODE = s.F_INFO_WINDCODE
    CROSS JOIN params p
    WHERE n.PRICE_DATE BETWEEN p.start_dt AND p.end_dt
      AND n.F_NAV_ADJUSTED IS NOT NULL
),
benchmark AS (
    SELECT
        e.TRADE_DT AS trade_dt,
        e.S_DQ_CLOSE AS bench_close,
        e.S_DQ_CLOSE / NULLIF(LAG(e.S_DQ_CLOSE) OVER (ORDER BY e.TRADE_DT), 0) - 1 AS bench_ret
    FROM CMFIndexEOD e
    CROSS JOIN params p
    WHERE e.S_INFO_WINDCODE = p.benchmark_code
      AND e.TRADE_DT BETWEEN p.start_dt AND p.end_dt
      AND e.S_DQ_CLOSE IS NOT NULL
)
SELECT
    f.F_INFO_WINDCODE,
    f.F_INFO_NAME,
    f.trade_dt,
    f.adj_nav,
    f.unit_nav,
    f.accumulated_nav,
    f.net_asset,
    b.bench_close,
    f.fund_ret,
    b.bench_ret,
    f.fund_ret - b.bench_ret AS excess_ret,
    EXP(SUM(LN(1 + NVL(f.fund_ret - b.bench_ret, 0))) OVER (
        PARTITION BY f.F_INFO_WINDCODE ORDER BY f.trade_dt
    )) - 1 AS cumulative_excess_ret
FROM fund_nav f
JOIN benchmark b
  ON b.trade_dt = f.trade_dt
WHERE f.fund_ret IS NOT NULL
  AND b.bench_ret IS NOT NULL
ORDER BY f.F_INFO_WINDCODE, f.trade_dt;

