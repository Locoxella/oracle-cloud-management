#!/bin/bash
# ==============================================================================
# Script de sincronización dinámica de Firewall para el puerto SSH de Gitea (2222)
# Permite:
#  1. Subred de la VPN WireGuard (10.8.0.0/24)
#  2. IP dinámica de casa resuelta via DDNS (locoxella2.asuscomm.com)
#  3. Bloquea todo el resto de tráfico entrante a este puerto en el firewall de Linux y Docker.
# ==============================================================================

DDNS_HOST="locoxella2.asuscomm.com"
CHAIN_NAME="GITEA_SSH_FILTER"
PORT=2222

# 1. Crear la cadena si no existe
if ! iptables -L "$CHAIN_NAME" -n 2>/dev/null; then
    iptables -N "$CHAIN_NAME" 2>/dev/null || true
fi

# 2. Asegurar que este enganchada en DOCKER-USER
CONTAINER_IP=$(docker inspect aether-git-seed -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "172.18.0.5")

if ! iptables -C DOCKER-USER -p tcp -d "$CONTAINER_IP" --dport 22 -j "$CHAIN_NAME" 2>/dev/null; then
    iptables -I DOCKER-USER 1 -p tcp -d "$CONTAINER_IP" --dport 22 -j "$CHAIN_NAME"
fi
if ! iptables -C DOCKER-USER -j RETURN 2>/dev/null; then
    iptables -A DOCKER-USER -j RETURN
fi

# 3. Asegurar regla WireGuard
if ! iptables -C "$CHAIN_NAME" -s 10.8.0.0/24 -j ACCEPT 2>/dev/null; then
    iptables -I "$CHAIN_NAME" 1 -s 10.8.0.0/24 -j ACCEPT
fi

# 4. Resolver la IP actual de DDNS
CURRENT_IP=$(python3 -c "import socket; print(socket.gethostbyname('$DDNS_HOST'))" 2>/dev/null || true)

STATE_FILE="/var/run/gitea_ddns_ip.state"
PREV_IP=""
if [ -f "$STATE_FILE" ]; then
    PREV_IP=$(cat "$STATE_FILE")
fi

if [ -n "$CURRENT_IP" ]; then
    if [ "$CURRENT_IP" != "$PREV_IP" ]; then
        echo "[$(date)] DDNS cambió de '$PREV_IP' a '$CURRENT_IP'. Actualizando iptables..."
        if [ -n "$PREV_IP" ]; then
            iptables -D "$CHAIN_NAME" -s "$PREV_IP" -j ACCEPT 2>/dev/null || true
        fi
        iptables -I "$CHAIN_NAME" 1 -s "$CURRENT_IP" -j ACCEPT
        echo "$CURRENT_IP" > "$STATE_FILE"
    fi
else
    echo "[$(date)] Advertencia: No se pudo resolver $DDNS_HOST"
fi

# 5. Asegurar DROP por defecto
if ! iptables -C "$CHAIN_NAME" -j DROP 2>/dev/null; then
    iptables -A "$CHAIN_NAME" -j DROP
fi
