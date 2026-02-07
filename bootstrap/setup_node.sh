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

# 4. Estructura de carpetas para Gitea
echo "📂 Creando estructura de carpetas..."
mkdir -p "$MOUNT_POINT/gitea"

echo "✨ Bootstrap completado con éxito."
echo "💡 NOTA: Es posible que necesites cerrar sesión y volver a entrar para que los permisos de Docker surtan efecto."
