# 🤖 AI Agent Guidelines & Context (AGENT.md)

## 📌 Fundamental Project Context

This repository (`oracle-cloud-management`) manages the Infrastructure as Code (IaC), server configurations, container deployments, and operational documentation for the **Aether** ecosystem hosted in **Oracle Cloud Infrastructure (OCI - Always Free tier)**.

### ⚠️ Execution & Environment Interpretation Rule

* **Target Environment Reference**: Whenever the user asks about "the VM", "running containers", "node status", or any related system inquiry, **IT ALWAYS REFERS TO THE REMOTE CLOUD VMS IN ORACLE CLOUD** (`Atlas-Node-01` AMD or `AlwaysFree-Ubuntu-ARM` ARM), **NEVER** to the user's local workstation where the agent/IDE runs.
* **Proactive Safe Execution**: Automatically execute safe, non-destructive diagnostic and maintenance commands directly rather than asking the user to run them manually.

---

## 🖥️ Remote Node Topology

The infrastructure runs on **two active OCI compute instances**:

1. **`Atlas-Node-01` (AMD Micro - Ubuntu):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq`
   * **Private IP:** `10.0.0.160` | **Public IP:** `129.153.185.184`
   * **Specifications:** 1 OCPU AMD EPYC / 1 GB RAM / 47 GB Boot Volume.
   * **Persistent Block Volume:** Mounted at `/mnt/extra-data` (`Atlas-Vault-01`, 50 GB).
   * **Bastion Connection:** `./connect_vm.sh amd` (or `./connect_vm.sh`).

2. **`AlwaysFree-Ubuntu-ARM` (ARM A1.Flex - Ubuntu):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljsinltkcacrv222dlla7akmfmgkhwspugq6bevmfvevlvkk5ooul5q`
   * **Private IP:** `10.0.0.200` | **Public IP:** `129.213.96.28`
   * **Specifications:** 2 OCPUs Ampere Altra / 12 GB RAM / 47 GB Boot Volume.
   * **Local Storage:** Boot volume only (`/dev/sda1`, ~45 GB usable).
   * **Stack Layout:** `/opt/stacks/{gitea,git-runner,management,network}`.
   * **Bastion Connection:** `./connect_vm.sh arm`.

---

## 📦 Running Workloads & Services

### On ARM Node (`AlwaysFree-Ubuntu-ARM` - 10.0.0.200)

1. **Gitea (Forgejo):**
   * **Container:** `aether-git-seed`
   * **Role:** Central private Git server and package registry.
   * **Ports:** HTTP `3000`, SSH `2222`.
   * **Data Path:** `/opt/stacks/gitea/data` (SQLite3).
   * **URL:** `https://git.solucionesaustral.com`
2. **Gitea Actions Runner:**
   * **Container:** `gitea-runner`
   * **Role:** CI/CD container runner attached to Docker socket.
3. **Cloudflare Tunnel (ARM HA Replica):**
   * **Container:** `aether-tunnel-arm`
   * **Role:** Active-Active HA ingress connected to Cloudflare Edge.
4. **Dockge (ARM):**
   * **Container:** `aether-dockge` (Port `5001`).
   * **Role:** Compose stack manager for `/opt/stacks`.

### On AMD Node (`Atlas-Node-01` - 10.0.0.160)

1. **WireGuard Easy (`wg-easy`):**
   * **Container:** `wg-easy`
   * **Role:** VPN gateway providing secure access to the `10.0.0.0/16` subnet and US egress.
   * **Port:** UDP `51820` (open in OCI Security List & iptables).
2. **Dockge (AMD):**
   * **Container:** `aether-dockge` (Port `5001`).
   * **Role:** Stack manager for `/mnt/extra-data/stacks` and `/mnt/extra-data/infrastructure`.
   * **URL:** `https://dockge.solucionesaustral.com` (Protected by Cloudflare Zero Trust).
3. **Cloudflare Tunnel (AMD HA Replica):**
   * **Container:** `aether-tunnel`
   * **Role:** Active-Active HA ingress (4 edge connections).
4. **Subastas Web Application:**
   * **Container:** `subastas-app` (Port `8000`).
   * **URL:** `https://subastas.solucionesaustral.com`
5. **Autoheal:**
   * **Container:** `aether-autoheal` (Monitors and restarts unhealthy containers).

---

## 🔄 Dual GitOps CI/CD Architecture (GitHub & Gitea)

### 1. Primary & Automated (GitHub Actions)

* **Trigger:** Runs automatically on push / PR to `main` (only by repository owner).
* **Smart Path Filtering:**
  * Evaluates `git diff --name-only` against previous commit.
  * Skips OpenTofu (`infrastructure/**`) and Ansible (`ansible/**`, `bootstrap/**`) steps if no relevant changes occurred.
  * Never installs runtime dependencies (OCI CLI, Ansible, OpenTofu, SSH credentials) if neither component changed.
  * Can be manually overridden via `workflow_dispatch` to force a complete run.
* **Semantic Versioning & Tagging:** Automatically runs `scripts/release_version.py` to calculate independent SemVer tags based on Conventional Commits (`tofu-v*` and `ansible-v*`) and pushes tags to both GitHub and Gitea.
* **Visual Step Summaries:** Publishes rich Markdown summaries to `$GITHUB_STEP_SUMMARY` and stdout, explicitly indicating whether components were converged or skipped.

### 2. Private Backup & Mirror (Gitea Actions)

* **Automated Sync (`sync_from_github.yml`):** Runs on a daily schedule (`cron: '0 3 * * *'`) pulling changes from upstream GitHub.
* **Automated Code Validation (`validation.yml`):** Runs on push / PR within Gitea to independently verify syntax, schemas, and dry-run health.
* **Manual Provisioning Fallback (`gitops_manual.yml`):**
  * **STRICTLY MANUAL (`workflow_dispatch` only)**.
  * Never triggers cloud provisioning or Ansible configuration automatically in Gitea to prevent concurrent or duplicate runs with GitHub.
  * Allows selecting execution target (`all`, `tofu`, `ansible`) in emergency scenarios where GitHub is unavailable.
