# 🍎 Proyecto: The Seed (Private Git & CI/CD)

Este proyecto establece el "Kilómetro 0" de toda nuestra infraestructura: un servidor Git privado con capacidades de automatización.

## 🛠️ El Stack Elegido: Gitea / Forgejo

He elegido **Gitea** (o su fork **Forgejo**) por las siguientes razones:

1. **Eficiencia:** Está escrito en Go y consume menos de 200MB de RAM. Es perfecto para una VM AMD Micro.
2. **Gitea Actions:** Soporta un sistema de CI/CD compatible con la sintaxis de GitHub Actions.
3. **Todo en uno:** Incluye registro de paquetes, gestión de releases y repositorio de código.
4. **Acceso Seguro:** Uso de **Cloudflare Tunnel** para exponer el servicio vía HTTPS sin abrir puertos públicos en Oracle Cloud.

## 📍 Ubicación y Almacenamiento

- **Host:** `Atlas-Node-01` (AMD).
- **Persistencia:** Usaremos el volumen `Atlas-Vault-01` (50GB) montado en `/mnt/extra-data` para guardar todos los repositorios y la base de datos de Gitea.
- **Base de Datos:** SQLite3. Es la opción más ligera y estable para Gitea en recursos limitados, y al estar sobre el volumen de 50GB, es muy fácil de respaldar y recuperar.

## 🗺️ Roadmap de "The Seed"

1. [ ] **Bootstrap Local:** Script manual para instalar Docker/Podman en `Atlas-Node-01`.
2. [ ] **Containerize:** Desplegar Gitea mediante Docker Compose.
3. [ ] **Runner Setup:** Configurar el primer Actions Runner (inicialmente en la misma AMD, luego migrarlo a la ARM cuando la tengamos).
4. [ ] **Mirroring:** Configurar que este repo local se espeje automáticamente a Gitea.

## 🔁 El Ciclo de Vida

Una vez "The Seed" esté activo:

1. Yo (el agente) o Tú (el humano) comiteamos código al Gitea privado.
2. Gitea Actions detecta el cambio.
3. El Runner ejecuta el Playbook de Ansible o el código de OpenTofu para aplicar los cambios a la infraestructura de Oracle.
