/*
Purpose:
  Export fund stock holdings by report period.

Key table:
  ChinaMutualFundStockPortfolio

Note:
  For ordinary funds, quarterly disclosure may mainly cover top holdings.
  Semiannual and annual reports are more useful for full portfolio reconstruction.
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
    h.F_PRT_ENDDATE,
    h.ANN_DATE,
    h.S_INFO_STOCKWINDCODE,
    h.F_PRT_STKVALUE,
    h.F_PRT_STKQUANTITY,
    h.F_PRT_STKVALUETONAV,
    h.STOCK_PER,
    h.FLOAT_SHR_PER,
    h.F_PRT_POSSTKVALUE,
    h.F_PRT_POSSTKQUANTITY,
    h.F_PRT_POSSTKTONAV,
    h.F_PRT_PASSTKEVALUE,
    h.F_PRT_PASSTKQUANTITY,
    h.F_PRT_PASSTKTONAV
FROM fund_scope s
JOIN ChinaMutualFundStockPortfolio h
  ON h.S_INFO_WINDCODE = s.F_INFO_WINDCODE
CROSS JOIN params p
WHERE h.F_PRT_ENDDATE BETWEEN p.start_dt AND p.end_dt
ORDER BY s.F_INFO_WINDCODE, h.F_PRT_ENDDATE, h.F_PRT_STKVALUETONAV DESC;

