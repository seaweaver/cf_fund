/*
Purpose:
  Resolve target fund Wind codes and confirm benchmark code 885001.

Notes:
  1. The target list includes the funds mentioned in the note plus the user's current holdings.
  2. Review match_rank and candidate_count first. If one input_name maps to multiple funds,
     keep the intended A share code when running later queries.
  3. The benchmark is assumed to be 885001.WI. This SQL also searches CMFIndexDescription
     to confirm the code/name in your Wind database.
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
fund_matches AS (
    SELECT
        t.source_group,
        t.input_name,
        t.search_key,
        d.F_INFO_WINDCODE,
        d.F_INFO_NAME,
        d.F_INFO_FULLNAME,
        d.F_INFO_CORP_FUNDMANAGEMENTCOMP,
        d.F_INFO_FIRSTINVESTTYPE,
        d.F_INFO_SETUPDATE,
        d.F_INFO_STATUS,
        d.IS_INDEXFUND,
        d.F_INFO_BENCHMARK,
        CASE
            WHEN d.F_INFO_NAME = t.input_name THEN 1
            WHEN d.F_INFO_FULLNAME = t.input_name THEN 2
            WHEN d.F_INFO_NAME LIKE t.search_key || '%A%' THEN 3
            WHEN d.F_INFO_FULLNAME LIKE '%' || t.search_key || '%A%' THEN 4
            WHEN d.F_INFO_NAME LIKE '%' || t.search_key || '%' THEN 5
            WHEN d.F_INFO_FULLNAME LIKE '%' || t.search_key || '%' THEN 6
            ELSE 9
        END AS match_rank
    FROM target_names t
    JOIN ChinaMutualFundDescription d
      ON d.F_INFO_NAME LIKE '%' || t.search_key || '%'
      OR d.F_INFO_FULLNAME LIKE '%' || t.search_key || '%'
),
ranked AS (
    SELECT
        m.*,
        COUNT(*) OVER (PARTITION BY input_name) AS candidate_count,
        ROW_NUMBER() OVER (
            PARTITION BY input_name, F_INFO_WINDCODE
            ORDER BY match_rank, F_INFO_SETUPDATE
        ) AS rn
    FROM fund_matches m
)
SELECT
    source_group,
    input_name,
    search_key,
    F_INFO_WINDCODE,
    F_INFO_NAME,
    F_INFO_FULLNAME,
    F_INFO_CORP_FUNDMANAGEMENTCOMP,
    F_INFO_FIRSTINVESTTYPE,
    F_INFO_SETUPDATE,
    F_INFO_STATUS,
    IS_INDEXFUND,
    F_INFO_BENCHMARK,
    match_rank,
    candidate_count
FROM ranked
WHERE rn = 1
ORDER BY source_group, input_name, match_rank, F_INFO_WINDCODE;

/*
Benchmark check:

SELECT
    S_INFO_WINDCODE,
    S_INFO_CODE,
    S_INFO_NAME,
    S_INFO_COMPNAME,
    S_INFO_PUBLISHER,
    S_INFO_LISTDATE,
    EXPIRE_DATE
FROM CMFIndexDescription
WHERE S_INFO_WINDCODE LIKE '885001%'
   OR S_INFO_CODE = '885001'
   OR S_INFO_NAME LIKE '%偏股%基金%'
   OR S_INFO_COMPNAME LIKE '%偏股%基金%';
*/

