# 🍎 Project: The Seed (Private Git & CI/CD)

This project establishes the foundation of the platform: a centralized private Git server with native CI/CD automation capabilities.

## 🛠️ Selected Engine: Gitea / Forgejo

Gitea was selected for the following reasons:

1. **Lightweight Footprint:** Built in Go, consuming less than 250 MB RAM.
2. **Gitea Actions:** Provides CI/CD pipelines fully compatible with GitHub Actions workflow syntax.
3. **All-in-One Hub:** Includes built-in package registry, release management, and issue tracking.
4. **Zero Trust Access:** Uses Cloudflare Tunnels to publish endpoints securely without opening public listening ports on the host.

## 📍 Topology & Storage

- **Active Host:** `AlwaysFree-Ubuntu-ARM` (ARM A1.Flex - 12 GB RAM).
- **Persistent Data:** Local host path at `/opt/stacks/gitea/data`.
- **Database:** SQLite3 (stable and lightweight).
- **Ingress:** Active-Active Cloudflare Tunnel (`aether-tunnel-arm`).

## 🗺️ Completed Milestones

1. [x] **Base Bootstrap:** Docker, Compose, and core utilities configured.
2. [x] **Containerization:** Gitea deployed via Docker Compose (`bootstrap/stacks/git/compose.yaml`).
3. [x] **Runner Deployment:** Gitea Actions runner (`gitea-runner`) deployed with access to the Docker socket.
4. [x] **GitOps Synchronization:** Dual-mirroring between public GitHub and private Gitea.
