/*
Purpose:
  Replacement for missing sql/06_industry_exposure_third_party.sql.

Method:
  Rebuild Wind industry exposure from disclosed stock holdings:
    ChinaMutualFundStockPortfolio
      -> AShareIndustriesClass
      -> AShareIndustriesCode

Output:
  - industry_weight_nav_pct: industry holding weight as % of fund NAV
  - industry_weight_disclosed_stock_pct: normalized % within disclosed stock holdings

Note:
  This is a holdings-based reconstruction. It is more useful than top-10-only
  analysis when semiannual/annual reports disclose full holdings.
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
        h.ANN_DATE,
        h.S_INFO_STOCKWINDCODE,
        h.F_PRT_STKVALUE,
        h.F_PRT_STKVALUETONAV
    FROM fund_scope s
    JOIN ChinaMutualFundStockPortfolio h
      ON h.S_INFO_WINDCODE = s.F_INFO_WINDCODE
    CROSS JOIN params p
    WHERE h.F_PRT_ENDDATE BETWEEN p.start_dt AND p.end_dt
      AND h.S_INFO_STOCKWINDCODE IS NOT NULL
),
stock_industry AS (
    SELECT
        h.F_INFO_WINDCODE,
        h.F_PRT_ENDDATE,
        h.S_INFO_STOCKWINDCODE,
        ic.WIND_IND_CODE,
        ROW_NUMBER() OVER (
            PARTITION BY h.F_INFO_WINDCODE, h.F_PRT_ENDDATE, h.S_INFO_STOCKWINDCODE
            ORDER BY ic.ENTRY_DT DESC, NVL(ic.CUR_SIGN, '0') DESC
        ) AS rn
    FROM holdings h
    LEFT JOIN AShareIndustriesClass ic
      ON ic.S_INFO_WINDCODE = h.S_INFO_STOCKWINDCODE
     AND ic.ENTRY_DT <= h.F_PRT_ENDDATE
     AND (ic.REMOVE_DT IS NULL OR ic.REMOVE_DT > h.F_PRT_ENDDATE)
),
industry_code AS (
    SELECT
        SUBSTR(c.INDUSTRIESCODE, 1, 10) AS WIND_IND_CODE,
        c.INDUSTRIESNAME,
        c.LEVELNUM,
        ROW_NUMBER() OVER (
            PARTITION BY SUBSTR(c.INDUSTRIESCODE, 1, 10)
            ORDER BY CASE WHEN LENGTH(c.INDUSTRIESCODE) = 10 THEN 0 ELSE 1 END,
                     c.LEVELNUM,
                     c.INDUSTRIESCODE
        ) AS rn
    FROM AShareIndustriesCode c
    WHERE c.INDUSTRIESCODE LIKE '62%'
      AND NVL(c.USED, 1) = 1
),
joined AS (
    SELECT
        h.source_group,
        h.F_INFO_WINDCODE,
        h.F_INFO_NAME,
        h.F_PRT_ENDDATE,
        h.S_INFO_STOCKWINDCODE,
        h.F_PRT_STKVALUE,
        h.F_PRT_STKVALUETONAV,
        si.WIND_IND_CODE,
        code.INDUSTRIESNAME AS WIND_INDUSTRY_NAME,
        code.LEVELNUM AS WIND_INDUSTRY_LEVEL
    FROM holdings h
    LEFT JOIN stock_industry si
      ON si.F_INFO_WINDCODE = h.F_INFO_WINDCODE
     AND si.F_PRT_ENDDATE = h.F_PRT_ENDDATE
     AND si.S_INFO_STOCKWINDCODE = h.S_INFO_STOCKWINDCODE
     AND si.rn = 1
    LEFT JOIN industry_code code
      ON code.WIND_IND_CODE = si.WIND_IND_CODE
     AND code.rn = 1
)
SELECT
    source_group,
    F_INFO_WINDCODE,
    F_INFO_NAME,
    F_PRT_ENDDATE,
    WIND_IND_CODE,
    WIND_INDUSTRY_NAME,
    WIND_INDUSTRY_LEVEL,
    COUNT(*) AS stock_count,
    SUM(F_PRT_STKVALUE) AS industry_stock_value,
    SUM(F_PRT_STKVALUETONAV) AS industry_weight_nav_pct,
    SUM(F_PRT_STKVALUETONAV)
        / NULLIF(SUM(SUM(F_PRT_STKVALUETONAV)) OVER (
            PARTITION BY F_INFO_WINDCODE, F_PRT_ENDDATE
        ), 0) * 100 AS industry_weight_disclosed_stock_pct
FROM joined
GROUP BY
    source_group,
    F_INFO_WINDCODE,
    F_INFO_NAME,
    F_PRT_ENDDATE,
    WIND_IND_CODE,
    WIND_INDUSTRY_NAME,
    WIND_INDUSTRY_LEVEL
ORDER BY F_INFO_WINDCODE, F_PRT_ENDDATE, industry_weight_nav_pct DESC;

