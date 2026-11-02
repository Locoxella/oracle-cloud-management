# 📋 Project Backlog & Status

Live tracker of architectural initiatives and technical debt (empirically reconciled with OCI and Cloudflare APIs).

---

## 🚀 Active Initiatives (In-Progress)

- **[GitOps] 100% Declarative Convergence:** GitHub Actions CI/CD with Ephemeral Bastion Bridge execution, OpenTofu state persistence in OCI Object Storage, and automated Gitea mirroring.
- **[HA] Cross-Cloud Tunnel Redundancy:** Continuous auditing of Cloudflare Edge connections across AMD (`aether-tunnel`), ARM (`aether-tunnel-arm`), and Homelab (`pi-home-tunnel`).

---

## 📅 Roadmap Milestones (To-Do)

- [ ] **Kubernetes (K3s):** Deploy lightweight K3s server on `AlwaysFree-Ubuntu-ARM` (12 GB RAM) and join `Atlas-Node-01` as worker node.
- [ ] **Unified Telemetry:** Configure OCI Monitoring exporter with Grafana Alloy and Prometheus for unified alerting.
- [ ] **Always Free Autonomous Database:** Evaluate recreating an Always Free Autonomous Database if transactional data persistence requires it.

---

## ✅ Completed Milestones

- **[GitOps] 100% GitOps Architecture:** OpenTofu + Ansible + GitHub Actions + Ephemeral Bastion Bridge and rich step summaries.
- **[Capacity] ARM Instance Provisioned:** `AlwaysFree-Ubuntu-ARM` active with 2 OCPUs Ampere Altra and 12 GB RAM.
- **[IaC] Infrastructure Imported:** All 6 OCI resources (VCN, Subnet, VMs, Volume, Security List, Bastion) declared in `infrastructure/main.tf` with zero diffs.
- **[Storage] Persistent Block Volume:** 50 GB block volume (`Atlas-Vault-01`) attached to `Atlas-Node-01` at `/mnt/extra-data`.
- **[Security] Bastion Automation:** `connect_vm.sh` and `scp_to_vm.sh` with automatic node selection and trap cleanup.
- **[Migration] Gitea Migration to ARM:** Fully migrated to ARM node (`/opt/stacks/gitea/data`), obsolete AMD storage purged.
- **[Network] WireGuard VPN Gateway:** Active on AMD node (`wg-easy`) routing internal VCN traffic (`10.0.0.0/16`).
- **[Zero Trust] Cloudflare Integration:** All HTTP/WebSocket services exposed via Cloudflare Edge and protected with Google OAuth Access policies.
