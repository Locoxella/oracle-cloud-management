# 📊 Inventario de Recursos (Oracle Always Free)

Este documento trackea qué recursos del nivel "Always Free" hemos reclamado y cuáles tenemos aún disponibles.

## 1. Cómputo (Máquinas Virtuales)

| Recurso | Utilizado | Total Disponible | Restante |
| :--- | :--- | :--- | :--- |
| **AMD Compute (E2.1.Micro)** | 1 (`Atlas-Node-01`) | 2 Instancias | **1 Instancia** (Cazando...) |
| **ARM Compute (A1.Flex)** | 0 | 4 OCPUs / 24 GB RAM | **4 OCPUs / 24 GB** (Cazando...) |

## 2. Almacenamiento (Block Volumes)

Total Gratuito: **200 GB**

| Volumen | Tamaño | Estado |
| :--- | :--- | :--- |
| Boot Volume (Atlas-Node-01) | ~47 GB | En uso |
| `Atlas-Vault-01` | 50 GB | En uso |
| *Reserva para futuras VMs* | ~94 GB (aprox) | **9 GB restantes** (aprox) |

*Nota: Cada VM necesita un Boot Volume. 2 AMD + 1 ARM consumirán aprox 141 GB en total solo en arranque.*

## 3. Bases de Datos (Gestionadas)

Estos recursos son "serverless" y muy seguros frente a la reclamación de Oracle si tienen tráfico mínimo.

| Servicio | Capacidad | Estado |
| :--- | :--- | :--- |
| **Autonomous DB** | 2 Instancias (20GB c/u) | **Libre** (Plan: Backend de Apps) |
| **NoSQL Database** | 133M reads/month | **Libre** |

## 4. Red y Otros

| Servicio | Capacidad | Estado |
| :--- | :--- | :--- |
| **Load Balancer** | 1 Instancia (10 Mbps) | **Libre** |
| **Egress Traffic** | 10 TB Mensuales | En uso (mínimo) |
| **OCI Bastion** | 1 Instancia (`Aether-Guardian`) | En uso |
| **Certificates** | 5 Autoridades / 150 Certs | **Libre** |
