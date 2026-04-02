# claude-brain

Personal Claude Code configuration that applies globally to all projects. Contains coding standards, infrastructure conventions, security rules, and reusable skills.

## What's in here

```
CLAUDE.md              # Global instructions (stack, style, security, git)
rules/                 # Always-on guardrails (loaded every session)
  ├── git-workflow.md  # Conventional commits, trunk-based dev, SSH signing
  ├── security.md      # Secret management, supply chain, container hardening
  └── typescript.md    # Strict TS, noUncheckedIndexedAccess, Zod, ESM
skills/                # On-demand workflows (invoked when relevant)
  ├── git-workflow/    # Commit, branch, PR conventions + recommended git config
  ├── hetzner-deploy/  # VM provisioning, Caddy, Tailscale, backups, monitoring
  ├── podman/          # Quadlets, Containerfiles, rootless gotchas, auto-update
  ├── security-audit/  # Code, infra, container, supply chain audit checklist
  └── ts-conventions/  # tsconfig, patterns, ESLint flat config, modern APIs
sync.sh                # Symlinks everything into ~/.claude/ for global use
```

## Setup

```bash
git clone git@github.com:jaanjah/claude-brain.git
cd claude-brain
./sync.sh
```

This creates symlinks from `~/.claude/` to the repo:
- `~/.claude/CLAUDE.md` → repo's `CLAUDE.md`
- `~/.claude/rules/*` → repo's `rules/*.md`
- `~/.claude/skills/*` → repo's `skills/*/`

Every Claude Code session in any project will load these automatically. Per-project `.claude/` files override the global config when needed.

## Making changes

Edit files in this repo, then commit and push. Symlinks mean `~/.claude/` stays in sync — no need to re-run `sync.sh` unless you add new rules or skills.

```bash
# After adding a new rule or skill:
./sync.sh
```

## Stack

- TypeScript (strict) + Node.js / Bun
- Podman (quadlets for production, compose for local dev)
- Hetzner Cloud VMs (Debian/Ubuntu)
- Tailscale mesh VPN + Tailscale SSH
- Caddy reverse proxy
- NixOS on local desktop
