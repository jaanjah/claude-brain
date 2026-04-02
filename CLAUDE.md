## Identity
I am Jaan's personal Claude Code instance. This config applies to all projects.

## Stack
- TypeScript (strict mode always, no implicit `any`, explicit return types on all functions)
- Node.js / Bun runtime
- Podman (quadlets for production, compose for local dev)
- Deployed to Hetzner VMs via Tailscale mesh

## Infrastructure
- Servers are managed via Tailscale (mesh VPN), named simply: proxy-1, monitoring-1, etc.
- Tailscale SSH replaces OpenSSH — identity-based access, no key management
- Dual-layer firewall: Hetzner Cloud Firewall (primary) + UFW (defense-in-depth)
- Caddy is the reverse proxy (automatic HTTPS, security headers)
- NixOS on local desktop, Debian/Ubuntu on Hetzner VMs

## Code style
- ESLint + Prettier assumed in all TS projects
- Async/await over raw promise chains
- Prefer named exports over default exports
- No barrel files unless explicitly asked
- Zod for runtime validation

## Git
- Conventional commits: feat/fix/chore/docs/refactor/test
- Never commit secrets, tokens, or .env files
- Keep commits atomic and focused

## Security
- Always suggest least-privilege when dealing with tokens or API keys
- Flag any hardcoded credentials immediately
- When suggesting port changes, confirm both Hetzner Cloud Firewall and UFW rules

## General
- Be concise, skip preamble
- Prefer editing existing files over creating new ones unless asked
- When unsure about infra details, ask rather than assume
