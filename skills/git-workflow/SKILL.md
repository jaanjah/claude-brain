---
name: git-workflow
description: Use when committing code, writing commit messages, creating branches, opening PRs, deciding a SemVer bump, or anytime a `git commit` is about to be authored. Covers Conventional Commits 1.0.0, Chris Beams' seven rules, SemVer 2.0.0 correlation, and trunk-based PR workflow.
---

# Git Workflow

Three specs combine into one discipline:
1. **Conventional Commits 1.0.0** — machine-parseable *format*.
2. **Chris Beams' seven rules** — human-readable *prose quality*.
3. **SemVer 2.0.0** — release *consequence* of commit type.

Pick the type honestly; the rest follows.

---

## 1. Conventional Commits 1.0.0

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

### Types
| Type | Use for | SemVer impact |
|------|---------|---------------|
| `feat` | New user-visible feature | MINOR |
| `fix` | Bug fix | PATCH |
| `perf` | Performance improvement, no behavior change | PATCH |
| `refactor` | Internal change, no behavior change | none |
| `docs` | Documentation only | none |
| `test` | Add/fix tests | none |
| `chore` | Tooling, deps, config | none |
| `ci` | CI/CD pipeline changes | none |
| `build` | Build system, packaging | none |
| `style` | Formatting only (whitespace, semicolons) | none |

Other types are permitted but the ones above cover ~99% of cases.

### Scope (optional)
A noun in parens describing the affected area: `feat(parser):`, `fix(auth):`, `refactor(api/users):`. Useful in monorepos and large codebases; skip in small projects.

### Breaking changes — two equivalent ways
**A. Bang syntax** (preferred for short messages):
```
feat!: drop support for Node 18
```
```
feat(api)!: rename `getUser` to `fetchUser`
```

**B. Footer** (preferred when the explanation is long):
```
feat: allow config object as first argument

BREAKING CHANGE: positional args removed; pass `{ host, port }` instead.
```

The `BREAKING CHANGE:` footer is **always uppercase**. Either signal alone is enough; using both is fine.

### Footers (git trailer format)
Token then `: ` or ` #`, hyphens instead of spaces:
```
Refs: #123
Reviewed-by: Alice
Co-authored-by: Bob <bob@example.com>
BREAKING CHANGE: <description>
```

---

## 2. Chris Beams' seven rules

1. **Separate subject from body with a blank line.**
2. **Limit the subject line to 50 characters** (hard cap 72 — GitHub truncates beyond).
3. **Capitalize the subject line** (the description after `<type>:` — `feat: Add foo`, not `feat: add foo`). *Note: many teams accept lowercase after the colon; the spec doesn't mandate. Capitalize when in doubt.*
4. **Do not end the subject line with a period.**
5. **Use the imperative mood in the subject.**
   - Test: *"If applied, this commit will ___."* must read naturally.
   - ✅ "Add login retry logic" / "Fix race in worker shutdown" / "Remove deprecated flag"
   - ❌ "Added login retry" / "Fixes the race" / "Removing the flag"
6. **Wrap the body at 72 characters.**
7. **Use the body to explain *what* and *why*, not *how*.** The diff shows how. The message captures intent, constraints, alternatives considered.

### The "If applied" test (single most useful check)
Read your subject after "If applied, this commit will ":
- "If applied, this commit will **add login retry logic**" ✅
- "If applied, this commit will **added login retry**" ❌
- "If applied, this commit will **fixes auth bug**" ❌

If it doesn't parse as English, fix the verb form.

---

## 3. SemVer 2.0.0 correlation

Format: `MAJOR.MINOR.PATCH` (with optional `-prerelease` and `+build` metadata).

| Commit signal | Version bump | Example |
|---------------|--------------|---------|
| `fix:` / `perf:` | PATCH | `1.4.2 → 1.4.3` |
| `feat:` | MINOR | `1.4.2 → 1.5.0` |
| `feat!:` or `BREAKING CHANGE:` footer | MAJOR | `1.4.2 → 2.0.0` |
| docs/test/chore/refactor/ci/build/style | none | (unless coupled with above) |

