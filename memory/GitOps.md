# 🔄 GitOps Architecture: GitHub + OpenTofu + Ansible (Cloud & Homelab)

This document details the architecture and operational blueprint to manage the **Aether** ecosystem (Oracle Cloud Always Free VMs + Raspberry Pi Homelab + Cloudflare Edge) under a **100% GitOps** model anchored in a public GitHub repository (`Locoxella/oracle-cloud-management`), with private Gitea maintained as an automated mirror and internal backup.

---

## 🏛️ 1. Separation of Concerns & Tooling Stack

| Layer | Primary Tool | Operational Scope |
| :--- | :--- | :--- |
| **Cloud & Edge Infrastructure (IaC)** | **OpenTofu / Terraform** | VCN (`10.0.0.0/16`), Subnets, Security Lists (`Aether-Guard-List`), OCI Compute instances (`Atlas-Node-01` AMD and `AlwaysFree-Ubuntu-ARM` ARM), Persistent Block Volumes (`Atlas-Vault-01`), OCI Bastion (`locoxella-bastion`), Cloudflare DNS records, Tunnels (`aether-tunnel`, `pi-home-tunnel`), and Zero Trust Access policies. |
| **System Configuration & Stacks (CaC)** | **Ansible** | Base system dependencies, mount points (`/mnt/extra-data`), swap configuration, firewall rules (`iptables` WireGuard NAT), dynamic timers (`gitea-firewall-sync.timer`), declarative Docker Compose stack synchronization, and **Raspberry Pi 4 (`10.0.0.75`)** service validation. |
| **Continuous Delivery & Verification** | **GitHub Actions** (+ Gitea Mirror) | Pre-flight security leak scanning, dry-run validations (`tofu validate`, `ansible-playbook --syntax-check`), owner-guarded convergence on `main`, visual `$GITHUB_STEP_SUMMARY` reporting, and empirical live post-apply health checks. |

---

## 🖥️ 2. Unified Node Inventory (OCI + Homelab HA)

1. **`atlas_arm` (`AlwaysFree-Ubuntu-ARM` — `10.0.0.200`):**
   - **Role:** Primary compute engine (2 Ampere OCPUs / 12 GB RAM).
   - **Workloads:** Gitea (`aether-git-seed`), Gitea Actions Runner (`gitea-runner`), Dockge ARM (`aether-dockge`), and HA Cloudflare Tunnel replica (`aether-tunnel-arm`, 4 edge connections).
2. **`atlas_amd` (`Atlas-Node-01` — `10.0.0.160`):**
   - **Role:** Edge VPN gateway and persistent storage (1 AMD OCPU / 1 GB RAM + 50 GB `Atlas-Vault-01`).
   - **Workloads:** WireGuard Easy (`wg-easy`), Subastas web app (`subastas-app`), Dockge AMD (`aether-dockge`), Autoheal (`aether-autoheal`), and HA Cloudflare Tunnel replica (`aether-tunnel`, 4 edge connections).
3. **`raspberry_pi` (`raspberrypi.home` — `10.0.0.75`):**
   - **Role:** Homelab node, local telemetry and cross-cloud observability (Raspberry Pi 4 8GB SSD).
   - **High Availability & Interconnect:**
     - **Independent Tunnel (`pi-home-tunnel`):** Provides independent Zero Trust management access to the homelab (`dockge-pi.solucionesaustral.com`) completely detached from OCI cloud availability.
     - **Cross-Node Observability:** Grafana Alloy and Uptime Kuma monitor OCI cloud endpoints and stream metrics across environments.

---

## 🔐 3. Public Repository Security Model

Operating in a public GitHub repository requires four non-negotiable security boundaries:

1. **Zero Hardcoded Secrets in History:**
   - No private keys, OCI API tokens, `.env` files, or `.tfstate` files are ever committed.
   - All historic commits are verified clean under GitHub Push Protection.
2. **Owner-Gated Execution:**
   - Apply workflows strictly enforce repository ownership and actor identity:
     ```yaml
     if: github.repository_owner == 'locoxella' && (github.actor == 'locoxella' || github.triggering_actor == 'locoxella')
     ```
   - Pull requests from external contributors are restricted to unprivileged dry-run validation.
3. **Option B Runner Architecture:**
   - GitHub-Hosted runners create ephemeral OCI Bastion sessions via `oci bastion session create-port-forwarding`, execute playbooks over dynamic SSH tunnels, and cleanly terminate all connections on exit traps.
4. **Decoupled State Storage:**
   - OpenTofu state is synchronized with OCI Object Storage bucket `Aether-Infra-State` (Namespace: `idsbz3qyzayx`).
