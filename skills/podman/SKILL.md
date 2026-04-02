---
name: podman
description: Write or review Podman configs — quadlets, compose files, or Containerfiles. Use when containerizing an app, setting up services, or reviewing container config. Prefer quadlets for production services.
---

# Podman Conventions

Podman runs rootless by default — keep it that way.

## Quadlets (preferred for production)

Place quadlet files in:
- `~/.config/containers/systemd/` (rootless)
- `/etc/containers/systemd/` (root/system-level)

After adding or changing: `systemctl --user daemon-reload`
Validate without reloading: `podman quadlet --dryrun`

### Production-hardened .container template
```ini
[Unit]
Description=My App
After=network-online.target

[Container]
Image=ghcr.io/youruser/my-app:latest
ContainerName=my-app
AutoUpdate=registry

PublishPort=127.0.0.1:8080:3000
Network=app.network

EnvironmentFile=%h/.config/myapp/.env
Secret=db-password,type=env,target=DATABASE_PASSWORD

UserNS=keep-id
NoNewPrivileges=true
ReadOnly=true
DropCapability=ALL
Tmpfs=/tmp
Tmpfs=/run

HealthCmd=curl -sf http://localhost:3000/health || exit 1
HealthInterval=30s
HealthRetries=3
HealthStartPeriod=15s
HealthOnFailure=kill
Notify=healthy

Volume=app-data.volume:/data

[Service]
Restart=on-failure
RestartSec=5s
TimeoutStartSec=120

[Install]
WantedBy=default.target
```

### .network example
```ini
[Network]
NetworkName=app
Subnet=10.89.0.0/24
DisableDNS=false
```
Note: the default `podman` network does NOT support DNS resolution. Always create a custom network for container-to-container DNS.

### .volume example
```ini
[Volume]
VolumeName=app-data
```

### Quadlet conventions
1. **One service per `.container` file**
2. **Use `.network` and `.volume` files** — reference by name in containers
3. **`EnvironmentFile`** over inline `Environment` — never hardcode secrets
4. **`Secret=`** for sensitive values — use `podman secret create` with SOPS + age
5. **`UserNS=keep-id`** — maps container UID to host user for volume permissions
6. **`Notify=healthy`** — delays systemd "started" until healthcheck passes (set `TimeoutStartSec` high enough)
7. **`HealthOnFailure=kill`** — let systemd's `Restart=on-failure` handle restarts cleanly
8. **`AutoUpdate=registry`** — enables `podman auto-update` for hands-free image pulls
9. **Bind ports to `127.0.0.1` only** — Caddy handles public traffic
10. **`ReadOnly=true` + `Tmpfs`** for scratch dirs — minimal writable surface

### Security hardening checklist
```ini
NoNewPrivileges=true
ReadOnly=true
DropCapability=ALL
# AddCapability= only what's strictly needed (e.g., NET_BIND_SERVICE)
Tmpfs=/tmp
Tmpfs=/run
SecurityLabelDisable=true   # if not using SELinux (Debian/Ubuntu)
```

Additional via PodmanArgs if needed:
```ini
PodmanArgs=--pids-limit=256 --memory=512m --cpus=1.0
```

### Auto-update setup
```bash
# Enable the timer (runs daily by default)
systemctl --user enable --now podman-auto-update.timer

# Manual check
podman auto-update --dry-run

# Rollback if new image fails
podman auto-update --rollback
```

## Rootless gotchas

**Lingering sessions (critical):**
```bash
sudo loginctl enable-linger $USER
```
Without this, all rootless containers die when you log out of SSH.

**Volume permissions:**
Use `:U` suffix to auto-chown: `Volume=/data:/data:U`
Or manually: `podman unshare chown 1000:1000 /path/to/volume`

**Ports below 1024:**
Not needed if Caddy handles 80/443. If required:
```bash
# /etc/sysctl.d/99-podman.conf
net.ipv4.ip_unprivileged_port_start=0
```

**Storage path:** Rootless uses `~/.local/share/containers/storage/`. On VMs, consider symlinking to a separate volume to avoid filling root.

**Cgroup v2:** Required for resource limits. Verify: `stat -fc %T /sys/fs/cgroup` → `cgroup2fs`

## Containerfile best practices

```dockerfile
FROM docker.io/library/node:22-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM cgr.dev/chainguard/node:latest
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER nonroot
CMD ["dist/index.js"]
```

- **Multi-stage builds** — build deps in full image, copy only artifacts to slim/distroless
- **Base images**: Chainguard (near-zero CVEs) > distroless > slim. Avoid full OS images.
- **Pin by digest** in production: `FROM node@sha256:abc123...`
- **`.containerignore`**: exclude `.git`, `node_modules`, `.env`, `*.md`
- **Layer ordering**: dependencies before source code (better cache hits)
- **Scan with Trivy**: `trivy image --severity HIGH,CRITICAL your-image:tag`

## Logging

Default for quadlets is `passthrough` log driver — logs go directly to systemd journal.

```bash
journalctl --user -xeu my-app.service              # full logs
journalctl --user -u my-app.service --since "1h ago" -f  # follow
```

Have your app output JSON to stdout for structured logging. journald preserves it.

Configure rotation in `/etc/systemd/journald.conf`:
```ini
[Journal]
SystemMaxUse=2G
MaxRetentionSec=30day
```

## Networking

- **Default rootless network driver: pasta** (Podman 5.0+) — faster than slirp4netns
- **Container-to-container DNS** requires a custom network (not the default `podman` network)
- **Pods** (`.pod` files) share a network namespace — containers talk via `localhost`
- For Tailscale-only services, bind to the Tailscale IP: `PublishPort=100.x.y.z:8080:3000`

## Secrets with SOPS + age

```bash
# Decrypt and load into Podman
sops -d secrets.enc.yaml | yq '.db_password' | podman secret create db-password -

# Reference in quadlet
Secret=db-password,type=env,target=DATABASE_PASSWORD
```

## Podman Compose (for local dev only)

Use when you need a quick multi-container setup locally or the project already has a `compose.yaml`.

1. **Named volumes** over bind mounts for persistent data
2. **Health checks** on all services that others depend on
3. **Env vars** — use `.env` file, never hardcode in compose file
4. **Networks** — use named networks, don't expose unnecessary ports
5. **Resource limits** — set `mem_limit` on constrained VMs

### Migration to quadlets
Each compose service → `.container` file, named volumes → `.volume`, networks → `.network`, `depends_on` → `After=` + `Requires=` in `[Unit]`.
