# 📊 Resource Inventory (Oracle Always Free)

This document tracks all resources claimed under the "Always Free" tier and remaining capacity (empirically reconciled with the OCI API).

---

## 1. Compute (Virtual Machines)

| Resource | Allocated | Total Available | Remaining Quota |
| :--- | :--- | :--- | :--- |
| **AMD Compute (`VM.Standard.E2.1.Micro`)** | 1 (`Atlas-Node-01`) | 2 Instances | **1 Instance** (Free) |
| **ARM Compute (`VM.Standard.A1.Flex`)** | 1 (`AlwaysFree-Ubuntu-ARM`) | 4 OCPUs / 24 GB RAM | **2 OCPUs / 12 GB RAM** (Free for expansion or 2nd ARM VM) |

### Active Compute Details:
1. **`Atlas-Node-01` (AMD Micro):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq`
   * **Private IP:** `10.0.0.160` | **Public IP:** `129.153.185.184`
   * **Specs:** 1 OCPU AMD / 1 GB RAM / 47 GB Boot Volume.
   * **Services:** Dockge, WireGuard Easy, Autoheal, Cloudflare Tunnel, Subastas Web App.
2. **`AlwaysFree-Ubuntu-ARM` (ARM A1.Flex):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljsinltkcacrv222dlla7akmfmgkhwspugq6bevmfvevlvkk5ooul5q`
   * **Private IP:** `10.0.0.200` | **Public IP:** `129.213.96.28`
   * **Specs:** 2 OCPUs Ampere Altra / 12 GB RAM / 47 GB Boot Volume.
   * **Services:** Gitea (Forgejo), Gitea Actions Runner, Dockge ARM, Cloudflare Tunnel ARM.

---

## 2. Storage (Block & Boot Volumes)

Total Always Free Storage Quota: **200 GB**

| Volume | Size | Associated Instance | Mount Status |
| :--- | :--- | :--- | :--- |
| Boot Volume (`Atlas-Node-01`) | 47 GB | `Atlas-Node-01` (AMD) | In use (`/dev/sda`) |
| Boot Volume (`AlwaysFree-Ubuntu-ARM`) | 47 GB | `AlwaysFree-Ubuntu-ARM` (ARM) | In use (`/dev/sda`) |
| `Atlas-Vault-01` (Block Volume) | 50 GB | `Atlas-Node-01` | In use (`/mnt/extra-data`) |
| **Total Allocated** | **144 GB** | — | — |
| **Remaining Free Storage** | **56 GB** | — | **56 GB unallocated** (available for new volume or expansion) |

---

## 3. Managed Databases

| Service | Always Free Quota | Current Status |
| :--- | :--- | :--- |
| **Autonomous Database** | 2 Instances (20 GB storage each) | **Free** (0 active instances in compartment) |
| **NoSQL Database** | 133M reads/month, 50 GB storage | **Free** (0 provisioned) |

---

## 4. Networking & Storage Services

| Service | Tier Quota | Current Status | Operational Notes |
| :--- | :--- | :--- | :--- |
| **Flexible Load Balancer** | 1 Instance (10 Mbps) | **Free** | Unallocated (ingress routed via Cloudflare Tunnels) |
| **Outbound Data Transfer** | 10 TB Monthly | In use | Regular egress and WireGuard VPN tunneling |
| **OCI Bastion Service** | 1 Bastion (`locoxella-bastion`) | In use | Secure SSH port-forwarding to private subnet `10.0.0.0/16` |
| **Object Storage** | 10 GB Standard / 10 GB Archive | In use | Bucket `Aether-Infra-State` (Namespace: `idsbz3qyzayx`) |
