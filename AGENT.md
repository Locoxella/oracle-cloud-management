# 🤖 Instrucciones para Agentes de IA (AGENT.md)

## 📌 Contexto Fundamental del Proyecto
Este repositorio (`oracle-cloud-management`) administra la infraestructura como código (IaC), configuraciones, despliegues y documentación del ecosistema **Aether** en **Oracle Cloud Infrastructure (OCI - Always Free)**.

### ⚠️ Regla de Interpretación del Entorno
* **Punto de Referencia de Consultas:** Cuando el usuario pregunte por "la VM", "las apps que corren en la VM", "el estado de la VM" o cualquier término similar, **SIEMPRE SE REFIERE A LA MÁQUINA VIRTUAL REMOTA EN ORACLE CLOUD** (nodo `Atlas-Node-01`), **NUNCA** a la máquina local del usuario desde donde opera el agente/IDE.

---

## 🖥️ Infraestructura de la VM Remota (`Atlas-Node-01`)
* **Instancia:** `Atlas-Node-01` (Oracle Cloud - AMD Micro, Ubuntu).
* **Volumen Adicional Montado:** `/mnt/extra-data` (`Atlas-Vault-01`, 50GB).
* **Gestión & Acceso:** Acceso SSH restringido a través de **OCI Bastion** (`Aether-Guardian`).

---

## 📦 Software y Servicios Ejecutándose en la VM Remota

Los servicios están orquestados mediante **Docker Compose** en la VM remota (ver `bootstrap/gitea/docker-compose.yml`):

1. **Gitea (Forgejo):**
   * **Contenedor:** `aether-git-seed`
   * **Propósito:** Servidor privado centralizado de Git y runners de CI/CD (Gitea Actions).
   * **URL:** `https://git.solucionesaustral.com`
   * **Base de Datos:** SQLite local en `/mnt/extra-data/gitea` (Migración planeada a Oracle Autonomous DB).

2. **Cloudflare Tunnel (`cloudflared`):**
   * **Contenedor:** `aether-tunnel`
   * **Propósito:** Expone los servicios HTTP/HTTPS internos de la VM de manera segura hacia internet sin abrir puertos públicos en la VCN de Oracle.

3. **Autoheal:**
   * **Contenedor:** `aether-autoheal`
   * **Propósito:** Monitorea el estado de salud (`healthcheck`) de los contenedores Docker en la VM y los reinicia automáticamente si fallan.

4. **WireGuard Easy (`wg-easy`):**
   * **Contenedor:** `wg-easy`
   * **Propósito:** Servidor VPN ligero con interfaz Web para acceso seguro a la red interna (VCN) de Oracle Cloud.
   * **Puerto UDP:** `51820`

5. **Dockge (`aether-dockge`):**
   * **Contenedor:** `aether-dockge`
   * **Propósito:** Gestor visual e interfaz web para stacks de Docker Compose (`/mnt/extra-data/stacks`).
   * **URL:** `https://dockge.solucionesaustral.com` (protegido con Cloudflare Zero Trust Access).

6. **Firewall Dinámico SSH Gitea (`gitea-firewall-sync`):**
   * **Servicio/Timer:** `gitea-firewall-sync.timer` (systemd cada 5 minutos).
   * **Propósito:** Resuelve la IP dinámica de `locoxella2.asuscomm.com` y permite acceso exclusivo a esta IP y a la subred de la VPN WireGuard (`10.8.0.0/24`) en el puerto SSH 2222, descartando (DROP) cualquier intento de escaneo del resto de internet.

---

## 🛠️ Modus Operandi y Reglas para el Agente
1. Al responder preguntas sobre procesos, puertos, almacenamiento o salud de aplicaciones en la VM, haz referencia a estos servicios orquestados en `Atlas-Node-01`.
2. Para ejecutar comandos o diagnósticos en la VM, utiliza los scripts de conexión/túnel provistos en el proyecto (`connect_vm.sh`, OCI Bastion o Cloudflare Tunnels).
3. **Regla de Disaster Recovery e IaC:** Siempre que se agreguen, modifiquen o creen configuraciones, servicios en segundo plano, scripts o dependencias en la VM en vivo, **SE DEBEN ACTUALIZAR EN PARALELO LOS ARCHIVOS DE DESPLIEGUE Y BOOTSTRAP** (`bootstrap/setup_node.sh`, scripts de inicialización y `infrastructure/`) para garantizar que la VM y todos sus servicios puedan reconstruirse de 0 ante un desastre sin requerir configuración manual adicional.
