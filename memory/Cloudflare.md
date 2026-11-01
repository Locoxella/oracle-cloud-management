# ☁️ Cloudflare & Cloudflare Tunnel (`cloudflared`) Integration

This document specifies the architecture, High Availability (HA) tunnels, and Zero Trust access policies for `solucionesaustral.com` (empirically reconciled against Cloudflare API v4).

---

## 🏛️ Tunnel Topology & High Availability (HA)

1. **`aether-tunnel` (`557b120e-553b-42f5-bc65-d2ffb9800ea6`):**
   - **Status:** `HEALTHY` (8 active edge connections).
   - **Active-Active HA Mode in OCI:** Two instances running concurrently within the `10.0.0.0/24` subnet:
     - `aether-tunnel` on `Atlas-Node-01` (AMD `10.0.0.160`) — 4 edge connections.
     - `aether-tunnel-arm` on `AlwaysFree-Ubuntu-ARM` (ARM `10.0.0.200`) — 4 edge connections.
   - If either host or container restarts, the surviving replica routes internal VCN traffic to either `10.0.0.160` or `10.0.0.200` without downtime.

2. **`pi-home-tunnel` (`63795e0e-ef77-4758-aa7a-9b75611b5d2c`):**
   - **Status:** `HEALTHY` (4 active edge connections).
   - **Homelab Node:** `aether-tunnel-pi` running on **Raspberry Pi 4 (`10.0.0.75`)**.

---

## 🌐 Ingress Route Catalog & Verified Endpoints

| Service | Public Hostname | Internal Destination | Ingress Tunnel | Access & Security Model |
| :--- | :--- | :--- | :--- | :--- |
| **Gitea Web** | `git.solucionesaustral.com` | `http://10.0.0.200:3000` | `aether-tunnel` | Public Cloudflare Edge (HTTPS) |
| **Gitea SSH** | `git-ssh.solucionesaustral.com` | `129.213.96.28:2222` | Direct DNS / Port 2222 | SSH Key + Dynamic Firewall Timer |
| **Subastas Web** | `subastas.solucionesaustral.com` | `http://10.0.0.160:8000` | `aether-tunnel` | Public Cloudflare Edge (SPA + API) |
| **Dockge Manager** | `dockge.solucionesaustral.com` | `http://10.0.0.160:5001` | `aether-tunnel` | Zero Trust Access (Google IdP) |
| **Dockge AMD** | `dockge-amd.solucionesaustral.com` | `http://10.0.0.160:5001` | `aether-tunnel` | Zero Trust Access (Google IdP) |
| **Dockge ARM** | `dockge-arm.solucionesaustral.com` | `http://10.0.0.200:5001` | `aether-tunnel` | Zero Trust Access (Google IdP) |
| **Dockge Pi** | `dockge-pi.solucionesaustral.com` | `http://localhost:5001` | `pi-home-tunnel` | Zero Trust Access (`pi-home-tunnel`) |
| **WireGuard Easy** | `wg.solucionesaustral.com` | `http://10.0.0.160:51821` | `aether-tunnel` | Zero Trust Access (Google IdP) |

---

## 🔑 Authentication & API References

- Local secret token is stored in `.cloudflare_token` (ignored by `.gitignore`).
- **Account ID:** `2a49278db7ba9207c09be9d2c3e9669a`
- **Zone ID (`solucionesaustral.com`):** `6904c05ddc4a10898d60f7bf50e86938`
