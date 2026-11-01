# Oracle Cloud Management Knowledge Base

> 💡 **Maintainer Guide:** For quick access and connection helpers to the cloud VMs, refer to [USER_GUIDE.md](USER_GUIDE.md).

This directory contains architectural specifications, operational runbooks, and inventory records for the **Aether** ecosystem running across Oracle Cloud (Always Free tier), Cloudflare Zero Trust, and the local Homelab.

---

## 🖥️ Current Infrastructure Summary

### 1. Compute Instances

- **VM 1 (AMD Micro):** `Atlas-Node-01`
  - **OCID:** `ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq`
  - **Private IP:** `10.0.0.160` | **Public IP:** `129.153.185.184`
  - **Specs:** 1 OCPU AMD EPYC / 1 GB RAM / 47 GB Boot.
  - **Block Storage:** 50 GB block volume attached (`Atlas-Vault-01`) mounted at `/mnt/extra-data`.
  - **Access:** `./connect_vm.sh amd` (via OCI Bastion).

- **VM 2 (ARM A1.Flex):** `AlwaysFree-Ubuntu-ARM`
  - **OCID:** `ocid1.instance.oc1.iad.anuwcljsinltkcacrv222dlla7akmfmgkhwspugq6bevmfvevlvkk5ooul5q`
  - **Private IP:** `10.0.0.200` | **Public IP:** `129.213.96.28`
  - **Specs:** 2 OCPUs Ampere Altra / 12 GB RAM / 47 GB Boot.
  - **Access:** `./connect_vm.sh arm` (via OCI Bastion).

### 2. Block & Object Storage

- **Block Volume:** `Atlas-Vault-01` (50 GB)
  - **OCID:** `ocid1.volume.oc1.iad.abuwcljtauvx5cicoglov3x5w5x7pl4sr2is3oygyhq24uu2dspiqel6c2aq`
  - **Attachment:** Attached to `Atlas-Node-01` at `/mnt/extra-data`.
- **Object Storage Bucket:** `Aether-Infra-State`
  - **Namespace:** `idsbz3qyzayx`
  - **Purpose:** OpenTofu remote state persistence and backup.

---

## 📚 Technical Documentation Index

- **[Resource Inventory (Inventory.md)](Inventory.md):** Always Free tier quotas, allocation breakdown, and remaining capacity.
- **[GitOps Architecture (GitOps.md)](GitOps.md):** End-to-end GitOps workflow with Option B ephemeral Bastion execution.
- **[Network Architecture (Network.md)](Network.md):** VCN routing, Security Lists, and subnets.
- **[Cloudflare Zero Trust (Cloudflare.md)](Cloudflare.md):** Tunnel HA topology and Access policies.
- **[Troubleshooting Runbook (Troubleshooting.md)](Troubleshooting.md):** Diagnostic playbooks and disaster recovery steps.
- **[Backlog & Roadmap (Backlog.md)](Backlog.md):** Architectural initiatives and planned milestones.
