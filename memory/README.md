# Oracle Cloud Management Memory

> 💡 **Guía Rápida para Humanos:** Para acceder rápido a las VMs, consulta [GUIA_HUMANA.md](GUIA_HUMANA.md).

This folder contains the "memory" and scripts used to manage Always Free resources in Oracle Cloud.

## Current Infrastructure

### 1. Compute Instances

- **VM 1 (AMD Micro):** `Atlas-Node-01`
  - **OCID:** `ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq`
  - **Private IP:** `10.0.0.160`
  - **Status:** Running.
  - **Storage:** Extra 50GB attached as `/dev/sdb`.

### 2. Storage

- **Extra Storage 1:** `Atlas-Vault-01` (50 GB)
  - **OCID:** `ocid1.volume.oc1.iad.abuwcljtauvx5cicoglov3x5w5x7pl4sr2is3oygyhq24uu2dspiqel6c2aq`
  - **Status:** Attached to Atlas-Node-01.

### Gestión de la Plataforma

- **[Inventario de Recursos](Inventory.md):** Qué tenemos y qué nos queda del Tier Gratuito.
- **[Backlog & Roadmap](Backlog.md):** User stories y estado de las iniciativas.

## Proyectos Activos

1. **[Aether-Cluster (Kubernetes)](Project-Kubernetes.md):** Plan para el cluster K3s multi-zonal.
2. **[Bootstrap & IAAC](Project-Bootstrap.md):** Automatización con OpenTofu y Ansible para DR.
3. **[GitOps con Atlantis](GitOps.md):** Orquestación de infraestructura desde Pull Requests.

## Networking & Security

Detailed docs: [Network.md](Network.md) | [Troubleshooting.md](Troubleshooting.md)

## Connectivity Strategy

To connect securely, we use SSH Port Forwarding through the Bastion.

### Step 1: Create a Tunnel Session

```bash
oci bastion session create-port-forwarding \
    --bastion-id "ocid1.bastion.oc1.iad.amaaaaaainltkcaaor463mvd7hxxcyqxpsmnhn3ptr5rdh7h5pvqesqekyma" \
    --display-name "Atlas-Tunnel" \
    --ssh-public-key-file "/home/locoxella/.ssh/id_rsa.pub" \
    --target-resource-id "ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq" \
    --target-port 22 \
    --session-ttl 10800
```

### Step 2: Connect via the Tunnel

Once the session is active, get the command via `oci bastion session get`. You will run a command that looks like this:

```bash
ssh -i <private_key> -N -L 2222:10.0.0.160:22 ocid1.bastionsession.oc1.iad...
```

Then, in another terminal, connect to your VM:

```bash
ssh -i <private_key> -p 2222 ubuntu@localhost
```

## Automation / "Hunter" Scripts

Detailed documentation: [scripts/Scripts.md](scripts/Scripts.md).

- **ARM Hunter:** [scripts/arm_hunter.sh](scripts/arm_hunter.sh)
- **AMD Hunter (2):** [scripts/amd_hunter.sh](scripts/amd_hunter.sh)
