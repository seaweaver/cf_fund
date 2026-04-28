/*
Purpose:
  Verified fund universe for this project.

Why:
  The original fuzzy-name matching SQL accidentally included
  006682.OF 景顺长城中证500指数增强A because its name contains
  the substring "长城中证500指数增强".

Use this CTE in later SQL when exact fund scope matters.
*/

WITH fund_scope AS (
    SELECT 'article' AS source_group, '001244.OF' AS F_INFO_WINDCODE, '华泰柏瑞量化智慧A' AS F_INFO_NAME FROM dual UNION ALL
    SELECT 'article', '006048.OF', '长城中证500指数增强A' FROM dual UNION ALL
    SELECT 'article', '001990.OF', '中欧数据挖掘多因子A' FROM dual UNION ALL
    SELECT 'article', '002871.OF', '华夏智胜价值成长A' FROM dual UNION ALL
    SELECT 'article_holding', '001917.OF', '招商量化精选A' FROM dual UNION ALL
    SELECT 'article', '001564.OF', '东方红京东大数据A' FROM dual UNION ALL
    SELECT 'article', '007831.OF', '博道伍佰智航A' FROM dual UNION ALL
    SELECT 'article', '008072.OF', '景顺长城创业板综指增强A' FROM dual UNION ALL
    SELECT 'article', '005443.OF', '国金量化多策略A' FROM dual UNION ALL
    SELECT 'holding', '002833.OF', '华夏新锦绣A' FROM dual UNION ALL
    SELECT 'holding', '090019.OF', '大成景恒A' FROM dual UNION ALL
    SELECT 'holding', '320016.OF', '诺安多策略A' FROM dual UNION ALL
    SELECT 'holding', '000270.OF', '建信灵活配置A' FROM dual UNION ALL
    SELECT 'holding', '019338.OF', '创金合信启富优选A' FROM dual
)
SELECT
    source_group,
    F_INFO_WINDCODE,
    F_INFO_NAME
FROM fund_scope
ORDER BY source_group, F_INFO_WINDCODE;

