# 🌌 Oracle Cloud Infrastructure: Management & IaC (Aether)

Este repositorio contiene la infraestructura como código (IaC), los scripts de automatización y la documentación técnica para la gestión del ecosistema **Aether** en Oracle Cloud (Always Free).

## 🚀 Estado Actual del Ecosistema

Actualmente, el proyecto se encuentra en la fase de **Bootstrap**. Hemos establecido el "Kilómetro 0" (The Seed) y estamos expandiendo la infraestructura mediante scripts de "cacería" de recursos gratuitos.

*   **Host Principal:** `Atlas-Node-01` (AMD Micro - Ubuntu)
*   **Servicio Core:** [Gitea (Forgejo)](https://git.solucionesaustral.com) - Nuestro servidor Git privado y CI/CD.
*   **Conectividad:** 
    *   **HTTPS:** Exponiendo servicios mediante un Oracle Load Balancer configurado para Cloudflare.
    *   **Gestión:** Acceso SSH cerrado al público, gestionado exclusivamente vía **OCI Bastion** (`locoxella-bastion`).
*   **Almacenamiento:** Volumen persistente de 50GB (`Atlas-Vault-01`) montado para datos críticos.

## 📁 Estructura del Proyecto

*   `📁 bootstrap/`: Scripts de inicialización de nodos (`setup_node.sh`) y archivos de configuración de servicios (`gitea/`).
*   `📁 memory/`: El "cerebro" del proyecto. Contiene el inventario, el backlog, la guía humana y los roadmaps detallados.
*   `📁 memory/scripts/`: Scripts de automatización, incluyendo los "hunters" de instancias ARM y AMD.

## 🎯 Próximos Pasos (Roadmap)

1.  **Migración de Base de Datos:** Mover el backend de Gitea de SQLite a una **Autonomous Transaction Processing (ATP)** de Oracle.
2.  **Hardening:** Implementar políticas de seguridad avanzadas y rotación de llaves.
3.  **CI/CD con Gitea Actions:** Automatizar el despliegue de este repositorio mediante runners locales.
4.  **Cluster Kubernetes (K3s):** Una vez cazada la instancia ARM (12GB RAM), establecer un cluster de alta disponibilidad.

## 🛠️ Guía Rápida para el Humano

Si eres el usuario humano (`locoxella`), consulta la **[Guía Humana (GUIA_HUMANA.md)](memory/GUIA_HUMANA.md)** para instrucciones sobre cómo re-establecer túneles, gestionar el balanceador y operar los scripts de cacería.

### Conexión Manual a la VM (Terminal Interactiva Segura)
Si quieres conectarte manualmente a la máquina virtual y evadir el problema de MTU de OCI, sigue estos pasos:

1. **Terminal 1: Levantar túnel en el Bastion**
   ```bash
   oci bastion session create-port-forwarding --bastion-id "ocid1.bastion.oc1.iad.amaaaaaainltkcaaor463mvd7hxxcyqxpsmnhn3ptr5rdh7h5pvqesqekyma" --display-name "ConexionManual" --ssh-public-key-file ~/.ssh/id_rsa.pub --target-resource-id "ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq" --target-port 22 --session-ttl 3600
   ```
   *Copia el `id` de sesión (`ocid1.bastionsession...`) que te devuelve el comando y espera 10 segundos a que pase a estado ACTIVE.*

2. **Terminal 1: Mantener el túnel abierto**
   ```bash
   ssh -i ~/.ssh/id_rsa -N -L 2222:10.0.0.160:22 -p 22 <ID_DE_SESION>@host.bastion.us-ashburn-1.oci.oraclecloud.com
   ```
   *El comando se quedará colgado (sin salida de texto). Déjalo corriendo; tu túnel está vivo.*

3. **Terminal 2: Conectarse**
   Abre otra pestaña y ejecuta:
   ```bash
   ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -i ~/.ssh/id_rsa -p 2222 ubuntu@127.0.0.1
   ```

---
*Gestión impulsada por IA. Codename: Aether.*
