---
name: git-workflow
description: Git commit, branch, and PR workflows. Use when committing code, creating PRs, or asking about git conventions.
---

# Git Workflow

## Commit messages (conventional commits)
- `feat:` new feature
- `fix:` bug fix
- `chore:` tooling, deps, config
- `docs:` documentation only
- `refactor:` no behavior change
- `test:` adding or fixing tests
- `ci:` CI/CD changes
- `perf:` performance improvement
- Breaking changes: use `!` after type — `feat!: remove legacy API`

## Branch strategy (trunk-based)
- Push small changes directly to `main`
- Use short-lived feature branches (hours, not days) for larger work
- Squash merge PRs — one commit per feature/fix in main's history
- Delete branches immediately after merge

## Before committing
1. Run linter and fix issues
2. Run tests if they exist
3. Check `git diff` — no secrets, no debug logs, no unrelated changes

## PR description
- **What**: what does this change do
- **Why**: why is it needed
- **How**: notable implementation decisions
- **Testing**: how was it tested

## Commit signing (SSH)
All commits should be signed with SSH keys. Recommended global config:
```ini
[gpg]
    format = ssh
[user]
    signingkey = ~/.ssh/id_ed25519.pub
[commit]
    gpgsign = true
[tag]
    gpgsign = true
```

## Recommended git config
```ini
[push]
    autoSetupRemote = true
[pull]
    rebase = true
[merge]
    conflictstyle = zdiff3
[rerere]
    enabled = true
[diff]
    algorithm = histogram
    colorMoved = plain
[fetch]
    prune = true
[rebase]
    autoStash = true
    updateRefs = true
[branch]
    sort = -committerdate
```
