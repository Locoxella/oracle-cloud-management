#!/usr/bin/env bash
# ==============================================================================
# Run Ansible playbooks via Ephemeral OCI Bastion Port-Forwarding
# Creates temporary port-forwarding sessions, opens local SSH tunnels, runs
# Ansible against localhost:port, and automatically tears down tunnels and
# Bastion sessions on completion (or on interruption via trap).
#
# Usage:
#   ./scripts/run_ansible_via_bastion.sh ansible/playbooks/verify.yml
#   ./scripts/run_ansible_via_bastion.sh ansible/playbooks/site.yml --check --diff
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BASTION_ID="${BASTION_ID:-ocid1.bastion.oc1.iad.amaaaaaainltkcaaor463mvd7hxxcyqxpsmnhn3ptr5rdh7h5pvqesqekyma}"
AMD_ID="${AMD_ID:-ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq}"
ARM_ID="${ARM_ID:-ocid1.instance.oc1.iad.anuwcljsinltkcacrv222dlla7akmfmgkhwspugq6bevmfvevlvkk5ooul5q}"
SSH_KEY_PUB="${SSH_KEY_PUB:-$HOME/.ssh/id_rsa.pub}"
SSH_KEY_PRIV="${SSH_KEY_PRIV:-$HOME/.ssh/id_rsa}"

if [[ ! -f "$SSH_KEY_PUB" && -f "$SSH_KEY_PRIV" ]]; then
    mkdir -p "$(dirname "$SSH_KEY_PUB")"
    ssh-keygen -y -f "$SSH_KEY_PRIV" > "$SSH_KEY_PUB"
fi

TUNNEL_AMD_PID=""
TUNNEL_ARM_PID=""
SESSION_AMD_ID=""
SESSION_ARM_ID=""

cleanup() {
    local exit_code=$?
    trap - EXIT INT TERM
    echo ""
    echo "👋 Cleaning up ephemeral Bastion sessions and SSH tunnels..."
    if [[ -n "$TUNNEL_AMD_PID" ]]; then
        kill "$TUNNEL_AMD_PID" 2>/dev/null || true
    fi
    if [[ -n "$TUNNEL_ARM_PID" ]]; then
        kill "$TUNNEL_ARM_PID" 2>/dev/null || true
    fi
    if [[ -n "$SESSION_AMD_ID" && "$SESSION_AMD_ID" != "null" ]]; then
        echo "  🗑️ Deleting AMD Bastion session: $SESSION_AMD_ID"
        oci bastion session delete --session-id "$SESSION_AMD_ID" --force >/dev/null 2>&1 || true
    fi
    if [[ -n "$SESSION_ARM_ID" && "$SESSION_ARM_ID" != "null" ]]; then
        echo "  🗑️ Deleting ARM Bastion session: $SESSION_ARM_ID"
        oci bastion session delete --session-id "$SESSION_ARM_ID" --force >/dev/null 2>&1 || true
    fi
    echo "✅ Ephemeral resources cleaned up."
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

get_free_port() {
    while true; do
        local port=$((RANDOM % 30000 + 15000))
        if ! lsof -i:"$port" >/dev/null 2>&1; then
            echo "$port"
            return
        fi
    done
}

PORT_AMD=$(get_free_port)
PORT_ARM=$(get_free_port)
while [[ "$PORT_ARM" == "$PORT_AMD" ]]; do
    PORT_ARM=$(get_free_port)
done

echo "=================================================================="
echo "🚀 Establishing Ephemeral OCI Bastion Bridge for Ansible"
echo "   AMD (10.0.0.160) -> 127.0.0.1:$PORT_AMD"
echo "   ARM (10.0.0.200) -> 127.0.0.1:$PORT_ARM"
echo "=================================================================="

echo "[1/4] Creating ephemeral port-forwarding sessions in OCI Bastion..."
SESSION_AMD_JSON=$(oci bastion session create-port-forwarding \
    --bastion-id "$BASTION_ID" \
    --display-name "Ansible_AMD_$(date +%s)" \
    --ssh-public-key-file "$SSH_KEY_PUB" \
    --target-resource-id "$AMD_ID" \
    --target-port 22 \
    --session-ttl 3600)
SESSION_AMD_ID=$(echo "$SESSION_AMD_JSON" | jq -r '.data.id')

SESSION_ARM_JSON=$(oci bastion session create-port-forwarding \
    --bastion-id "$BASTION_ID" \
    --display-name "Ansible_ARM_$(date +%s)" \
    --ssh-public-key-file "$SSH_KEY_PUB" \
    --target-resource-id "$ARM_ID" \
    --target-port 22 \
    --session-ttl 3600)
SESSION_ARM_ID=$(echo "$SESSION_ARM_JSON" | jq -r '.data.id')

echo "  ✓ AMD Session: $SESSION_AMD_ID"
echo "  ✓ ARM Session: $SESSION_ARM_ID"

echo "[2/4] Waiting for both sessions to become ACTIVE..."
for item in "AMD:$SESSION_AMD_ID" "ARM:$SESSION_ARM_ID"; do
    node="${item%%:*}"
    sid="${item##*:}"
    while true; do
        state=$(oci bastion session get --session-id "$sid" | jq -r '.data."lifecycle-state"')
        if [[ "$state" == "ACTIVE" ]]; then
            break
        elif [[ "$state" == "FAILED" ]]; then
            echo "❌ Bastion session for $node failed to initialize."
            exit 1
        fi
        sleep 2
    done
done
echo "  ✓ Both sessions are ACTIVE. Waiting for key propagation (8s)..."
sleep 8

echo "[3/4] Establishing local SSH tunnels in background..."
ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "$SSH_KEY_PRIV" -N -L "$PORT_AMD:10.0.0.160:22" -p 22 "$SESSION_AMD_ID@host.bastion.us-ashburn-1.oci.oraclecloud.com" &
TUNNEL_AMD_PID=$!

ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "$SSH_KEY_PRIV" -N -L "$PORT_ARM:10.0.0.200:22" -p 22 "$SESSION_ARM_ID@host.bastion.us-ashburn-1.oci.oraclecloud.com" &
TUNNEL_ARM_PID=$!

sleep 3
echo "  ✓ Local SSH tunnels established."

echo "[4/4] Executing Ansible playbook through Bastion bridge..."
echo "------------------------------------------------------------------"
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook "$@" \
    -e "bastion_amd_host=127.0.0.1" \
    -e "bastion_amd_port=$PORT_AMD" \
    -e "bastion_arm_host=127.0.0.1" \
    -e "bastion_arm_port=$PORT_ARM"

echo "------------------------------------------------------------------"
echo "✅ Ansible execution completed successfully."
