# Security Rules

- Never store secrets in code or commit .env files — use SOPS + age or Podman secrets
- Always use environment variables or encrypted secret files for credentials
- When opening a port on a Hetzner VM, remind to add UFW rule
- SSH is Tailscale-only — never suggest exposing port 22 publicly
- Use least-privilege API tokens (scoped, not master keys)
- Validate and sanitize all external input (Zod at API boundaries)
- Prefer read-only DB connections where writes aren't needed
- Containers must run rootless with `NoNewPrivileges=true` and `DropCapability=ALL`
- Use `ignore-scripts=true` in `.npmrc` to block supply-chain install scripts
