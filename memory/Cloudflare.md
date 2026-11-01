# ☁️ Cloudflare & Cloudflare Tunnel (`cloudflared`) Integration

Este documento registra la arquitectura, túneles de alta disponibilidad (HA) y políticas de Zero Trust para el dominio `solucionesaustral.com` (verificado empíricamente contra la API v4 de Cloudflare el 2026-11-01).

## 🏛️ Topología de Túneles y Alta Disponibilidad (HA)

1. **`aether-tunnel` (`557b120e-553b-42f5-bc65-d2ffb9800ea6`):**
   - **Estado:** `HEALTHY` (8 conexiones activas al borde de Cloudflare).
   - **Modo HA en OCI:** Dos réplicas conectadas simultáneamente al mismo túnel dentro de la VCN `10.0.0.0/24`:
     - `aether-tunnel` en `Atlas-Node-01` (AMD `10.0.0.160`) — 4 conexiones.
     - `aether-tunnel-arm` en `AlwaysFree-Ubuntu-ARM` (ARM `10.0.0.200`) — 4 conexiones.
   - Si cualquiera de los contenedores de túnel en OCI se reinicia, el otro nodo enruta el tráfico interno hacia `10.0.0.160` o `10.0.0.200` sin caída de servicio.

2. **`pi-home-tunnel` (`63795e0e-ef77-4758-aa7a-9b75611b5d2c`):**
   - **Estado:** `HEALTHY` (4 conexiones activas al borde).
   - **Nodo Homelab:** `aether-tunnel-pi` ejecutándose en el **Raspberry Pi 4 (`10.0.0.75`)**.

## 🌐 Catálogo de Servicios e Ingress Verificado

| Servicio | Hostname Público | Destino Interno | Túnel / Modo | Seguridad / Acceso |
| :--- | :--- | :--- | :--- | :--- |
| **Gitea Web** | `git.solucionesaustral.com` | `http://10.0.0.200:3000` | `aether-tunnel` | Público (HTTPS Cloudflare) |
| **Gitea SSH** | `git-ssh.solucionesaustral.com` | `129.213.96.28:2222` | DNS / SSH Directo | Llave SSH + Firewall DDNS |
| **Subastas** | `subastas.solucionesaustral.com` | `http://10.0.0.160:8000` | `aether-tunnel` | Público (SPA + API) |
| **Dockge (Principal)** | `dockge.solucionesaustral.com` | `http://10.0.0.160:5001` | `aether-tunnel` | Cloudflare Zero Trust Access |
| **Dockge (AMD)** | `dockge-amd.solucionesaustral.com` | `http://10.0.0.160:5001` | `aether-tunnel` | Cloudflare Zero Trust Access |
| **Dockge (ARM)** | `dockge-arm.solucionesaustral.com` | `http://10.0.0.200:5001` | `aether-tunnel` | Cloudflare Zero Trust Access |
| **Dockge (Pi)** | `dockge-pi.solucionesaustral.com` | `http://localhost:5001` | `pi-home-tunnel` | Cloudflare Zero Trust Access |
| **WireGuard Easy** | `wg.solucionesaustral.com` | `http://10.0.0.160:51821` | `aether-tunnel` | Cloudflare Zero Trust Access |

## 🔑 Autenticación & API Token
- El token local se almacena en `.cloudflare_token` (excluido por `.gitignore`).
- **Account ID:** `2a49278db7ba9207c09be9d2c3e9669a`
- **Zone ID (`solucionesaustral.com`):** `6904c05ddc4a10898d60f7bf50e86938`
