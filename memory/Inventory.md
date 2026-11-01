# 📊 Inventario de Recursos (Oracle Always Free)

Este documento trackea qué recursos del nivel "Always Free" hemos reclamado y cuáles tenemos aún disponibles (validado empíricamente contra OCI API).

## 1. Cómputo (Máquinas Virtuales)

| Recurso | Utilizado | Total Disponible | Restante |
| :--- | :--- | :--- | :--- |
| **AMD Compute (E2.1.Micro)** | 1 (`Atlas-Node-01`) | 2 Instancias | **1 Instancia** (Libre) |
| **ARM Compute (A1.Flex)** | 1 (`AlwaysFree-Ubuntu-ARM`) | 4 OCPUs / 24 GB RAM | **2 OCPUs / 12 GB RAM** (Libre para ampliar o nueva VM) |

### Detalle de Instancias Activas:
1. **`Atlas-Node-01` (AMD Micro):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq`
   * **IP Privada:** `10.0.0.160` | **IP Pública:** `129.153.185.184`
   * **Specs:** 1 OCPU / 1 GB RAM / 47 GB Boot Volume.
   * **Servicios:** Dockge, WireGuard Easy, Autoheal, Cloudflare Tunnel, Subastas App.
2. **`AlwaysFree-Ubuntu-ARM` (ARM A1.Flex):**
   * **OCID:** `ocid1.instance.oc1.iad.anuwcljsinltkcacrv222dlla7akmfmgkhwspugq6bevmfvevlvkk5ooul5q`
   * **IP Privada:** `10.0.0.200` | **IP Pública:** `129.213.96.28`
   * **Specs:** 2 OCPUs / 12 GB RAM / 47 GB Boot Volume (Creada el 06/10/2026).
   * **Servicios:** Gitea (Forgejo), Gitea Actions Runner, Dockge ARM, Cloudflare Tunnel ARM.

## 2. Almacenamiento (Block & Boot Volumes)

Total Gratuito OCI: **200 GB**

| Volumen | Tamaño | Instancia Asociada | Estado |
| :--- | :--- | :--- | :--- |
| Boot Volume (`Atlas-Node-01`) | 47 GB | `Atlas-Node-01` (AMD) | En uso |
| Boot Volume (`AlwaysFree-Ubuntu-ARM`) | 47 GB | `AlwaysFree-Ubuntu-ARM` (ARM) | En uso |
| `Atlas-Vault-01` (Block Storage) | 50 GB | `Atlas-Node-01` (`/mnt/extra-data`) | En uso |
| **Total Utilizado** | **144 GB** | — | — |
| **Capacidad Restante** | **56 GB** | — | **56 GB libres** (apto para otro disco o expansión) |

## 3. Bases de Datos (Gestionadas)

| Servicio | Capacidad | Estado |
| :--- | :--- | :--- |
| **Autonomous DB** | 2 Instancias (20GB c/u) | **Libre** (la API devuelve 0 Autonomous DB; la `Aether-Seed-DB` documentada antes ya no existe en el compartimento, causa no determinada) |
| **NoSQL Database** | 133M reads/month | **Libre** |

## 4. Red y Otros

| Servicio | Capacidad | Estado | Notas |
| :--- | :--- | :--- | :--- |
| **Load Balancer** | 1 Instancia (10 Mbps) | **Libre** | 0 aprovisionados (todo el tráfico entra vía Cloudflare Tunnels) |
| **Egress Traffic** | 10 TB Mensuales | En uso | Tráfico regular y VPN WireGuard |
| **OCI Bastion** | 1 Instancia (`locoxella-bastion`) | En uso | Acceso SSH seguro a subred `10.0.0.0/16` |
| **Object Storage** | 1 Bucket (`Aether-Infra-State`) | En uso | Namespace `idsbz3qyzayx` |
| **Gitea Backend** | State Storage | En uso | Backend OpenTofu nativo de Gitea |
| **Certificates** | 5 Autoridades / 150 Certs | **Libre** | SSL/TLS delegado a Cloudflare |
