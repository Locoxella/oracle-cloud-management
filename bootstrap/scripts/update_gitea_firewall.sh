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
if ! iptables -N "$CHAIN_NAME" 2>/dev/null; then
    # Insertar en DOCKER-USER (para reglas que van hacia contenedores Docker)
    if iptables -L DOCKER-USER -n 2>/dev/null; then
        iptables -I DOCKER-USER 1 -p tcp --dport "$PORT" -j "$CHAIN_NAME"
    fi
    # Insertar en INPUT (para conexiones al host)
    iptables -I INPUT 1 -p tcp --dport "$PORT" -j "$CHAIN_NAME"
fi

# 2. Asegurar que la cadena siempre tenga la regla para WireGuard (10.8.0.0/24)
if ! iptables -C "$CHAIN_NAME" -s 10.8.0.0/24 -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
    iptables -I "$CHAIN_NAME" 1 -s 10.8.0.0/24 -p tcp --dport "$PORT" -j ACCEPT
fi

# 3. Resolver la IP actual de DDNS
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
            iptables -D "$CHAIN_NAME" -s "$PREV_IP" -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null || true
        fi
        iptables -I "$CHAIN_NAME" 1 -s "$CURRENT_IP" -p tcp --dport "$PORT" -j ACCEPT
        echo "$CURRENT_IP" > "$STATE_FILE"
    fi
else
    echo "[$(date)] Advertencia: No se pudo resolver $DDNS_HOST"
fi

# 4. Asegurar que la regla por defecto en la cadena sea DROP
if ! iptables -C "$CHAIN_NAME" -p tcp --dport "$PORT" -j DROP 2>/dev/null; then
    iptables -A "$CHAIN_NAME" -p tcp --dport "$PORT" -j DROP
fi
