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
The `Aether-Guard-List` is configured for maximum security by closing public access to critical ports:

| Protocol | Source | Port | Purpose |
| :--- | :--- | :--- | :--- |
| TCP (6) | `10.0.0.0/16` | 22 | Internal SSH (via Bastion) |
| ICMP (1) | `0.0.0.0/0` | Type 3, Code 4 | Path MTU Discovery |
| ICMP (1) | `10.0.0.0/16` | Type 3 | Internal Error Messaging |

## 4. Connectivity (Bastion)
- **Guardian:** `locoxella-bastion` (internal name: `Aether-Guardian`)
- **Private Endpoint IP:** `10.0.0.2`
- **Usage:** All external management must go through this Bastion. No public IPs are directly accessible via SSH.
