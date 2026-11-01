# 🤖 Instrucciones para Agentes de IA (AGENT.md)

## 📌 Contexto Fundamental del Proyecto
Este repositorio (`oracle-cloud-management`) administra la infraestructura como código (IaC), configuraciones, despliegues y documentación del ecosistema **Aether** en **Oracle Cloud Infrastructure (OCI - Always Free)**.

### ⚠️ Regla de Interpretación del Entorno
* **Punto de Referencia de Consultas:** Cuando el usuario pregunte por "la VM", "las apps que corren en la VM", "el estado de la VM" o cualquier término similar, **SE REFIERE A LAS MÁQUINAS VIRTUALES REMOTAS EN ORACLE CLOUD** (`Atlas-Node-01` AMD o `AlwaysFree-Ubuntu-ARM` ARM), **NUNCA** a la máquina local del usuario desde donde opera el agente/IDE.

---

## 🖥️ Topología de Nodos Remotos

El ecosistema cuenta con **dos instancias activas** en OCI:

1. **`Atlas-Node-01` (AMD Micro - Ubuntu):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq`
   * **IP Privada:** `10.0.0.160` | **IP Pública:** `129.153.185.184`
   * **Especificaciones:** 1 OCPU AMD EPYC / 1 GB RAM / 47 GB Boot Volume.
   * **Volumen Persistente Adicional:** `/mnt/extra-data` (`Atlas-Vault-01`, 50GB).
   * **Conexión Bastion:** `./connect_vm.sh amd` (o `./connect_vm.sh`).

2. **`AlwaysFree-Ubuntu-ARM` (ARM A1.Flex - Ubuntu):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljsinltkcacrv222dlla7akmfmgkhwspugq6bevmfvevlvkk5ooul5q`
   * **IP Privada:** `10.0.0.200` | **IP Pública:** `129.213.96.28`
   * **Especificaciones:** 2 OCPUs Ampere Altra / 12 GB RAM / 47 GB Boot Volume.
   * **Almacenamiento Local:** solo boot volume (`/dev/sda1`, 45GB útiles); sin volumen adicional.
   * **Layout de stacks:** `/opt/stacks/{gitea,git-runner,management,network}` (verificado por SSH).
   * **Conexión Bastion:** `./connect_vm.sh arm`.

---

## 📦 Software y Servicios Ejecutándose por Nodo

### En Nodo ARM (`AlwaysFree-Ubuntu-ARM` - 10.0.0.200):
1. **Gitea (Forgejo):**
   * **Contenedor:** `aether-git-seed`
   * **Propósito:** Servidor privado centralizado de Git y gestor de repositorios.
   * **Puertos:** HTTP `3000`, SSH `2222`.
   * **Base de datos:** SQLite3 (verificado). Almacenamiento: `/opt/stacks/gitea/data` (340 MB, 8 repositorios activos).
   * **Sincronización IaC:** Alineado en `bootstrap/stacks/git/compose.yaml`; los restos obsoletos en `/mnt/extra-data/gitea` del nodo AMD fueron eliminados tras verificar la migración.
   * **URL:** `https://git.solucionesaustral.com`
2. **Gitea Actions Runner:**
   * **Contenedor:** `gitea-runner`
   * **Propósito:** Runner de CI/CD nativo de Gitea Actions conectado a Docker.
3. **Cloudflare Tunnel ARM:**
   * **Contenedor:** `aether-tunnel-arm`
   * **Propósito:** Expone Gitea HTTP/SSH de forma segura hacia Cloudflare sin abrir puertos entrantes.
4. **Dockge (ARM):**
   * **Contenedor:** `aether-dockge` (Puerto `5001`).
   * **Propósito:** Gestor visual de compose stacks en el nodo ARM (`/opt/stacks`, datos en `/opt/stacks/management/dockge-data`). No hay `autoheal` en este nodo.

### En Nodo AMD (`Atlas-Node-01` - 10.0.0.160):
1. **WireGuard Easy (`wg-easy`):**
   * **Contenedor:** `wg-easy`
   * **Propósito:** Servidor VPN: acceso seguro a la subred interna `10.0.0.0/16` y salida a internet.
   * **Puerto UDP:** `51820` (abierto en Security List e iptables).
2. **Dockge (AMD):**
   * **Contenedor:** `aether-dockge` (Puerto `5001`, URL: `https://dockge.solucionesaustral.com` protegida por Cloudflare Access).
   * **Stacks:** Gestiona `/mnt/extra-data/stacks` e infraestructura base en `/mnt/extra-data/infrastructure`.
3. **Cloudflare Tunnel AMD:**
   * **Contenedor:** `aether-tunnel`
4. **Autoheal:**
   * **Contenedor:** `aether-autoheal` (Reinicia contenedores no saludables).
5. **Subastas App:**
   * **Contenedor:** `subastas-app` (Puerto `8000`).
6. **Firewall Dinámico SSH Gitea:**
   * **Servicio:** `gitea-firewall-sync.timer` (Sincroniza IP dinámica DDNS para filtrado de SSH).

---

## 🛠️ Modus Operandi y Reglas para el Agente
1. Al responder preguntas sobre procesos, puertos, almacenamiento o salud de aplicaciones en la VM, haz referencia a estos servicios orquestados en `Atlas-Node-01`.
2. Para ejecutar comandos o diagnósticos en la VM, utiliza los scripts de conexión/túnel provistos en el proyecto (`connect_vm.sh`, OCI Bastion o Cloudflare Tunnels).
3. **Regla de Disaster Recovery e IaC:** Siempre que se agreguen, modifiquen o creen configuraciones, servicios en segundo plano, scripts o dependencias en la VM en vivo, **SE DEBEN ACTUALIZAR EN PARALELO LOS ARCHIVOS DE DESPLIEGUE Y BOOTSTRAP** (`bootstrap/setup_node.sh`, scripts de inicialización y `infrastructure/`) para garantizar que la VM y todos sus servicios puedan reconstruirse de 0 ante un desastre sin requerir configuración manual adicional.
