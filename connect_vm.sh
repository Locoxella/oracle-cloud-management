#!/bin/bash
set -e

# Configuración Bastion
BASTION_ID="${BASTION_ID:-ocid1.bastion.oc1.iad.amaaaaaainltkcaaor463mvd7hxxcyqxpsmnhn3ptr5rdh7h5pvqesqekyma}"
SSH_KEY_PUB="${SSH_KEY_PUB:-$HOME/.ssh/id_rsa.pub}"
SSH_KEY_PRIV="${SSH_KEY_PRIV:-$HOME/.ssh/id_rsa}"

TUNNEL_PID=""
SESSION_ID=""

cleanup() {
    local exit_code=$?
    trap - EXIT INT TERM
    echo ""
    echo "👋 Limpiando recursos de la sesión..."
    if [ -n "$TUNNEL_PID" ]; then
        kill "$TUNNEL_PID" 2>/dev/null || true
    fi
    if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
        oci bastion session delete --session-id "$SESSION_ID" --force >/dev/null 2>&1 || true
    fi
    echo "✅ Recursos liberados."
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# Instancias conocidas
AMD_ID="ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq"
AMD_IP="10.0.0.160"
ARM_ID="ocid1.instance.oc1.iad.anuwcljsinltkcacrv222dlla7akmfmgkhwspugq6bevmfvevlvkk5ooul5q"
ARM_IP="10.0.0.200"

# Target por defecto o argumento
TARGET_NODE="amd"
if [ "$1" == "arm" ] || [ "$1" == "ARM" ]; then
    TARGET_NODE="arm"
    shift
elif [ "$1" == "amd" ] || [ "$1" == "AMD" ]; then
    TARGET_NODE="amd"
    shift
fi

if [ "$TARGET_NODE" == "arm" ]; then
    INSTANCE_ID="$ARM_ID"
    TARGET_IP="$ARM_IP"
    NODE_NAME="AlwaysFree-Ubuntu-ARM"
else
    INSTANCE_ID="$AMD_ID"
    TARGET_IP="$AMD_IP"
    NODE_NAME="Atlas-Node-01 (AMD)"
fi

function get_free_port() {
    while true; do
        PORT=$((RANDOM % 40000 + 10240))
        if ! lsof -i:$PORT >/dev/null 2>&1; then
            echo $PORT
            return
        fi
    done
}

function disconnect() {
    echo "🔌 Desconectando y limpiando sesiones activas generadas por este script..."
    SESSIONS=$(oci bastion session list --bastion-id "$BASTION_ID" --session-lifecycle-state ACTIVE --all | jq -r '.data[] | select(."display-name" | startswith("PortFwd_")) | .id')
    for SESSION in $SESSIONS; do
        echo "🗑️ Borrando sesión: $SESSION"
        oci bastion session delete --session-id "$SESSION" --force
    done
    echo "✅ Limpieza de sesiones finalizada."
    exit 0
}

if [ "$1" == "disconnect" ]; then
    disconnect
fi

LOCAL_PORT=$(get_free_port)

echo "================================================="
echo "🔗 Iniciando conexión a $NODE_NAME ($TARGET_IP)"
echo "================================================="

echo "[1/4] Creando sesión de Port Forwarding en OCI Bastion..."
SESSION_JSON=$(oci bastion session create-port-forwarding \
    --bastion-id "$BASTION_ID" \
    --display-name "PortFwd_$(date +%s)" \
    --ssh-public-key-file "$SSH_KEY_PUB" \
    --target-resource-id "$INSTANCE_ID" \
    --target-port 22 \
    --session-ttl 3600)

SESSION_ID=$(echo "$SESSION_JSON" | jq -r '.data.id')

if [ -z "$SESSION_ID" ] || [ "$SESSION_ID" == "null" ]; then
    echo "❌ Error: Falló la creación de la sesión en el Bastion de OCI."
    exit 1
fi
echo "✅ Sesión creada. ID: $SESSION_ID"

echo "[2/4] Esperando a que la sesión esté ACTIVE..."
while true; do
    STATE=$(oci bastion session get --session-id "$SESSION_ID" | jq -r '.data."lifecycle-state"')
    if [ "$STATE" == "ACTIVE" ]; then
        break
    elif [ "$STATE" == "FAILED" ]; then
        echo "❌ La sesión falló al crearse."
        exit 1
    fi
    sleep 3
done
echo "✅ Sesión lista. Esperando 10s para propagación de llave..."
sleep 10

echo "[3/4] Levantando túnel local en segundo plano (puerto aleatorio $LOCAL_PORT)..."
ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY_PRIV" -N -L "$LOCAL_PORT:$TARGET_IP:22" -p 22 "$SESSION_ID@host.bastion.us-ashburn-1.oci.oraclecloud.com" &
TUNNEL_PID=$!

sleep 3

echo "[4/4] Conectando por SSH a través del túnel local..."

if [ $# -eq 0 ]; then
    ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY_PRIV" -p "$LOCAL_PORT" ubuntu@127.0.0.1 || true
else
    ssh -n -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i "$SSH_KEY_PRIV" -p "$LOCAL_PORT" ubuntu@127.0.0.1 "$@" || true
fi

echo "👋 Sesión SSH finalizada."
exit 0
