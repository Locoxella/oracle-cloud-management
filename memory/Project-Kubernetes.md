# 🎡 Proyecto: Aether-Cluster (K3s Multi-Zonal)

El objetivo es crear un cluster de Kubernetes ligero que se distribuya entre las 3 Availability Domains de US-Ashburn.

## Arquitectura Probable

- **Control Plane (The Brain):** Se instalará en la VM **ARM** (4 cores / 24GB RAM) por su alta capacidad.
- **Worker Nodes:** Las 2 VMs **AMD Micro** actuarán como nodos de trabajo para microservicios livianos.
- **Capa de Red:** Flannel o Calico sobre la VCN `Aether-Network`.
- **Ingress:** Usaremos el **Flexible Load Balancer** gratuito de Oracle para recibir tráfico externo.

## User Stories / Roadmap

1. [ ] **Bootstrap Base:** Configurar OS, firewall y dependencias en todos los nodos.
2. [ ] **Nudo Central:** Desplegar K3s Server en la ARM VM una vez capturada.
3. [ ] **Join Nodes:** Unir `Atlas-Node-01` y el futuro segundo nodo al cluster.
4. [ ] **Storage Class:** Configurar el CSI de Oracle para usar los 200GB de Block Storage como volúmenes dinámicos de K8s.
5. [ ] **Cert-Manager:** Usar el servicio de certificados de Oracle o Let's Encrypt para HTTPS automático.

## Gestión de Carga (Keep-Alive)

Al correr un cluster de K3s con pods reales (como Atlantis, Prometheus, etc.), cumpliremos naturalmente con los requisitos de Oracle de >20% de uso, evitando que nos borren las máquinas.
