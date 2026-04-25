/*
Purpose:
  Export fund style coefficients and Wind style thresholds.

Key tables:
  CFundStyleCoefficient
  CFundStyleThreshold

Use:
  Reconstruct large/mid/small and growth/value tendency by comparing
  AVG_MARKET_VALUE, GROWTH_Z and VALUE_Z with threshold fields.
*/

WITH params AS (
    SELECT '20210419' AS start_dt, '20260417' AS end_dt FROM dual
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
)
SELECT
    s.F_INFO_WINDCODE,
    s.F_INFO_NAME,
    c.S_CHANGE_DATE,
    c.DATE_CLOSING_DATE,
    c.STYLE_COEFFICIENT,
    c.GROWTH_Z,
    c.VALUE_Z,
    c.AVG_MARKET_VALUE,
    c.GROSS_OPER_REV,
    c.GROSS_OPER_NETPROFIT,
    c.VALUE_COEFFICIENT,
    th.THRESHOLD_LARGE_STOCK,
    th.THRESHOLD_MID_STOCK,
    th.THRESHOLD_GROWTH_STOCK,
    th.THRESHOLD_VALUE_STOCK,
    CASE
        WHEN c.AVG_MARKET_VALUE >= th.THRESHOLD_LARGE_STOCK THEN 'large'
        WHEN c.AVG_MARKET_VALUE >= th.THRESHOLD_MID_STOCK THEN 'mid'
        ELSE 'small'
    END AS market_cap_bucket,
    CASE
        WHEN c.GROWTH_Z >= th.THRESHOLD_GROWTH_STOCK THEN 'growth'
        WHEN c.VALUE_Z >= th.THRESHOLD_VALUE_STOCK THEN 'value'
        ELSE 'blend'
    END AS style_bucket
FROM fund_scope s
JOIN CFundStyleCoefficient c
  ON c.S_INFO_WINDCODE = s.F_INFO_WINDCODE
LEFT JOIN CFundStyleThreshold th
  ON th.S_CHANGE_DATE = c.S_CHANGE_DATE
CROSS JOIN params p
WHERE c.S_CHANGE_DATE BETWEEN p.start_dt AND p.end_dt
ORDER BY s.F_INFO_WINDCODE, c.S_CHANGE_DATE;

