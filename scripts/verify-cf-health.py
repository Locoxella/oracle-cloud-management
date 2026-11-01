#!/usr/bin/env python3
"""
Cloudflare API Verification & Health Audit Script.

Verifies:
  1. API Token authentication and permissions.
  2. Cloudflare Tunnels status and active edge connections (aether-tunnel, pi-home-tunnel).
  3. Tunnel ingress routing rules across tunnels.
  4. Zero Trust Access applications and active policies (Dockge Manager, WebSocket Bypass, WG-Easy).
  5. DNS Zone status.

Requirements:
  Python 3.8+ (Zero external dependencies; uses standard library urllib).
"""

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path


def load_env(env_path: Path) -> None:
    """Simple parser to load .env variables without external libraries."""
    if not env_path.is_file():
        return
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, val = line.split("=", 1)
            key = key.strip()
            val = val.strip().strip("\"'")
            if key and key not in os.environ:
                os.environ[key] = val


def cf_api_get(endpoint: str, token: str) -> dict:
    """Execute GET request to Cloudflare v4 API."""
    url = f"https://api.cloudflare.com/client/v4/{endpoint.lstrip('/')}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "Antigravity-Cloudflare-Auditor/1.0",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            err_data = json.loads(body)
            msgs = [err.get("message", "Unknown error") for err in err_data.get("errors", [])]
            err_msg = ", ".join(msgs) if msgs else body
        except Exception:
            err_msg = body
        raise RuntimeError(f"HTTP {e.code}: {err_msg}") from e
    except Exception as e:
        raise RuntimeError(f"Connection error: {e}") from e


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    load_env(repo_root / ".env")

    token = os.environ.get("CLOUDFLARE_API_TOKEN")
    if not token and (repo_root / ".cloudflare_token").is_file():
        token = (repo_root / ".cloudflare_token").read_text(encoding="utf-8").strip()
    account_id = os.environ.get("CLOUDFLARE_ACCOUNT_ID", "2a49278db7ba9207c09be9d2c3e9669a")
    zone_id = os.environ.get("CLOUDFLARE_ZONE_ID", "6904c05ddc4a10898d60f7bf50e86938")

    # Known Tunnels
    TUNNELS = [
        {"name": "aether-tunnel", "id": os.environ.get("CLOUDFLARE_TUNNEL_ID", "557b120e-553b-42f5-bc65-d2ffb9800ea6")},
        {"name": "pi-home-tunnel", "id": "63795e0e-ef77-4758-aa7a-9b75611b5d2c"},
    ]

    print("\033[1;34m=== Cloudflare Configuration & Health Audit ===\033[0m\n")

    if not token or token == "your_cloudflare_api_token_here":
        print("\033[1;33m[SKIPPED]\033[0m CLOUDFLARE_API_TOKEN is not configured.")
        print("Please configure CLOUDFLARE_API_TOKEN in .env or CI secrets to run this audit.")
        return 0

    all_passed = True

    # 1. Verify Token
    try:
        tok_data = cf_api_get("user/tokens/verify", token)
        if tok_data.get("success") and tok_data.get("result", {}).get("status") == "active":
            print("\033[0;32m[ PASS ]\033[0m API Token: Valid and active")
        else:
            print(f"\033[0;31m[ FAIL ]\033[0m API Token status: {tok_data}")
            all_passed = False
    except Exception as e:
        print(f"\033[0;31m[ FAIL ]\033[0m API Token verification failed: {e}")
        return 1

    # 2. Check DNS Zone
    try:
        zone_data = cf_api_get(f"zones/{zone_id}", token)
        zone_info = zone_data.get("result", {})
        zone_name = zone_info.get("name", "unknown")
        zone_status = zone_info.get("status", "unknown")
        if zone_status == "active":
            print(f"\033[0;32m[ PASS ]\033[0m DNS Zone: {zone_name} is active")
        else:
            print(f"\033[1;33m[ WARN ]\033[0m DNS Zone: {zone_name} status is {zone_status}")
    except Exception as e:
        print(f"\033[0;31m[ FAIL ]\033[0m Failed to inspect DNS Zone: {e}")
        all_passed = False

    # 3. Check Tunnels Status & Ingress
    for tun_entry in TUNNELS:
        tun_id = tun_entry["id"]
        tun_label = tun_entry["name"]
        try:
            tun_data = cf_api_get(f"accounts/{account_id}/cfd_tunnel/{tun_id}", token)
            tun = tun_data.get("result", {})
            tun_name = tun.get("name", tun_label)
            tun_status = tun.get("status", "unknown")
            active_conns = len(tun.get("connections", []))
            
            if tun_status == "healthy":
                print(f"\033[0;32m[ PASS ]\033[0m Tunnel '{tun_name}': Healthy ({active_conns} active edge connections)")
            else:
                print(f"\033[0;31m[ FAIL ]\033[0m Tunnel '{tun_name}': Status is {tun_status} ({active_conns} connections)")
                all_passed = False
        except Exception as e:
            print(f"\033[0;31m[ FAIL ]\033[0m Failed to inspect Tunnel '{tun_label}': {e}")
            all_passed = False

        # Ingress rules check
        try:
            cfg_data = cf_api_get(f"accounts/{account_id}/cfd_tunnel/{tun_id}/configurations", token)
            ingress = cfg_data.get("result", {}).get("config", {}).get("ingress", [])
            mapped_hostnames = [item.get("hostname") for item in ingress if item.get("hostname")]
            print(f"\033[0;32m[ PASS ]\033[0m Ingress '{tun_label}': {len(mapped_hostnames)} routes active ({', '.join(mapped_hostnames)})")
        except Exception as e:
            print(f"\033[0;31m[ FAIL ]\033[0m Failed to inspect Tunnel Ingress for '{tun_label}': {e}")
            all_passed = False

    # 4. Check Zero Trust Access Applications
    try:
        apps_data = cf_api_get(f"accounts/{account_id}/access/apps", token)
        apps = apps_data.get("result", [])
        app_names = {a.get("name"): a for a in apps}
        
        expected_apps = [
            "Dockge Manager",
            "Dockge Socket.IO WebSocket Bypass",
            "WG-Easy VPN Admin",
        ]
        for app_name in expected_apps:
            if app_name in app_names:
                app = app_names[app_name]
                policies = app.get("policies", [])
                domains = app.get("self_hosted_domains", [app.get("domain")])
                print(f"\033[0;32m[ PASS ]\033[0m Zero Trust App '{app_name}': Active ({len(policies)} policies, domains: {', '.join(domains)})")
            else:
                print(f"\033[0;31m[ FAIL ]\033[0m Zero Trust App '{app_name}': Not found in Cloudflare Access")
                all_passed = False
    except Exception as e:
        print(f"\033[0;31m[ FAIL ]\033[0m Failed to inspect Access Applications: {e}")
        all_passed = False

    print()
    if all_passed:
        print("\033[1;32mAudit Result: All Cloudflare configurations are verified and healthy.\033[0m")
        return 0
    else:
        print("\033[1;31mAudit Result: Discrepancies or failures were detected.\033[0m")
        return 1


if __name__ == "__main__":
    sys.exit(main())
