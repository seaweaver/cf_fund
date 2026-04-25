/*
Purpose:
  Export quarterly industry exposure disclosed by funds.

Key table:
  ChinaMutualFundIndPortfolio

Note:
  This table uses CSRC industry classification. Use 06_industry_exposure_third_party.sql
  for Wind/third-party industry exposure when available.
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
    i.F_PRT_ENDDATE,
    i.F_ANN_DATE,
    i.S_INFO_CSRCINDUSCODE,
    i.S_INFO_CSRCINDUSNAME,
    i.F_PRT_INDUSVALUE,
    i.F_PRT_INDUSTONAV,
    i.F_PRT_INDUSTONAVCHANGE,
    i.F_PRT_INDPOSVALUE,
    i.F_PRT_INDPOSPRO,
    i.F_PRT_INDPASSIVEVALUE,
    i.F_PRT_INDPASSIVEPRO
FROM fund_scope s
JOIN ChinaMutualFundIndPortfolio i
  ON i.S_INFO_WINDCODE = s.F_INFO_WINDCODE
CROSS JOIN params p
WHERE i.F_PRT_ENDDATE BETWEEN p.start_dt AND p.end_dt
ORDER BY s.F_INFO_WINDCODE, i.F_PRT_ENDDATE, i.F_PRT_INDUSTONAV DESC;

