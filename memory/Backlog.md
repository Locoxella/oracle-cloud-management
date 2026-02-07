# 📋 Backlog & Status

Registro de iniciativas y su estado actual.

## 🚀 En Ejecución (In-Progress)

- **[Hunt] Catch ARM Instance:** Los scripts están en pausa tras presentar timeouts nocturnos. Pendiente re-lanzamiento con mejor manejo de errores.
- **[Hunt] Catch 2nd AMD Instance:** Idem anterior.
- **[Infra] Hardening:** SSH del Balanceador abierto (Puerto 22), acceso a la VM solo vía Bastion.

## 📅 Próximos Pasos (To-Do)

- [ ] **Gitea Actions:** Configurar el primer runner para automatización GitOps (analizar impacto en RAM de la AMD).
- [ ] **Bootstrap:** Crear el primer Playbook de Ansible para configurar `Atlas-Node-01`.
- [ ] **Database Connection:** Configurar la conexión desde la VM a la **Aether-Seed-DB** (Autonomous DB).
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
