#!/usr/bin/env bash
# ==============================================================================
# Aether GitOps Pre-Flight (Dry-Run) & Post-Apply Verification Suite
# Usage:
#   ./scripts/verify_infra.sh          # Static & Dry-Run checks (safe for CI/PR)
#   ./scripts/verify_infra.sh --live   # Includes live Post-Apply endpoint & node checks
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LIVE_MODE=false
if [[ "${1:-}" == "--live" ]]; then
    LIVE_MODE=true
fi

echo "=================================================================="
echo "🛡️  [1/6] Security & Secret Leak Guard (Public GitHub Readiness)"
echo "=================================================================="
# Ensure sensitive files are ignored by Git
for secret_path in ".env" ".cloudflare_token" ".tunnel_token" "infrastructure/terraform.tfstate" "secrets/key.pem"; do
    if ! git check-ignore -q "$secret_path"; then
        echo "❌ FAIL: '$secret_path' is NOT ignored by .gitignore!"
        exit 1
    fi
done

# Scan tracked files for accidental hardcoded tokens or private keys
if git grep -En "cfat_[A-Za-z0-9_-]{20,}|GOCSPX-[A-Za-z0-9_-]{15,}|-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----" -- ':!scripts/verify_infra.sh'; then
    echo "❌ FAIL: Potential hardcoded secret detected in tracked files!"
    exit 1
fi
echo "✅ Zero hardcoded secrets in tracked files & .gitignore rules verified."

echo ""
echo "=================================================================="
echo "🐚 [2/6] Bash Scripts Syntax Check (bash -n)"
echo "=================================================================="
for sh_file in connect_vm.sh scp_to_vm.sh scripts/*.sh bootstrap/setup_node.sh bootstrap/scripts/*.sh archive/hunters/*.sh; do
    if [[ -f "$sh_file" ]]; then
        bash -n "$sh_file"
        echo "  ✓ $sh_file"
    fi
done
echo "✅ All Bash scripts passed syntax check."

echo ""
echo "=================================================================="
echo "🐍 [3/6] Python Scripts Compilation Check (py_compile)"
echo "=================================================================="
python3 -m py_compile scripts/*.py archive/hunters/arm-hunter/app.py
echo "✅ All Python scripts compiled cleanly."

echo ""
echo "=================================================================="
echo "📦 [4/6] Docker Compose & Ansible YAML Schema Validation"
echo "=================================================================="
if command -v docker >/dev/null 2>&1; then
    for compose_file in \
        bootstrap/infrastructure/management/compose.yaml \
        bootstrap/stacks/network/compose.yaml \
        bootstrap/stacks/git/compose.yaml \
        bootstrap/stacks/subastas/compose.yaml \
        archive/hunters/arm-hunter/docker-compose.yml; do
        docker compose -f "$compose_file" config -q
        echo "  ✓ $compose_file"
    done
else
    echo "  ⚠️ docker CLI not found; validating Compose YAML via Python..."
fi

python3 -c "
import yaml, glob, sys
files = glob.glob('ansible/**/*.yml', recursive=True) + glob.glob('bootstrap/**/*.yaml', recursive=True) + glob.glob('.github/workflows/*.yml') + glob.glob('.gitea/workflows/*.yml')
for f in sorted(files):
    with open(f) as fp:
        list(yaml.safe_load_all(fp))
    print(f'  ✓ YAML valid: {f}')
"

if command -v ansible-playbook >/dev/null 2>&1; then
    ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbooks/site.yml --syntax-check
    ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbooks/verify.yml --syntax-check
    echo "  ✓ Ansible playbooks passed --syntax-check"
fi
echo "✅ Compose and Ansible YAML definitions verified."

echo ""
echo "=================================================================="
echo "🏗️  [5/6] OpenTofu / Terraform Formatting & Validation (Dry-Run)"
echo "=================================================================="
if command -v tofu >/dev/null 2>&1; then
    tofu fmt -check infrastructure/
    (cd infrastructure && tofu init -backend=false && tofu validate)
    echo "✅ OpenTofu configuration formatted and valid."
elif command -v terraform >/dev/null 2>&1; then
    terraform fmt -check infrastructure/
    (cd infrastructure && terraform init -backend=false && terraform validate)
    echo "✅ Terraform configuration formatted and valid."
else
    echo "⚠️ Neither tofu nor terraform binary found in PATH (skipping CLI check)."
fi

echo ""
echo "=================================================================="
echo "🌐 [6/6] Post-Apply / Live Infrastructure Verification"
echo "=================================================================="
if [[ "$LIVE_MODE" != "true" ]]; then
    echo "ℹ️  Dry-Run complete. Pass '--live' to execute empirical post-apply checks."
    exit 0
fi

check_http() {
    local url="$1"
    local expected="$2"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 "$url" || echo "000")
    if [[ "$code" == "$expected" ]]; then
        echo "  ✓ $url -> HTTP $code (Expected $expected)"
    else
        echo "  ❌ $url -> HTTP $code (Expected $expected)"
        exit 1
    fi
}

echo "Checking public and Zero-Trust endpoints via Cloudflare Edge..."
check_http "https://git.solucionesaustral.com" "200"
check_http "https://subastas.solucionesaustral.com" "200"
check_http "https://dockge.solucionesaustral.com" "302"
check_http "https://dockge-arm.solucionesaustral.com" "302"
check_http "https://dockge-pi.solucionesaustral.com" "302"
check_http "https://wg.solucionesaustral.com" "302"

if [[ -f ".cloudflare_token" ]] || [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "Running comprehensive Cloudflare Health & Ingress Audit..."
    python3 scripts/verify-cf-health.py
fi

echo "✅ All Pre-Flight and Live Post-Apply checks PASSED!"
