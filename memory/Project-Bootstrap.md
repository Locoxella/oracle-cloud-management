# 🛠️ Proyecto: Bootstrap & Disaster Recovery

Este proyecto centraliza la automatización necesaria para levantar toda la plataforma desde cero si fuera necesario.

## Herramientas

- **Terraform / OpenTofu:** Para la infraestructura (VCN, Subnets, VMs, DBs).
- **Ansible:** Para la configuración de los sistemas operativos y hardening de seguridad.
- **GitOps (Atlantis):** El motor que ejecutará los cambios de forma automática.

## El Repositorio de Verdad

Todo lo que hagamos manualmente en la consola de Oracle debe ser "importado" a código.

- [ ] **Importar VCN/Subnets:** Crear archivos `.tf` que representen `Aether-Network`.
- [ ] **Importar Seguridad:** Código para `Aether-Guard-List`.
- [ ] **Playbook Inicial:** Crear un script de Ansible que configure el Bastion y los usuarios en cualquier VM nueva.

## Iniciativas Adicionales (Propuestas)

- **Observability Hub:** Un dashboard de **Grafana** (usando el Tier gratuito de 500M de puntos de monitoreo) para ver el estado de salud de los nodos y recibir alertas en Telegram/Email.
- **Backups Inmutables:** Script que haga snapshots de los volúmenes y los guarde en Object Storage como "Archive Store" (muy barato/gratis).
