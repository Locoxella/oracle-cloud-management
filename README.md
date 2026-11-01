# 🌌 Oracle Cloud Infrastructure: Management & IaC (Aether)

Este repositorio contiene la infraestructura como código (IaC), los scripts de automatización y la documentación técnica para la gestión del ecosistema **Aether** en Oracle Cloud (Always Free).

## 🔄 Sincronización Git

Este repositorio está sincronizado con nuestro servidor privado centralizado de **Gitea**:

- **URL SSH (Remoto Origin):** `git@git-ssh.solucionesaustral.com:locoxella/oracle-cloud-management.git`
- **Servidor Web:** [https://git.solucionesaustral.com/locoxella/oracle-cloud-management](https://git.solucionesaustral.com/locoxella/oracle-cloud-management)

## ⚙️ Gitea Actions (CI/CD)

Las automatizaciones e integraciones continuas nativas de Gitea se gestionan mediante workflows alojados en la carpeta `.gitea/workflows/`:
- `.gitea/workflows/validation.yml`: Pipeline básico de verificación de estructura y pruebas del repositorio que se ejecuta en cada `push` y `pull_request` en la rama `main`.

## 🤖 Prompt de Sincronización para Agentes IA

Si sos un agente de IA que necesita inicializar o clonar este proyecto en tu entorno actual, podés ejecutar el siguiente comando:

```bash
git clone git@git-ssh.solucionesaustral.com:locoxella/oracle-cloud-management.git .
```

---

## 🚀 Estado Actual del Ecosistema

Actualmente, el proyecto cuenta con dos nodos activos en Oracle Cloud (Always Free):

*   **Nodo de Cómputo Principal (ARM):** `AlwaysFree-Ubuntu-ARM` (2 OCPUs Ampere Altra / 12 GB RAM / IP `10.0.0.200`)
    *   **Servicio Core:** [Gitea (Forgejo)](https://git.solucionesaustral.com) - Servidor Git privado y registro de paquetes.
    *   **CI/CD:** Runner local activo de Gitea Actions (`gitea-runner`).
    *   **Túnel:** `aether-tunnel-arm` (Cloudflare Tunnel dedicado).
*   **Nodo Secundario de Gestión & VPN (AMD):** `Atlas-Node-01` (1 OCPU AMD / 1 GB RAM / IP `10.0.0.160`)
    *   **VPN:** WireGuard Easy (`wg-easy`) para acceso a red interna y túnel completo con IP de EE.UU.
    *   **Gestión:** Dockge (`dockge.solucionesaustral.com` protegido por Cloudflare Zero Trust) y Autoheal.
    *   **Almacenamiento Persistente:** Volumen en bloque de 50GB (`Atlas-Vault-01`) montado en `/mnt/extra-data`.
*   **Conectividad & Seguridad:**
    *   **HTTPS:** Exposición cifrada de punta a punta mediante Cloudflare Tunnels (sin abrir puertos públicos en la VCN).
    *   **Gestión SSH:** Acceso cerrado al público, operado exclusivamente mediante **OCI Bastion** (`locoxella-bastion`).

## 📁 Estructura del Proyecto

```
oracle-cloud-management/
├── .github/workflows/
│   └── gitops.yml               # Pipeline GitOps para GitHub Actions (Dry-Run + Owner Guard + Post-Apply)
├── .gitea/workflows/
│   └── validation.yml           # Pipeline espejo para Gitea Actions
├── ansible/                     # Configuración como Código (CaC) para ARM, AMD y Raspberry Pi
│   ├── ansible.cfg
│   ├── inventory/hosts.yml      # Inventario unificado (OCI VMs + Homelab Raspberry Pi)
│   └── playbooks/               # Playbooks de convergencia (site.yml) y verificación (verify.yml)
├── archive/hunters/             # Scripts históricos de cacería de capacidad Always Free (archivados)
├── bootstrap/                   # Inicialización y stacks modulares de Docker Compose
│   ├── infrastructure/          # Stacks base de gestión (Dockge, Autoheal)
│   └── stacks/                  # Stacks de servicios (git, network, subastas)
├── infrastructure/              # Infraestructura como código con OpenTofu / Terraform
├── memory/                      # Inventarios, topología HA, plan GitOps y guías operativas
├── scripts/                     # Suite de verificación (verify_infra.sh) y utilidades de Cloudflare
├── connect_vm.sh                # Acceso interactivo SSH seguro vía OCI Bastion
└── scp_to_vm.sh                 # Copia de archivos remota a través del Bastion
```

## 🎯 Próximos Pasos (Roadmap)

1.  **Cluster Kubernetes (K3s):** Desplegar el servidor K3s en `AlwaysFree-Ubuntu-ARM` (12 GB RAM) y unir `Atlas-Node-01` como worker node.
2.  **Hardening & GitOps:** Fortalecer pipelines en Gitea Actions con OpenTofu para automatizar cambios de infraestructura en cada Pull Request.
3.  **Monitoreo Unificado:** Configurar conector OCI Monitoring / Prometheus para métricas de ambos nodos.

## 🛠️ Guía Rápida para el Humano

Para conectarte a cualquiera de las máquinas virtuales de forma inmediata (sin lidiar con configuraciones manuales de Bastion):

```bash
# Conectar al nodo AMD (Atlas-Node-01)
./connect_vm.sh

# Conectar al nodo ARM (AlwaysFree-Ubuntu-ARM)
./connect_vm.sh arm

# Ejecutar un comando remoto directamente
./connect_vm.sh "docker ps"
./connect_vm.sh arm "docker ps"
```

Para más detalles operativos o resolución de problemas, consulta la **[Guía Humana (GUIA_HUMANA.md)](memory/GUIA_HUMANA.md)**.

---
*Gestión impulsada por IA. Codename: Aether.*

