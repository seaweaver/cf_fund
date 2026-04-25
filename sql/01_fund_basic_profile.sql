/*
Purpose:
  Export basic fund profile for the analysis universe.

Key table:
  ChinaMutualFundDescription
*/

WITH target_names AS (
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
    SELECT DISTINCT
        d.F_INFO_WINDCODE,
        d.F_INFO_NAME,
        d.F_INFO_FULLNAME
    FROM target_names t
    JOIN ChinaMutualFundDescription d
      ON d.F_INFO_NAME LIKE '%' || t.search_key || '%'
      OR d.F_INFO_FULLNAME LIKE '%' || t.search_key || '%'
    WHERE d.F_INFO_NAME LIKE '%A%'
       OR d.F_INFO_FULLNAME LIKE '%A%'
)
SELECT
    d.F_INFO_WINDCODE,
    d.F_INFO_NAME,
    d.F_INFO_FULLNAME,
    d.F_INFO_FRONT_CODE,
    d.F_INFO_BACKEND_CODE,
    d.F_INFO_CORP_FUNDMANAGEMENTCOMP,
    d.F_INFO_CORP_FUNDMANAGEMENTID,
    d.F_INFO_CUSTODIANBANK,
    d.F_INFO_FIRSTINVESTTYPE,
    d.F_INFO_FIRSTINVESTSTYLE,
    d.F_INFO_TYPE,
    d.IS_INDEXFUND,
    d.F_INFO_SETUPDATE,
    d.F_INFO_STATUS,
    d.F_INFO_DELISTDATE,
    d.F_INFO_BENCHMARK,
    d.INVESTSTRATEGY,
    d.RISK_RETURN,
    d.F_INFO_INVESTSCOPE,
    d.F_INFO_INVESTOBJECT
FROM fund_scope s
JOIN ChinaMutualFundDescription d
  ON d.F_INFO_WINDCODE = s.F_INFO_WINDCODE
ORDER BY d.F_INFO_WINDCODE;

