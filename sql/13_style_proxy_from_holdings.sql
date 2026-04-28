/*
Purpose:
  Replacement for missing sql/07_style_coefficient.sql.

Method:
  Rebuild a holdings-based style proxy from:
    ChinaMutualFundStockPortfolio
      -> AShareEODDerivativeIndicator

Definitions:
  - cap_bucket uses each report period's stock universe in target holdings:
      bottom 30% total market cap = small
      middle 40% = mid
      top 30% = large
  - valuation_bucket uses PB:
      bottom 30% PB = low_pb_value_proxy
      top 30% PB = high_pb_growth_proxy

Limit:
  PB proxy is not equivalent to Wind growth/value Z-score. For exact
  "growth/value" exposure, query Wind style coefficient table or add
  stock-level growth factors.
*/

WITH params AS (
    SELECT '20210419' AS start_dt, '20260417' AS end_dt FROM dual
),
fund_scope AS (
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
),
holdings AS (
    SELECT
        s.source_group,
        s.F_INFO_WINDCODE,
        s.F_INFO_NAME,
        h.F_PRT_ENDDATE,
        h.S_INFO_STOCKWINDCODE,
        h.F_PRT_STKVALUETONAV
    FROM fund_scope s
    JOIN ChinaMutualFundStockPortfolio h
      ON h.S_INFO_WINDCODE = s.F_INFO_WINDCODE
    CROSS JOIN params p
    WHERE h.F_PRT_ENDDATE BETWEEN p.start_dt AND p.end_dt
      AND h.S_INFO_STOCKWINDCODE IS NOT NULL
      AND h.F_PRT_STKVALUETONAV IS NOT NULL
),
stock_valuation AS (
    SELECT
        h.F_INFO_WINDCODE,
        h.F_PRT_ENDDATE,
        h.S_INFO_STOCKWINDCODE,
        v.TRADE_DT,
        v.S_VAL_MV,
        v.S_DQ_MV,
        v.S_VAL_PE_TTM,
        v.S_VAL_PB_NEW,
        v.S_VAL_PS_TTM,
        ROW_NUMBER() OVER (
            PARTITION BY h.F_INFO_WINDCODE, h.F_PRT_ENDDATE, h.S_INFO_STOCKWINDCODE
            ORDER BY v.TRADE_DT DESC
        ) AS rn
    FROM holdings h
    LEFT JOIN AShareEODDerivativeIndicator v
      ON v.S_INFO_WINDCODE = h.S_INFO_STOCKWINDCODE
     AND v.TRADE_DT <= h.F_PRT_ENDDATE
     AND v.TRADE_DT >= TO_CHAR(TO_DATE(h.F_PRT_ENDDATE, 'YYYYMMDD') - 10, 'YYYYMMDD')
),
joined AS (
    SELECT
        h.source_group,
        h.F_INFO_WINDCODE,
        h.F_INFO_NAME,
        h.F_PRT_ENDDATE,
        h.S_INFO_STOCKWINDCODE,
        h.F_PRT_STKVALUETONAV,
        v.S_VAL_MV,
        v.S_DQ_MV,
        v.S_VAL_PE_TTM,
        v.S_VAL_PB_NEW,
        v.S_VAL_PS_TTM
    FROM holdings h
    LEFT JOIN stock_valuation v
      ON v.F_INFO_WINDCODE = h.F_INFO_WINDCODE
     AND v.F_PRT_ENDDATE = h.F_PRT_ENDDATE
     AND v.S_INFO_STOCKWINDCODE = h.S_INFO_STOCKWINDCODE
     AND v.rn = 1
    WHERE v.S_VAL_MV IS NOT NULL
),
bucketed AS (
    SELECT
        j.*,
        PERCENTILE_CONT(0.3) WITHIN GROUP (ORDER BY S_VAL_MV)
            OVER (PARTITION BY F_PRT_ENDDATE) AS mv_p30,
        PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY S_VAL_MV)
            OVER (PARTITION BY F_PRT_ENDDATE) AS mv_p70,
        PERCENTILE_CONT(0.3) WITHIN GROUP (ORDER BY S_VAL_PB_NEW)
            OVER (PARTITION BY F_PRT_ENDDATE) AS pb_p30,
        PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY S_VAL_PB_NEW)
            OVER (PARTITION BY F_PRT_ENDDATE) AS pb_p70
    FROM joined j
),
classified AS (
    SELECT
        b.*,
        CASE
            WHEN S_VAL_MV <= mv_p30 THEN 'small'
            WHEN S_VAL_MV >= mv_p70 THEN 'large'
            ELSE 'mid'
        END AS cap_bucket,
        CASE
            WHEN S_VAL_PB_NEW <= pb_p30 THEN 'low_pb_value_proxy'
            WHEN S_VAL_PB_NEW >= pb_p70 THEN 'high_pb_growth_proxy'
            ELSE 'mid_pb'
        END AS valuation_bucket
    FROM bucketed b
)
SELECT
    source_group,
    F_INFO_WINDCODE,
    F_INFO_NAME,
    F_PRT_ENDDATE,
    cap_bucket,
    valuation_bucket,
    COUNT(*) AS stock_count,
    SUM(F_PRT_STKVALUETONAV) AS bucket_weight_nav_pct,
    SUM(F_PRT_STKVALUETONAV)
        / NULLIF(SUM(SUM(F_PRT_STKVALUETONAV)) OVER (
            PARTITION BY F_INFO_WINDCODE, F_PRT_ENDDATE
        ), 0) * 100 AS bucket_weight_disclosed_stock_pct,
    AVG(S_VAL_MV) AS avg_total_mv_wan,
    AVG(S_DQ_MV) AS avg_float_mv_wan,
    AVG(S_VAL_PE_TTM) AS avg_pe_ttm,
    AVG(S_VAL_PB_NEW) AS avg_pb,
    AVG(S_VAL_PS_TTM) AS avg_ps_ttm
FROM classified
GROUP BY
    source_group,
    F_INFO_WINDCODE,
    F_INFO_NAME,
    F_PRT_ENDDATE,
    cap_bucket,
    valuation_bucket
ORDER BY F_INFO_WINDCODE, F_PRT_ENDDATE, cap_bucket, valuation_bucket;

