#!/bin/bash
set -e

BASTION_ID="${BASTION_ID:-ocid1.bastion.oc1.iad.amaaaaaainltkcaaor463mvd7hxxcyqxpsmnhn3ptr5rdh7h5pvqesqekyma}"
INSTANCE_ID="${INSTANCE_ID:-ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq}"
SSH_KEY_PUB="${SSH_KEY_PUB:-$HOME/.ssh/id_rsa.pub}"
SSH_KEY_PRIV="${SSH_KEY_PRIV:-$HOME/.ssh/id_rsa}"
TARGET_IP="${TARGET_IP:-10.0.0.160}"

TUNNEL_PID=""
SESSION_ID=""

cleanup() {
    local exit_code=$?
    trap - EXIT INT TERM
    echo ""
    echo "👋 Cleaning up Bastion session..."
    if [ -n "$TUNNEL_PID" ]; then
        kill "$TUNNEL_PID" 2>/dev/null || true
    fi
    if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
        oci bastion session delete --session-id "$SESSION_ID" --force >/dev/null 2>&1 || true
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

SRC="$1"
DEST="$2"

if [ -z "$SRC" ] || [ -z "$DEST" ]; then
    echo "Usage: $0 <local_file> <remote_destination>"
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

echo "🔗 Creating OCI Bastion port-forwarding session..."
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

echo "📦 Transferring $SRC to ubuntu@127.0.0.1:$DEST..."
scp -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY_PRIV" -P "$LOCAL_PORT" "$SRC" "ubuntu@127.0.0.1:$DEST"

echo "✅ File transfer completed successfully."
exit 0
