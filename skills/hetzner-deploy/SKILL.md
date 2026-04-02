---
name: hetzner-deploy
description: Deploy or provision a Hetzner VM, set up a new server, configure firewall/SSH hardening, or deploy an app to a Hetzner server.
---

# Hetzner VM Deploy

## Initial setup checklist

### Firewall (dual-layer)
- [ ] **Hetzner Cloud Firewall** (primary) — blocks traffic before it hits the VM. Allow only 80, 443 for web. No port 22 (SSH goes through Tailscale).
- [ ] **UFW** (defense-in-depth) — same rules as Cloud Firewall, catches anything if the cloud layer fails.

### Tailscale
- [ ] Server joined to the tailnet and verified
- [ ] **Tailscale SSH enabled** — replaces OpenSSH entirely (identity-based access, no key management)
- [ ] If keeping OpenSSH as emergency backup: bind to Tailscale IP only (`ListenAddress 100.x.y.z`)
- [ ] ACLs configured — tag servers (`tag:server`), restrict inter-node traffic, default deny
- [ ] MagicDNS enabled — use hostnames not IPs in configs
- [ ] Node key expiry set (90-180 days)
- [ ] Device approval enabled for new devices

### SSH (if keeping OpenSSH)
- [ ] `PasswordAuthentication no`
- [ ] `PermitRootLogin no`
- [ ] Bound to Tailscale interface only

### System
- [ ] Non-root user for app processes
- [ ] `loginctl enable-linger` for rootless Podman user
- [ ] Unattended upgrades enabled for security patches
- [ ] Podman installed, cgroup v2 verified
- [ ] Caddy configured as reverse proxy

### DNS
- [ ] CAA record set: `0 issue "letsencrypt.org"` (restricts cert issuance)
- [ ] DNSSEC enabled at registrar

## Caddy reverse proxy

```caddyfile
(security_headers) {
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=()"
        Cross-Origin-Opener-Policy "same-origin"
        -Server
    }
}

app.example.com {
    import security_headers
    reverse_proxy 127.0.0.1:8080

    request_body {
        max_size 10MB
    }

    log {
        output file /var/log/caddy/access.log
    }
}
```

- Caddy handles automatic HTTPS and cert renewal
- CSP is app-specific — define per-site
- Remove `Server` header with `-Server`
- Set `request_body max_size` to prevent memory exhaustion
- For rate limiting: `caddy-ratelimit` plugin (by mholt)

## Deployment workflow

### Simple: SSH + restart
```bash
ssh server 'cd /app && git pull && npm ci && npm run build && systemctl --user restart my-app'
```

### With Podman auto-update (preferred)
Build and push image in CI → quadlet has `AutoUpdate=registry` → `podman-auto-update.timer` pulls and restarts automatically. Zero manual deployment.

### CI/CD pipeline
GitHub Actions: build image → push to GHCR → SSH to server → `podman pull` + `systemctl --user restart`

## Backup strategy

| Layer | Tool | Target | Frequency |
|-------|------|--------|-----------|
| App data / DB dumps | restic | Hetzner Storage Box (SFTP) | Daily |
| Offsite copy | restic | Backblaze B2 or Hetzner Object Storage | Weekly |
| VM snapshots | Hetzner API | Hetzner snapshots | Before upgrades only |

- **restic → Hetzner Storage Box** is cheapest (no egress fees, native SFTP support)
- **Hetzner snapshots are NOT backups** — same infrastructure, use for pre-upgrade safety nets only
- **Test restores regularly**

## Monitoring

- **Uptime Kuma** — HTTP/TCP/DNS checks, 90+ notification providers. Deploy via Podman quadlet.
- **Beszel** — lightweight system metrics (CPU, memory, disk, network). ~50MB RAM, replaces Grafana+Prometheus for solo devs.
- Check `/var/run/reboot-required` after unattended-upgrades — alert and reboot during planned maintenance.

## systemd hardening

Add to any service unit (including Caddy, app services):
```ini
[Service]
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
NoNewPrivileges=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
SystemCallArchitectures=native
LockPersonality=true
RestrictRealtime=true
```

Score your services: `systemd-analyze security your-app.service` (lower is better, aim for <5).

## Unattended upgrades

```bash
apt install unattended-upgrades apt-listchanges
dpkg-reconfigure -plow unattended-upgrades
```

Key settings in `/etc/apt/apt.conf.d/50unattended-upgrades`:
- Security origins only (default on Ubuntu)
- `Automatic-Reboot "false"` — reboot manually during maintenance
- Enable mail notifications

## Cost optimization

- **CAX (ARM)** over CX/CPX when possible — best performance/EUR, most Node.js apps work on ARM64
- **EU regions** (Falkenstein, Nuremberg) get 20TB included transfer (US: 1TB, Singapore: 0.5TB)
- **Local NVMe** is included and fast — only use Volumes if you need detachable storage
- **Delete unused resources** — floating IPs, load balancers, and volumes bill even when unattached
- **Hourly billing** is capped at monthly rate — use short-lived instances for CI runners

## Provisioning at scale

When managing 2+ servers, use **OpenTofu** with the `hetznercloud/hcloud` provider:
- Declare servers, firewalls, networks, SSH keys
- Pass cloud-init as `user_data`
- For a single server, cloud-init + a bash provisioning script over SSH is fine