Pre-1.0.0 (`0.x.y`): anything goes — breaking changes can land in any bump. The 1.0.0 release is the contract that everything after it follows SemVer strictly.

Pre-release: `1.0.0-alpha`, `1.0.0-rc.1`. Build metadata: `1.0.0+20260505`. Build metadata is ignored for precedence comparison.

Automated release tooling (semantic-release, release-please, changesets) reads commit types directly — *the type field is an API contract*, not a tag. Lying about the type breaks downstream consumers.

---

## 4. Examples

### ✅ Good — short
```
fix: prevent retry loop when token expires mid-request
```

### ✅ Good — with body
```
feat(api): cache user lookups for 60s

The `/me` endpoint hits the auth service on every request, which
became the bottleneck during the load test. Caching the resolved
user for 60 seconds (with explicit invalidation on logout) cuts
p95 latency from 240ms to 35ms with no observable staleness.

Refs: #842
```

### ✅ Good — breaking change
```
feat(config)!: replace YAML with TOML

BREAKING CHANGE: `config.yaml` is no longer read. Migrate to
`config.toml`; run `npx migrate-config` for an automated port.
```

### ❌ Bad — wrong mood, period, vague
```
Updated the auth stuff.
```
Issues: not conventional, past tense, period, "stuff", no scope.

### ❌ Bad — explains *how*
```
fix: change line 42 from `==` to `===` and update the test
```
The diff already shows that. The message should explain *why* (e.g., "Numeric coercion was masking type errors when IDs arrived as strings from the new API").

---

## 5. Branch + merge strategy (trunk-based)

- **Never commit directly to `main`** — always a feature branch.
- Always check `git branch --show-current` before any edit.
- Short-lived branches: `feat/desc`, `fix/desc`, `chore/desc`, `docs/desc`, `refactor/desc`.
- Merge style — pick to **preserve granular Conventional Commits**:
  - `--merge` (merge commit): default; keeps every commit, adds a merge node.
  - `--rebase` (linear history): keeps every commit, no merge node — preferred for clean `git log --oneline`.
  - `--squash`: only for WIP-heavy PRs where intermediate commits are noise. Squashing **destroys per-commit conventional-commit metadata**, which release tooling (semantic-release, release-please, changesets) reads.
- Delete branches immediately after merge.
- Never force-push to `main`.

### Standard PR flow
```bash
git checkout main && git pull
git checkout -b feat/my-feature
# ... edits ...
git add <files>
git commit -m "feat: add my feature"
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

PR titles **also follow conventional commits** — they become the merge/squash commit subject when squash is used.

---

## 6. Pre-commit checklist
1. Verify branch: `git branch --show-current` (not `main`)
2. `git diff --staged` — no secrets, no debug logs, no unrelated hunks
3. Lint and tests pass
4. Subject ≤ 50 chars, imperative mood, no period
5. "If applied, this commit will ___" test passes
6. Body (if any) explains *why*, wrapped at 72
7. Breaking change? `!` in subject **or** `BREAKING CHANGE:` footer

---

## 7. Commit signing (SSH)
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

## 8. Recommended git config
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

---

## Common rationalizations to refuse

| Excuse | Reality |
|--------|---------|
| "It's a one-line fix, format doesn't matter" | The format *is* the contract release tooling reads. Always conventional. |
| "Past-tense reads more natural to me" | The repo's history is in imperative; mixing voices makes `git log` unreadable. Use imperative. |
| "I'll squash and rewrite later" | Each individual commit should still pass these rules — squashes inherit subjects. |
| "Body would just repeat the subject" | Then skip the body. A good subject alone is fine. Don't pad. |
| "It's just a refactor, no SemVer impact" | Then use `refactor:` — but verify *no* behavior changed. If behavior changed, it's `fix:` or `feat:`. |

## References
- https://www.conventionalcommits.org/en/v1.0.0/
- https://cbea.ms/git-commit/
- https://semver.org/
