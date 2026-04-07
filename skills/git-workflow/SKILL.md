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
- **NEVER commit directly to main** — always use feature branches
- Always check `git branch --show-current` before any edit
- Use short-lived feature branches: `feat/description`, `fix/description`, `chore/description`
- Squash merge PRs — one commit per feature/fix in main's history
- Delete branches immediately after merge

## Before committing
1. Verify you're NOT on main: `git branch --show-current`
2. Run linter and fix issues
3. Run tests if they exist
4. Check `git diff` — no secrets, no debug logs, no unrelated changes

## Creating a PR
```bash
# 1. Ensure you're on main and up to date
git checkout main && git pull

# 2. Create feature branch
git checkout -b feat/my-feature

# 3. Make changes, commit
git add <files>
git commit -m "feat: add my feature"

# 4. Push and create PR
git push -u origin feat/my-feature
gh pr create \
  --title "feat: add my feature" \
  --body "$(cat <<'EOF'
## Summary
- What changed and why

## Test plan
- [ ] How to verify
EOF
)" \
  --assignee jaanjah
```

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
