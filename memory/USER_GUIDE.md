# 📘 User Guide & Operations Manual

This guide provides operational instructions and quick commands for human maintainers managing the Oracle Cloud Infrastructure (OCI) instances and homelab nodes.

---

## ⚡ Instant VM Access via Bastion CLI

The [`connect_vm.sh`](../connect_vm.sh) script abstracts all complexity associated with the OCI Bastion service. It creates an ephemeral port-forwarding session, establishes a background SSH tunnel on a dynamic local port, and opens a shell session directly to the target instance.

### 1. Interactive Shell Sessions

```bash
# Connect to AMD node (Atlas-Node-01 - 10.0.0.160)
./connect_vm.sh

# Connect to ARM node (AlwaysFree-Ubuntu-ARM - 10.0.0.200)
./connect_vm.sh arm
```

### 2. Direct Remote Command Execution

You can pass shell commands directly:

```bash
# Check Docker containers on AMD
./connect_vm.sh "docker ps"

# Check Docker containers on ARM
./connect_vm.sh arm "docker ps"

# Inspect disk space on persistent storage (/mnt/extra-data)
./connect_vm.sh "df -h /mnt/extra-data"
```

### 3. File Transfers via Bastion

Use [`scp_to_vm.sh`](../scp_to_vm.sh) to copy files to remote instances through an ephemeral Bastion tunnel:

```bash
# Copy a local file to AMD node
./scp_to_vm.sh ./local_file.txt /home/ubuntu/

# Copy to a specific directory with sudo privileges
./scp_to_vm.sh ./compose.yaml /tmp/compose.yaml
./connect_vm.sh "sudo mv /tmp/compose.yaml /mnt/extra-data/stacks/network/compose.yaml"
```

### 4. Session Cleanup

If a session remains active after an abrupt disconnect:

```bash
./connect_vm.sh disconnect
```

---

## 🌐 Cloudflare Edge & Zero Trust Management

- **Cloudflare Zone:** `solucionesaustral.com`
- **Tunnels:**
  - `aether-tunnel` (`557b120e-553b-42f5-bc65-d2ffb9800ea6`): Active across AMD and ARM in High Availability mode (8 connections).
  - `pi-home-tunnel` (`63795e0e-ef77-4758-aa7a-9b75611b5d2c`): Homelab ingress (4 connections).
- **Audit Tool:**
  ```bash
  python3 scripts/verify-cf-health.py
  ```

---

## 🔍 Pre-Flight & Post-Apply Verification

Run the unified test suite before pushing or modifying infrastructure:

```bash
# Dry-run validation (syntax, secrets, schemas, OpenTofu validate)
./scripts/verify_infra.sh

# Empirical live verification (audits live HTTP endpoints and Cloudflare tunnels)
./scripts/verify_infra.sh --live
```
