# 🔄 Arquitectura GitOps: GitHub + OpenTofu + Ansible (Cloud & Homelab)

Este documento define el diseño y plan de implementación para operar todo el ecosistema **Aether** (Oracle Cloud VMs + Raspberry Pi Homelab + Cloudflare Edge) bajo un modelo **100% GitOps** desde un repositorio público en GitHub (`locoxella/oracle-cloud-management`), manteniendo a Gitea como mirror privado y backup.

---

## 🏛️ 1. Separación de Responsabilidades (Tooling Stack)

| Capa | Herramienta | Alcance |
| :--- | :--- | :--- |
| **Infraestructura Cloud & Edge (IaC)** | **OpenTofu / Terraform** | VCN (`10.0.0.0/16`), Subnets, Security Lists (`Aether-Guard-List`), Instancias OCI (`Atlas-Node-01` AMD y `AlwaysFree-Ubuntu-ARM` ARM), Volúmenes (`Atlas-Vault-01`), OCI Bastion (`locoxella-bastion`), DNS de Cloudflare, Túneles (`aether-tunnel`, `pi-home-tunnel`) y políticas Zero Trust Access. |
| **Configuración de Servidores y Apps (CaC)** | **Ansible** | Provisionamiento de paquetes base, puntos de montaje (`/mnt/extra-data`), swap, reglas `sysctl`/`iptables` (WireGuard NAT), timers de systemd (`gitea-firewall-sync`), despliegue declarativo de stacks Docker Compose y sincronización con el **Raspberry Pi 4 (`10.0.0.75`)**. |
| **Orquestación CI/CD & Validación** | **GitHub Actions** (+ Gitea Mirror) | Linting, escaneo de secretos, **Dry-Runs** (`tofu plan`, `ansible-playbook --check --diff`), aplicación controlada en `main` y **Post-Apply Health Checks** empíricos. |

---

## 🖥️ 2. Inventario Unificado de Nodos (OCI + Homelab HA)

1. **`atlas_arm` (`AlwaysFree-Ubuntu-ARM` — `10.0.0.200`):**
   - **Rol:** Nodo principal de cómputo (2 OCPUs Ampere / 12 GB RAM).
   - **Servicios gestionados por Ansible:** Gitea (`aether-git-seed`), Gitea Actions Runner (`gitea-runner`), Dockge ARM (`aether-dockge`) y réplica HA del túnel Cloudflare (`aether-tunnel-arm`, 4 conexiones al borde).
2. **`atlas_amd` (`Atlas-Node-01` — `10.0.0.160`):**
   - **Rol:** Nodo de red, VPN y servicios web ligeros (1 OCPU AMD / 1 GB RAM + 50 GB `Atlas-Vault-01`).
   - **Servicios gestionados por Ansible:** WireGuard Easy (`wg-easy`), Subastas App (`subastas-app`), Dockge AMD (`aether-dockge`), Autoheal (`aether-autoheal`), timer `gitea-firewall-sync` y réplica HA del túnel Cloudflare (`aether-tunnel`, 4 conexiones al borde).
3. **`raspberry_pi` (`raspberrypi.home` — `10.0.0.75`):**
   - **Rol:** Nodo Homelab local, observabilidad de disponibilidad y borde local (Raspberry Pi 4 8GB SSD).
   - **Servicios y HA con las VMs:**
     - **Túnel Independiente (`pi-home-tunnel` / `aether-tunnel-pi`):** Garantiza acceso de gestión alternativo al homelab (`dockge-pi.solucionesaustral.com`) incluso si OCI tuviera mantenimiento.
     - **Monitoreo Cruzado (`Uptime Kuma :3001` + `Grafana Alloy`):** Monitorea la disponibilidad de los endpoints en las VMs de OCI y envía telemetría a Loki (`10.0.3.0:3100`).
     - **Conectividad VPN (`WireGuard`):** Permite enlazar la LAN local (`10.0.0.0/24` / `10.0.3.0/24`) con la VCN de Oracle Cloud.

---

## 🔐 3. Modelo de Seguridad para Repositorio Público en GitHub

