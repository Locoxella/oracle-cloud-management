#!/bin/bash
set -e

BASTION_ID="ocid1.bastion.oc1.iad.amaaaaaainltkcaaor463mvd7hxxcyqxpsmnhn3ptr5rdh7h5pvqesqekyma"
INSTANCE_ID="ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq"
SSH_KEY_PUB="/home/locoxella/.ssh/id_rsa.pub"
SSH_KEY_PRIV="/home/locoxella/.ssh/id_rsa"
TARGET_IP="10.0.0.160"

SRC="$1"
DEST="$2"

if [ -z "$SRC" ] || [ -z "$DEST" ]; then
    echo "Uso: $0 <archivo_local> <destino_remoto>"
    exit 1
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

LOCAL_PORT=$(get_free_port)

echo "🔗 Creando sesión Bastion..."
SESSION_JSON=$(oci bastion session create-port-forwarding \
    --bastion-id "$BASTION_ID" \
    --display-name "PortFwd_SCP_$(date +%s)" \
    --ssh-public-key-file "$SSH_KEY_PUB" \
    --target-resource-id "$INSTANCE_ID" \
    --target-port 22 \
    --session-ttl 3600)

SESSION_ID=$(echo "$SESSION_JSON" | jq -r '.data.id')

while true; do
    STATE=$(oci bastion session get --session-id "$SESSION_ID" | jq -r '.data."lifecycle-state"')
    if [ "$STATE" == "ACTIVE" ]; then
        break
    fi
    sleep 2
done
sleep 8

ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY_PRIV" -N -L "$LOCAL_PORT:$TARGET_IP:22" -p 22 "$SESSION_ID@host.bastion.us-ashburn-1.oci.oraclecloud.com" &
TUNNEL_PID=$!
sleep 3

echo "📦 Copiando $SRC a ubuntu@127.0.0.1:$DEST..."
scp -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY_PRIV" -P "$LOCAL_PORT" "$SRC" "ubuntu@127.0.0.1:$DEST"

echo "👋 Limpiando..."
kill $TUNNEL_PID 2>/dev/null || true
oci bastion session delete --session-id "$SESSION_ID" --force >/dev/null 2>&1
echo "✅ Copia finalizada con éxito."
