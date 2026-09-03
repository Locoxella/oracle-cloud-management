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

## 4. Cloudflare Distroless Containers & Healthchecks

- **Issue / Symptom:** Cloudflare Tunnel (`cloudflared`) drops continuously with **Error 1033**.
- **Root Cause:** The official `cloudflare/cloudflared` image is built on a minimal Distroless image (no `/bin/sh` or `/bin/bash`). If `docker-compose.yml` uses `CMD-SHELL` for its healthcheck, Docker fails to spawn shell (`stat /bin/sh: no such file or directory`), causing `autoheal` or Docker daemon to kill/restart the container continuously.
- **Fix:** Use direct executable format (`CMD`) instead of `CMD-SHELL`:
  ```yaml
  healthcheck:
    test: ["CMD", "cloudflared", "--version"]
    interval: 30s
    timeout: 10s
    retries: 3
  ```

## 5. Maintenance of Gitea Actions Runner (`act_runner`)

- **Issue:** Workflows fail with `Cannot find: node in PATH`.
- **Root Cause:** By default, if `GITEA_RUNNER_LABELS` maps `self-hosted:host` or `ubuntu-latest:host`, jobs attempt to run on the host VM directly, where Node.js or required CLI binaries might be missing.
- **Maintenance / Fix:** Always configure `gitea-runner` container with Docker socket access (`-v /var/run/docker.sock:/var/run/docker.sock`) and force all labels to use Node.js docker images:
  ```bash
  docker run -d --name gitea-runner --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e GITEA_INSTANCE_URL=http://10.0.0.160:3000 \
    -e GITEA_RUNNER_REGISTRATION_TOKEN=<TOKEN> \
    -e GITEA_RUNNER_NAME=atlas-node-runner \
    -e GITEA_RUNNER_LABELS="ubuntu-latest:docker://node:18-bullseye,ubuntu-22.04:docker://node:18-bullseye,self-hosted:docker://node:18-bullseye" \
    gitea/act_runner:nightly
  ```
