# cf_fund

量化基金相对 `885001` 的超额收益、行业暴露和风格暴露分析项目。

## 🎯 目标

复现并扩展“跑赢 885001 的量化基金拆解”框架：

- 先筛基金相对 `885001` 的长期超额表现。
- 再穿透行业配置、风格系数和持仓结构。
- 最后判断基金收益来源、风格稳定性和组合分散有效性。

## 📁 文件

| 路径 | 说明 |
|---|---|
| `sql/00_fund_scope_candidates.sql` | 校验目标基金 Wind 代码 |
| `sql/10_benchmark_885001_check.sql` | 校验 `885001` 基准代码 |
| `sql/02_nav_excess_daily.sql` | 日度超额收益明细 |
| `sql/03_excess_performance_summary.sql` | 超额收益指标汇总 |
| `sql/05_industry_exposure_csrc.sql` | 证监会行业配置 |
| `sql/06_industry_exposure_third_party.sql` | Wind/第三方行业配置 |
| `sql/07_style_coefficient.sql` | 基金风格系数 |
| `sql/08_stock_portfolio_holdings.sql` | 基金持股明细 |

## 🔢 建议执行顺序

1. 运行 `sql/00_fund_scope_candidates.sql`。
2. 确认基金代码和 A 类份额。
3. 运行 `sql/10_benchmark_885001_check.sql`。
4. 确认 `885001` 代码是否为 `885001.WI`。
5. 依次运行 `sql/01` 到 `sql/09`。
6. 将结果导出为同名 CSV/XLSX。

## ⚠️ 数据原则

- 不提交 Wind 连接信息、账号、Token。
- 不默认提交查询结果原始数据。
- `data/` 和 `output/` 用于本地分析产物。

