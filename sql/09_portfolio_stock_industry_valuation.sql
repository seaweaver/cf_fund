/*
Purpose:
  Export stock-level industry and valuation data for stocks appearing in target funds' holdings.

Key tables:
  ChinaMutualFundStockPortfolio
  AShareIndustriesClass
  AShareIndustriesCode
  AShareEODDerivativeIndicator

Use:
  Join this result with 08_stock_portfolio_holdings.sql by:
    S_INFO_STOCKWINDCODE = stock_windcode
    F_PRT_ENDDATE = report_period
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
),
portfolio_stocks AS (
    SELECT DISTINCT
        h.S_INFO_STOCKWINDCODE AS stock_windcode,
        h.F_PRT_ENDDATE AS report_period
    FROM fund_scope s
    JOIN ChinaMutualFundStockPortfolio h
      ON h.S_INFO_WINDCODE = s.F_INFO_WINDCODE
    CROSS JOIN params p
    WHERE h.F_PRT_ENDDATE BETWEEN p.start_dt AND p.end_dt
      AND h.S_INFO_STOCKWINDCODE IS NOT NULL
),
stock_industry AS (
    SELECT
        ps.stock_windcode,
        ps.report_period,
        ic.WIND_IND_CODE,
        code.INDUSTRIESNAME AS wind_industry_name,
        code.LEVELNUM AS wind_industry_level,
        ROW_NUMBER() OVER (
            PARTITION BY ps.stock_windcode, ps.report_period
            ORDER BY ic.ENTRY_DT DESC
        ) AS rn
    FROM portfolio_stocks ps
    LEFT JOIN AShareIndustriesClass ic
      ON ic.S_INFO_WINDCODE = ps.stock_windcode
     AND ic.ENTRY_DT <= ps.report_period
     AND (ic.REMOVE_DT IS NULL OR ic.REMOVE_DT > ps.report_period)
    LEFT JOIN AShareIndustriesCode code
      ON code.INDUSTRIESCODE = ic.WIND_IND_CODE
),
stock_valuation AS (
    SELECT
        ps.stock_windcode,
        ps.report_period,
        v.TRADE_DT,
        v.S_VAL_MV,
        v.S_DQ_MV,
        v.S_VAL_PE_TTM,
        v.S_VAL_PB_NEW,
        v.S_VAL_PS_TTM,
        v.S_DQ_TURN,
        v.S_DQ_FREETURNOVER,
        v.S_DQ_CLOSE_TODAY,
        ROW_NUMBER() OVER (
            PARTITION BY ps.stock_windcode, ps.report_period
            ORDER BY v.TRADE_DT DESC
        ) AS rn
    FROM portfolio_stocks ps
    LEFT JOIN AShareEODDerivativeIndicator v
      ON v.S_INFO_WINDCODE = ps.stock_windcode
     AND v.TRADE_DT <= ps.report_period
     AND v.TRADE_DT >= TO_CHAR(TO_DATE(ps.report_period, 'YYYYMMDD') - 10, 'YYYYMMDD')
)
SELECT
    ps.stock_windcode,
    ps.report_period,
    si.WIND_IND_CODE,
    si.wind_industry_name,
    si.wind_industry_level,
    sv.TRADE_DT AS valuation_trade_dt,
    sv.S_VAL_MV,
    sv.S_DQ_MV,
    sv.S_VAL_PE_TTM,
    sv.S_VAL_PB_NEW,
    sv.S_VAL_PS_TTM,
    sv.S_DQ_TURN,
    sv.S_DQ_FREETURNOVER,
    sv.S_DQ_CLOSE_TODAY
FROM portfolio_stocks ps
LEFT JOIN stock_industry si
  ON si.stock_windcode = ps.stock_windcode
 AND si.report_period = ps.report_period
 AND si.rn = 1
LEFT JOIN stock_valuation sv
  ON sv.stock_windcode = ps.stock_windcode
 AND sv.report_period = ps.report_period
 AND sv.rn = 1
ORDER BY ps.report_period, ps.stock_windcode;

