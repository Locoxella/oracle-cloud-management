# OCI CLI Troubleshooting & Lessons Learned

This file documents the errors encountered while managing Oracle Cloud resources and the correct way to handle them.

## 1. Resource Renaming Limits

### Bastion Service

- **Error:** `oci bastion bastion update` does not support `--name` or `--display-name`.
- **Finding:** Once a Bastion is created, its display name cannot be changed via the standard OCI CLI `update` command. It is immutable through this specific tool.
- **Solution:** Choose a definitive name during creation. If a rename is strictly necessary, the Bastion must be deleted and recreated.

## 2. Common Parameter Mismatches

### Bastion Sessions

- **Wrong:** `--target-os-user`
- **Correct:** `--target-os-username`
- **Wrong:** `--ttl`
- **Correct:** `--session-ttl` (Value in seconds).
- **Wrong:** `--db-workload ATP`
- **Correct:** `--db-workload OLTP` (in the `oci db autonomous-database create` command).
- **Error:** Password muy corto.
- **Dato:** El password de admin debe tener **al menos 12 caracteres**, incluyendo mayúsculas, minúsculas, números y símbolos.

## 3. Mandatory Plugin States

- **Issue:** Managed SSH sessions fail if the **Bastion plugin** is not in the `RUNNING` state inside the VM.
- **Fix:** Use `oci compute instance update` with the `--agent-config` parameter to enable the plugin, and wait a few minutes for the Oracle Cloud Agent to start the service inside the OS.
