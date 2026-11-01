#!/usr/bin/env python3
"""
Cloudflare Configuration Backup & Disaster Recovery Export Tool.

Exports:
  - DNS Zone records
  - Cloudflare Tunnel details and Ingress routing rules
  - Zero Trust Access Applications and Policies

Outputs to backups/cloudflare-backup-<timestamp>.json (gitignored).
"""

import json
import os
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


def load_env(env_path: Path) -> None:
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


def cf_get(endpoint: str, token: str) -> dict:
    url = f"https://api.cloudflare.com/client/v4/{endpoint.lstrip('/')}"
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    load_env(repo_root / ".env")

    token = os.environ.get("CLOUDFLARE_API_TOKEN")
    if not token and (repo_root / ".cloudflare_token").is_file():
        token = (repo_root / ".cloudflare_token").read_text(encoding="utf-8").strip()
    account_id = os.environ.get("CLOUDFLARE_ACCOUNT_ID", "2a49278db7ba9207c09be9d2c3e9669a")
    zone_id = os.environ.get("CLOUDFLARE_ZONE_ID", "6904c05ddc4a10898d60f7bf50e86938")
    tunnel_id = os.environ.get("CLOUDFLARE_TUNNEL_ID", "557b120e-553b-42f5-bc65-d2ffb9800ea6")

    if not token or token == "your_cloudflare_api_token_here":
        print("Error: CLOUDFLARE_API_TOKEN is required in .env or environment.")
        return 1

    print("Fetching Cloudflare configuration snapshot...")
    backup_data = {
        "metadata": {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "account_id": account_id,
            "zone_id": zone_id,
            "tunnel_id": tunnel_id,
        },
        "dns_records": cf_get(f"zones/{zone_id}/dns_records?per_page=100", token).get("result", []),
        "tunnel": cf_get(f"accounts/{account_id}/cfd_tunnel/{tunnel_id}", token).get("result", {}),
        "tunnel_ingress": cf_get(f"accounts/{account_id}/cfd_tunnel/{tunnel_id}/configurations", token).get("result", {}),
        "access_apps": cf_get(f"accounts/{account_id}/access/apps", token).get("result", []),
    }

    backup_dir = repo_root / "backups"
    backup_dir.mkdir(parents=True, exist_ok=True)

    timestamp_str = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%SZ")
    backup_file = backup_dir / f"cloudflare-backup-{timestamp_str}.json"
    latest_file = backup_dir / "latest.json"

    with open(backup_file, "w", encoding="utf-8") as f:
        json.dump(backup_data, f, indent=2)

    with open(latest_file, "w", encoding="utf-8") as f:
        json.dump(backup_data, f, indent=2)

    print(f"Backup saved to: {backup_file}")
    print(f"Latest snapshot updated: {latest_file}")
    print(f"Summary: {len(backup_data['dns_records'])} DNS records, {len(backup_data['access_apps'])} Access Apps.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
