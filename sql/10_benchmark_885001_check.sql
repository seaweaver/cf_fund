/*
Purpose:
  Confirm the Wind code and name of 885001 benchmark in fund index tables.

Expected:
  The code is usually 885001.WI, but confirm this in your local Wind database
  before running 02_nav_excess_daily.sql and 03_excess_performance_summary.sql.
*/

SELECT
    S_INFO_WINDCODE,
    S_INFO_CODE,
    S_INFO_NAME,
    S_INFO_COMPNAME,
    S_INFO_PUBLISHER,
    S_INFO_LISTDATE,
    EXPIRE_DATE,
    INDEX_INTRO
FROM CMFIndexDescription
WHERE S_INFO_WINDCODE LIKE '885001%'
   OR S_INFO_CODE = '885001'
   OR S_INFO_NAME LIKE '%偏股%基金%'
   OR S_INFO_COMPNAME LIKE '%偏股%基金%'
ORDER BY S_INFO_WINDCODE;

