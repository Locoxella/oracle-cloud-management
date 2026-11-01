# 🎡 Project: Aether-Cluster (K3s Multi-Zonal)

The goal of this initiative is to deploy a lightweight Kubernetes (K3s) cluster distributed across availability domains in US-Ashburn.

## Target Architecture

- **Control Plane:** Hosted on `AlwaysFree-Ubuntu-ARM` (2 cores Ampere / 12 GB RAM) leveraging high compute and memory capacity.
- **Worker Nodes:** AMD nodes (`Atlas-Node-01`) serving as lightweight worker nodes.
- **Overlay Network:** Flannel or Calico running over the `Aether-Network` VCN (`10.0.0.0/16`).
- **Ingress Strategy:** Cloudflare Tunnels (or Oracle Always Free Flexible Load Balancer) for zero-trust external traffic routing.

## Milestones & Roadmap

1. [ ] **Prerequisites:** Validate kernel parameters, cgroups, and firewall rules on all nodes.
2. [ ] **Control Plane Deployment:** Initialize K3s server on the ARM node using systemd.
3. [ ] **Worker Join:** Join `Atlas-Node-01` to the cluster via internal VCN IP (`10.0.0.160`).
4. [ ] **Storage Class Integration:** Configure OCI CSI driver to leverage block storage for dynamic volume provisioning.
5. [ ] **Ingress Controller & Certs:** Route ingress via Cloudflare Tunnel edge endpoints.
