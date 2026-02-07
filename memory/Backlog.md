# 📋 Backlog & Status

Registro de iniciativas y su estado actual.

## 🚀 En Ejecución (In-Progress)

- **[Hunt] Catch ARM Instance:** Pausados tras timeouts. (En espera de re-lanzamiento con monitoreo).
- **[Hunt] Catch 2nd AMD Instance:** Pausados.
- **[Infra] Hardening:** SSH del Balanceador abierto (Puerto 22), acceso a la VM solo vía Bastion.

## 📅 Próximos Pasos (To-Do)

- [ ] **Gitea Actions:** Configurar el primer runner para automatización GitOps (analizar impacto en RAM de la AMD).
- [ ] **Bootstrap:** Crear el primer Playbook de Ansible para configurar `Atlas-Node-01`.
- [x] **Database Connectivity:** Wallet de la `Aether-Seed-DB` descargado y listo en `./secrets/db_wallet`.
- [ ] **Database Migration (Gitea):** Analizar uso de la DB para Gitea (Recordatorio: Gitea no tiene driver nativo para Oracle DB, evaluar si migramos a Postgres en VM o usamos la DB para otros servicios).
- [ ] **Grafana:** Configurar el conector de OCI Monitoring para ver métricas de CPU/RAM.
- [ ] **Kubernetes:** Iniciar el diseño de redes internas para K3s.

## ✅ Completado

- Creación de VCN y Subnets.
- Creación de Bastion.
- Setup de Memoria y documentación en Repo.
- Conexión de Almacenamiento Extra (50GB).
- **[Seed] Gitea Deploy:** Servidor Git activo en `git.solucionesaustral.com`.
- **[Seed] SSH Connectivity:** Acceso Git-over-SSH configurado vía Load Balancer.
- **[Seed] First Push:** El repo principal ya está versionado en la infraestructura propia.
- **[Infra] DB Provisioning:** Autonomous DB `Aether-Seed-DB` creada exitosamente.
- **[Infra] Wallet Management:** Wallet descargado y password generado localmente.
