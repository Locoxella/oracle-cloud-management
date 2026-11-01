# 🍎 Proyecto: The Seed (Private Git & CI/CD)

Este proyecto establece el "Kilómetro 0" de toda nuestra infraestructura: un servidor Git privado con capacidades de automatización.

## 🛠️ El Stack Elegido: Gitea / Forgejo

He elegido **Gitea** (o su fork **Forgejo**) por las siguientes razones:

1. **Eficiencia:** Está escrito en Go y consume menos de 200MB de RAM. Es perfecto para una VM AMD Micro.
2. **Gitea Actions:** Soporta un sistema de CI/CD compatible con la sintaxis de GitHub Actions.
3. **Todo en uno:** Incluye registro de paquetes, gestión de releases y repositorio de código.
4. **Acceso Seguro:** Uso de **Cloudflare Tunnel** para exponer el servicio vía HTTPS sin abrir puertos públicos en Oracle Cloud.

## 📍 Ubicación y Almacenamiento

- **Host Actual:** `AlwaysFree-Ubuntu-ARM` (ARM - 12GB RAM).
- **Persistencia:** Almacenamiento local en `/opt/stacks/gitea/data`.
- **Base de Datos:** SQLite3 (ligera y estable).
- **Exposición:** Cloudflare Tunnel (`aether-tunnel-arm`) para HTTPS seguro sin puertos públicos.

## 🗺️ Roadmap de "The Seed"

1. [x] **Bootstrap Base:** Docker y dependencias instaladas en ambos nodos.
2. [x] **Containerize:** Desplegar Gitea mediante Docker Compose.
3. [x] **Runner Setup:** Configurar el runner de Gitea Actions (`gitea-runner`) con socket de Docker en el nodo ARM.
4. [x] **Mirroring & CI:** Repositorio sincronizado y pipeline de validación activo en cada push.

## 🔁 El Ciclo de Vida

Una vez "The Seed" esté activo:

1. Yo (el agente) o Tú (el humano) comiteamos código al Gitea privado.
2. Gitea Actions detecta el cambio.
3. El Runner ejecuta el Playbook de Ansible o el código de OpenTofu para aplicar los cambios a la infraestructura de Oracle.
