# 📋 Backlog & Status

Registro de iniciativas y su estado actual (actualizado empíricamente contra OCI API).

## 🚀 En Ejecución (In-Progress)

- **[Infra] Cluster Kubernetes (K3s):** Diseño de red interna y despliegue del Server K3s en `AlwaysFree-Ubuntu-ARM`.
- **[Infra] Hardening:** Acceso SSH exclusivo vía OCI Bastion (`connect_vm.sh`) y Cloudflare Zero Trust.

## 📅 Próximos Pasos (To-Do)

- [ ] **Database Evaluation:** Evaluar provisionamiento de una nueva DB Always Free (la `Aether-Seed-DB` ya no existe; causa no determinada).
- [ ] **Grafana:** Configurar el conector de OCI Monitoring para ver métricas de CPU/RAM.
- [ ] **Kubernetes:** Desplegar K3s Server en el nodo ARM y unir el nodo AMD como Worker.

## ✅ Completado

- **[Hunt] Catch ARM Instance:** Instancia `AlwaysFree-Ubuntu-ARM` cazada y activa desde 06/10/2026 (2 OCPUs / 12 GB RAM).
- **[CI/CD] Gitea Actions Runner:** Runner `gitea-runner` configurado y operativo en el nodo ARM.
- **[Seed] Gitea Migración a ARM:** Servidor Git migrado a la instancia ARM para aprovechar los 12GB de RAM.
- **[VPN] WireGuard Easy:** Servidor VPN activo en `Atlas-Node-01` con IP de EE.UU.
- **[Security] Bastion Automation:** Script `connect_vm.sh` con selección automática de nodo AMD/ARM y cleanup con traps.
- Creación de VCN y Subnets.
- Creación de Bastion (`locoxella-bastion`).
- Setup de Memoria y documentación en Repo.
- Conexión de Almacenamiento Extra (50GB - `Atlas-Vault-01`).
