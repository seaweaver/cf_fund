# Errors

Command failures and integration errors.

---

## [ERR-20260428-003] pandas_to_markdown_tabulate_missing

**Logged**: 2026-04-28T00:00:00+08:00
**Priority**: low
**Status**: pending
**Area**: data

### Summary
`DataFrame.to_markdown()` failed because the bundled Python runtime does not include `tabulate`.

### Error
`ImportError: Import tabulate failed`

### Context
- Command attempted: generate markdown report from pandas analysis tables
- Environment: bundled Codex Python runtime

### Suggested Fix
Use a small local Markdown table formatter instead of installing packages.

### Metadata
- Reproducible: yes
- Related Files: output/2026-04-28_fund_analysis_stage1.md

---

## [ERR-20260428-002] pandas_to_numeric_errors_ignore

**Logged**: 2026-04-28T00:00:00+08:00
**Priority**: low
**Status**: pending
**Area**: data

### Summary
Bundled pandas raised an error for `pd.to_numeric(errors='ignore')`.

### Error
`ValueError: invalid error value specified`

### Context
- Command attempted: local xlsx result analysis script
- Environment: bundled Codex Python runtime

### Suggested Fix
Use explicit text-column skips and `errors='coerce'` only where numeric conversion is expected.

### Metadata
- Reproducible: yes
- Related Files: result/*.xlsx

---

## [ERR-20260428-001] result_workbook_sheet_name_assumption

**Logged**: 2026-04-28T00:00:00+08:00
**Priority**: medium
**Status**: pending
**Area**: data

### Summary
Result workbook parsing failed because not every exported workbook uses a `With` sheet name.

### Error
`ValueError: Worksheet named 'With' not found`

### Context
- Command attempted: pandas read of `result/*.xlsx`
- File involved: `result/10_benchmark_885001_check.xlsx`
- Actual sheet name started with `Select wind2_cmfindexdescripti`

### Suggested Fix
When parsing exported SQL result workbooks, choose the first non-`SQL` sheet instead of assuming `With`.

### Metadata
- Reproducible: yes
- Related Files: result/10_benchmark_885001_check.xlsx

---

## [ERR-20260425-001] gh_missing

**Logged**: 2026-04-25T12:30:00+08:00
**Priority**: high
**Status**: pending
**Area**: infra

### Summary
GitHub publish flow is blocked because GitHub CLI is not installed in this Windows environment.

### Error
`gh` is not recognized as a cmdlet, function, script file, or executable program.

### Context
- Command attempted: `gh --version`
- Workspace: `D:\Dropbox\Project\cf_fund`
- Task: initialize project and publish to GitHub

### Suggested Fix
Install and authenticate GitHub CLI, or provide an existing GitHub remote URL so plain `git push` can be used.

### Metadata
- Reproducible: yes
- Related Files: AGENTS.md

---
