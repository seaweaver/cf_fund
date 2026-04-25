/*
Purpose:
  Calculate summary metrics for excess return versus 885001.

Output:
  annualized_excess_ret, excess_vol, excess_sharpe, max_excess_drawdown,
  daily_win_rate, positive_excess_days.
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
        e.S_DQ_CLOSE / NULLIF(LAG(e.S_DQ_CLOSE) OVER (ORDER BY e.TRADE_DT), 0) - 1 AS bench_ret
    FROM CMFIndexEOD e
    CROSS JOIN params p
    WHERE e.S_INFO_WINDCODE = p.benchmark_code
      AND e.TRADE_DT BETWEEN p.start_dt AND p.end_dt
      AND e.S_DQ_CLOSE IS NOT NULL
),
daily_excess AS (
    SELECT
        f.F_INFO_WINDCODE,
        f.F_INFO_NAME,
        f.trade_dt,
        f.fund_ret,
        b.bench_ret,
        f.fund_ret - b.bench_ret AS excess_ret
    FROM fund_nav f
    JOIN benchmark b
      ON b.trade_dt = f.trade_dt
    WHERE f.fund_ret IS NOT NULL
      AND b.bench_ret IS NOT NULL
),
indexed AS (
    SELECT
        d.*,
        EXP(SUM(LN(1 + d.excess_ret)) OVER (
            PARTITION BY d.F_INFO_WINDCODE ORDER BY d.trade_dt
        )) AS excess_index
    FROM daily_excess d
    WHERE d.excess_ret > -1
),
drawdown AS (
    SELECT
        i.*,
        i.excess_index / NULLIF(MAX(i.excess_index) OVER (
            PARTITION BY i.F_INFO_WINDCODE ORDER BY i.trade_dt
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 0) - 1 AS excess_drawdown
    FROM indexed i
)
SELECT
    F_INFO_WINDCODE,
    F_INFO_NAME,
    MIN(trade_dt) AS start_dt,
    MAX(trade_dt) AS end_dt,
    COUNT(*) AS trading_days,
    EXP(SUM(LN(1 + excess_ret))) - 1 AS cumulative_excess_ret,
    POWER(EXP(SUM(LN(1 + excess_ret))), 252 / NULLIF(COUNT(*), 0)) - 1 AS annualized_excess_ret,
    STDDEV(excess_ret) * SQRT(252) AS annualized_excess_vol,
    (POWER(EXP(SUM(LN(1 + excess_ret))), 252 / NULLIF(COUNT(*), 0)) - 1)
        / NULLIF(STDDEV(excess_ret) * SQRT(252), 0) AS excess_sharpe,
    MIN(excess_drawdown) AS max_excess_drawdown,
    AVG(CASE WHEN excess_ret > 0 THEN 1 ELSE 0 END) AS daily_win_rate,
    SUM(CASE WHEN excess_ret > 0 THEN 1 ELSE 0 END) AS positive_excess_days
FROM drawdown
GROUP BY F_INFO_WINDCODE, F_INFO_NAME
ORDER BY annualized_excess_ret DESC;

