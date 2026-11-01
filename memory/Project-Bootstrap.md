# 🛠️ Project: Bootstrap & Disaster Recovery

This document outlines the automation and steps required to rebuild the entire platform from zero should disaster recovery be necessary.

## Tooling Stack

- **OpenTofu / Terraform:** Cloud infrastructure definition (VCN, Subnets, VMs, Storage).
- **Ansible:** Operating system configuration, package management, and security hardening.
- **GitOps:** The continuous delivery engine that applies declarative changes automatically.

## Infrastructure as Code Baseline

All resources established in the Oracle Cloud Console are imported into code:

- [x] **VCN & Subnets:** Declared as `oci_core_vcn.aether_network` in `infrastructure/main.tf`.
- [x] **Security Lists:** Declared as `oci_core_security_list.aether_guard_list`.
- [x] **OCI Bastion:** Declared as `oci_bastion_bastion.locoxella_bastion`.
- [x] **Instances:** Declared as `oci_core_instance.atlas_node_01` and `oci_core_instance.alwaysfree_ubuntu_arm`.
- [x] **Block Storage:** Declared as `oci_core_volume.atlas_vault_01`.

## Operational Roadmap

- **Observability Hub:** Unified telemetry with Grafana Alloy and Uptime Kuma cross-monitoring between OCI cloud nodes and local Homelab.
- **Immutable Backups:** Snapshot retention and object storage archiving for persistent block volumes.
