#!/bin/bash

# Aether Node Bootstrap Script
# Este script prepara una VM de Oracle para ser parte del ecosistema Aether.

set -e

echo "🚀 Iniciando Bootstrap en $(hostname)..."

# 1. Actualización de paquetes
echo "📦 Actualizando sistema..."
sudo apt-get update && sudo apt-get upgrade -y

# 2. Instalación de Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado."
else
    echo "✅ Docker ya está instalado."
fi

# 3. Preparación del almacenamiento extra (/dev/sdb)
echo "💾 Configurando disco extra..."
DEVICE="/dev/sdb"
MOUNT_POINT="/mnt/extra-data"

if [ -b "$DEVICE" ]; then
    # Solo formatear si no tiene sistema de archivos
    if ! sudo blkid "$DEVICE" > /dev/null; then
        echo "🔨 Formateando $DEVICE con ext4..."
        sudo mkfs.ext4 "$DEVICE"
    fi

    # Crear punto de montaje y montar
    sudo mkdir -p "$MOUNT_POINT"
    if ! mount | grep -q "$MOUNT_POINT"; then
        echo "🔗 Montando disco en $MOUNT_POINT..."
        sudo mount "$DEVICE" "$MOUNT_POINT"
        # Persistencia en fstab
        UUID=$(sudo blkid -s UUID -o value "$DEVICE")
        if ! grep -q "$UUID" /etc/fstab; then
            echo "UUID=$UUID $MOUNT_POINT ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab
        fi
    fi
    sudo chown -R $USER:$USER "$MOUNT_POINT"
    echo "✅ Almacenamiento configurado en $MOUNT_POINT."
else
    echo "⚠️ ADVERTENCIA: No se encontró el dispositivo $DEVICE. Saltando configuración de disco."
fi

# 4. Estructura de carpetas para Stacks y Red Docker compartida
echo "📂 Creando estructura de carpetas para Stacks y Dockge..."
mkdir -p "$MOUNT_POINT/gitea"
mkdir -p "$MOUNT_POINT/dockge/data"
mkdir -p "$MOUNT_POINT/stacks/management"
mkdir -p "$MOUNT_POINT/stacks/network"
mkdir -p "$MOUNT_POINT/stacks/git"
mkdir -p "$MOUNT_POINT/stacks/subastas"

# Crear red Docker compartida externa
sudo docker network create aether-net 2>/dev/null || true

# 5. Configurar Sincronización Dinámica de Firewall para Gitea SSH (DDNS + WireGuard)
echo "🛡️ Configurando sincronización dinámica de Firewall para Gitea SSH..."
sudo cp "$(dirname "$0")/scripts/update_gitea_firewall.sh" /usr/local/bin/update_gitea_firewall.sh
sudo chmod +x /usr/local/bin/update_gitea_firewall.sh

cat << 'EOF' | sudo tee /etc/systemd/system/gitea-firewall-sync.service
[Unit]
Description=Sync Gitea SSH Firewall with DDNS & WireGuard
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update_gitea_firewall.sh

[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' | sudo tee /etc/systemd/system/gitea-firewall-sync.timer
[Unit]
Description=Run Gitea SSH Firewall sync every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now gitea-firewall-sync.timer
sudo /usr/local/bin/update_gitea_firewall.sh || true

echo "✨ Bootstrap completado con éxito."
echo "💡 NOTA: Es posible que necesites cerrar sesión y volver a entrar para que los permisos de Docker surtan efecto."
