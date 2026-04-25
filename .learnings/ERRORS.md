# Errors

Command failures and integration errors.

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

