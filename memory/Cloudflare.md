# ☁️ Cloudflare & Cloudflare Tunnel (`cloudflared`) Integration

Este documento registra la configuración, autenticación y gestión del CLI de Cloudflare (`cloudflared`) en el proyecto Aether.

## 🛠️ Instalación de `cloudflared`
- **Ubicación del ejecutable:** `/home/locoxella/.local/bin/cloudflared` (en el `$PATH` del sistema)
- **Versión:** `2026.7.3`
- **Fuente original RPM:** `/home/locoxella/Downloads/cloudflared-linux-x86_64.rpm`

## 🔑 Autenticación & API Token
- El token de API de Cloudflare se encuentra en [.cloudflare_token](file:///home/locoxella/repos/oracle-cloud-management/.cloudflare_token).
- **Zona activa:** `solucionesaustral.com` (Zone ID: `6904c05ddc4a10898d60f7bf50e86938`)

## 🌐 Configuración de Servicios
- **`git.solucionesaustral.com`**:
  - Tipo: `A` record -> `129.80.43.192` (Oracle Load Balancer)
  - Estado: **Proxied (Nube Naranja 🟧)**
  - SSL/TLS: Gestionado automáticamente por Cloudflare (Google Trust Services).

## 🚀 Comandos Útiles con `cloudflared`

### Ver versión e información
```bash
cloudflared --version
```

### Autenticar con cuenta de Cloudflare
```bash
cloudflared tunnel login
```

### Crear un nuevo Túnel de Cloudflare
```bash
cloudflared tunnel create <tunnel-name>
```

### Ejecutar un túnel mapeado a un servicio local
```bash
cloudflared tunnel run --url http://localhost:3000 <tunnel-name>
```