Al ser un repositorio público (vitrina de portafolio profesional), se aplican 4 barreras de seguridad estrictas:

1. **Cero Credenciales en el Código o Historial:**
   - Ningún token, clave privada SSH/OCI, `.env` ni archivo `terraform.tfstate` vive en el repositorio.
   - El estado de OpenTofu se almacena remotamente y cifrado (OCI Object Storage `Aether-Infra-State` vía S3 API o Gitea Terraform Backend) usando variables inyectadas en tiempo de ejecución.
   - En desarrollo local, las credenciales residen en `~/.oci/`, `~/.ssh/` y archivos `.env` / `.cloudflare_token` protegidos por `.gitignore` y verificados automáticamente por el script de pre-flight.
2. **Bloqueo de Ejecución Exclusivo para `locoxella`:**
   - Todos los jobs de despliegue en GitHub Actions incluyen la condición dura:
     `if: github.repository_owner == 'locoxella' && github.actor == 'locoxella'`
   - Los Pull Requests externos (si alguien hace fork) **nunca** reciben acceso a `secrets.*` y solo pueden ejecutar linters estáticos.
3. **GitHub Protected Environment (`production`):**
   - Las credenciales sensibles (`OCI_PRIVATE_KEY`, `CLOUDFLARE_API_TOKEN`, `SSH_PRIVATE_KEY`, `TUNNEL_TOKEN`, etc.) se guardan como **Environment Secrets** dentro del entorno `production` de GitHub, restringido únicamente a la rama `main` y con aprobación de `locoxella`.
4. **Runner Self-Hosted (Recomendado) o Bastion Efímero:**
   - **Opción A (Óptima):** Ejecutar el `actions-runner` de GitHub como contenedor en `AlwaysFree-Ubuntu-ARM` (12 GB RAM) o en el Raspberry Pi (conectado por WireGuard). Así, Ansible se conecta directamente por IP privada (`10.0.0.200`, `10.0.0.160`, `10.0.0.75`) sin abrir puertos SSH en internet ni esperar sesiones de Bastion.
   - **Opción B (GitHub-Hosted):** El runner de GitHub abre un túnel efímero mediante `oci bastion session create-port-forwarding` usando `ProxyCommand` de SSH y lo destruye al finalizar el playbook.

---

## 🧪 4. Pipeline de Cambios: Dry-Run + Apply + Post-Apply Checks

Cada cambio sigue un ciclo verificable de 3 etapas:

1. **Etapa 1 — Validación Estática y Dry-Run (En local y en cada PR / Push):**
   - `scripts/verify_infra.sh`:
     - Escaneo anti-secretos en archivos trackeados por Git.
     - Sintaxis Bash (`bash -n`) y compilación Python (`py_compile`).
     - `tofu fmt -check` y `tofu validate`.
     - Validación de esquemas Docker Compose (`docker compose config`).
     - `ansible-playbook ansible/playbooks/site.yml --syntax-check` y `--check --diff` (simulación sin tocar las VMs).
2. **Etapa 2 — Convergencia / Apply (Solo en `main` por `locoxella`):**
   - `tofu apply -auto-approve` para recursos OCI/Cloudflare.
   - `ansible-playbook ansible/playbooks/site.yml` para sincronizar `/opt/stacks` en ARM, `/mnt/extra-data/stacks` en AMD y servicios en el Raspberry Pi.
3. **Etapa 3 — Post-Apply Empirical Health Check:**
   - `scripts/verify_infra.sh --live` y `ansible-playbook ansible/playbooks/verify.yml`:
     - Verifica que todos los contenedores requeridos estén en estado `running` / `healthy`.
     - Comprueba por HTTP que `git.solucionesaustral.com` y `subastas.solucionesaustral.com` respondan `200 OK`, y que `dockge.solucionesaustral.com` y `wg.solucionesaustral.com` respondan `302 Found` hacia Cloudflare Zero Trust Access.
     - Consulta la API de Cloudflare para confirmar que `aether-tunnel` (8 conexiones HA) y `pi-home-tunnel` (4 conexiones) estén `healthy`.
