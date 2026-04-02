---
name: security-audit
description: Run a security review on code, config, or infrastructure. Use when asked to review for vulnerabilities, before deploying, or when the user mentions security concerns.
---

# Security Audit

When performing a security audit:

## Code
- Hardcoded secrets or tokens
- Unsanitized user input going into DB queries, shell commands, or file paths
- Missing auth/authz checks on routes (validate ownership, not just authentication)
- Insecure dependencies — run `npm audit`, check Socket.dev for supply-chain risks
- Sensitive data logged or exposed in error messages
- Prototype pollution — use `Map` for dynamic keys, avoid `obj[userInput]`
- ReDoS — flag complex regex patterns, suggest `safe-regex2` lint

## Dependencies / Supply Chain
- `ignore-scripts=true` in `.npmrc`? (blocks malicious install scripts)
- Lockfile committed and validated? (`lockfile-lint`)
- Dependency update automation in place? (Renovate)
- Pinned image digests in production Containerfiles? (not just tags)

## Secrets
- Are secrets managed with SOPS + age or Podman secrets? (plain `.env` on disk is a flag)
- `.env` files committed to git?
- API tokens scoped to least privilege?

## Infrastructure
- UFW rules — are unnecessary ports open? (only 80, 443 for web; SSH goes through Tailscale)
- Tailscale ACLs — is inter-node traffic restricted? (default deny)
- SSH config — password auth disabled? Root login disabled? Tailscale-only?
- Caddy security headers set? (HSTS, CSP, X-Content-Type-Options, COOP/CORP/COEP, no X-XSS-Protection)

## Containers (Podman/Quadlets)
- Running rootless?
- `UserNS=keep-id` set?
- `NoNewPrivileges=true` and `DropCapability=ALL`?
- `ReadOnly=true` where possible?
- Base images minimal? (slim/distroless, not full OS)
- Image scanning with Trivy?

## Output format
List findings as: [CRITICAL / HIGH / MEDIUM / LOW] — description — suggested fix
