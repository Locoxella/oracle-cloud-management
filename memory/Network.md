# Aether Network Topology

This document describes the networking and security structure of the Oracle Cloud environment.

## 1. Virtual Cloud Network (VCN)
- **Name:** `Aether-Network`
- **CIDR:** `10.0.0.0/16`
- **DNS Label:** `locoxella`

## 2. Subnets
- **Public Subnet:** `Aether-Subnet-Public`
  - **CIDR:** `10.0.0.0/24`
  - **Security List:** `Aether-Guard-List`

## 3. Security (Ingress Rules)
The `Aether-Guard-List` (`ocid1.securitylist.oc1.iad.aaaaaaaajdp73kgoav45b7w55px2x4bj2phpwgqmtm3deo3fce67qplju2da`) governs inbound traffic to the subnet:

| Protocol | Source | Port / Type | Purpose |
| :--- | :--- | :--- | :--- |
| **TCP (6)** | `10.0.0.0/16` | 22 | Internal SSH (management exclusively via OCI Bastion) |
| **UDP (17)** | `0.0.0.0/0` | 51820 | WireGuard VPN tunnel ingress |
| **TCP (6)** | `0.0.0.0/0` | 2222 | Gitea Git-over-SSH (filtered at host via dynamic DDNS timer) |
| **TCP (6)** | `0.0.0.0/0` | 80, 443 | Web ingress (HTTP/HTTPS) |
| **TCP (6)** | `10.0.0.0/16` | 3000 | Gitea web interface (internal VCN traffic) |
| **ALL** | `10.0.0.0/16` | All ports | Full internal mesh connectivity between VCN nodes |
| **ICMP (1)** | `0.0.0.0/0` | Type 3, Code 4 | Path MTU Discovery |
| **ICMP (1)** | `10.0.0.0/16` | Type 3 | Internal Error Messaging |

## 4. Connectivity (Bastion)
- **Guardian:** `locoxella-bastion` (internal name: `Aether-Guardian`)
- **Private Endpoint IP:** `10.0.0.2`
- **Usage:** All external management must go through this Bastion. No public IPs are directly accessible via SSH.
