# Git Workflow

## Commit message format (Conventional Commits 1.0.0)
`<type>[optional scope][!]: <description>` — then optional body and footers.

Types:
- `feat` (→ MINOR), `fix` (→ PATCH)
- `chore`, `docs`, `refactor`, `test`, `ci`, `perf`, `build`, `style`
- Breaking change: trailing `!` before colon **or** `BREAKING CHANGE:` footer (→ MAJOR)

## Subject line (Chris Beams' rules — non-negotiable)
- Imperative mood: "Add X", "Fix Y" — never "Added", "Fixes", "Fixing"
  - Test: "If applied, this commit will ___" must read naturally
- ≤ 50 characters (hard cap 72; GitHub truncates beyond that)
- Capitalize the description after the colon
- No trailing period
- Blank line between subject and body

## Body (when warranted)
- Wrap at 72 characters
- Explain **why** and **what**, not **how** (the diff shows how)
- Reference issues/PRs in footers, not the subject
- Co-author and trailers go in footers (`Co-authored-by:`, `Refs:`, `BREAKING CHANGE:`)

## Branch + merge strategy (trunk-based)
- **Never commit directly to main** — always feature branch
- Always check `git branch --show-current` before any edit
- Branch names: `feat/desc`, `fix/desc`, `chore/desc`, `docs/desc`, `refactor/desc`
- Always merge with `--merge` (merge commit). Never `--rebase`, never `--squash`. Granular Conventional Commits stay intact. Delete branch after merge.
- One logical change per commit
- Never force-push to main
- All commits SSH-signed

## SemVer is downstream of commit type
Commit choice determines the next release: `fix:` → patch, `feat:` → minor, `feat!:` or `BREAKING CHANGE:` → major. Pick the type honestly — automated release tooling trusts it.

## Before committing
1. Verify branch: `git branch --show-current`
2. `git diff` — no secrets, debug logs, or unrelated hunks
3. Lint and tests pass
4. Subject passes the "If applied…" test
