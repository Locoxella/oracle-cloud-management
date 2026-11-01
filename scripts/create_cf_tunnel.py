import requests
import json
import base64
import os
from cf_common import ACCOUNT_ID, get_headers

ZONE_ID = os.getenv("CLOUDFLARE_ZONE_ID", "6904c05ddc4a10898d60f7bf50e86938")
headers = get_headers()

# 1. Create Tunnel Secret (32 bytes base64)
secret_bytes = os.urandom(32)
tunnel_secret = base64.b64encode(secret_bytes).decode('utf-8')

# 2. Create Tunnel
print("Creating tunnel...")
res = requests.post(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/cfd_tunnel", headers=headers, json={
    "name": "aether-tunnel",
    "tunnel_secret": tunnel_secret
})
res_json = res.json()
if not res_json.get('success'):
    print("Error creating tunnel:", res_json)
    exit(1)
tunnel_id = res_json['result']['id']
print(f"Tunnel created: {tunnel_id}")

# 3. Create Tunnel Token
token_data = json.dumps({"a": ACCOUNT_ID, "t": tunnel_id, "s": tunnel_secret}).encode('utf-8')
tunnel_token = base64.b64encode(token_data).decode('utf-8')
print(f"Tunnel Token: {tunnel_token}")
with open('.tunnel_token', 'w') as f:
    f.write(tunnel_token)

# 4. Configure Tunnel Routing
print("Configuring tunnel routing...")
config = {
    "config": {
        "ingress": [
            {
                "hostname": "git.solucionesaustral.com",
                "service": "http://server:3000"
            },
            {
                "service": "http_status:404"
            }
        ]
    }
}
res = requests.put(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/cfd_tunnel/{tunnel_id}/configurations", headers=headers, json=config)
if not res.json().get('success'):
    print("Error configuring tunnel:", res.json())
    exit(1)
print("Tunnel configured.")

# 5. Route DNS
print("Routing DNS...")
dns_record = {
    "type": "CNAME",
    "name": "git.solucionesaustral.com",
    "content": f"{tunnel_id}.cfargotunnel.com",
    "proxied": True
}
# Find existing record
res = requests.get(f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dns_records?name=git.solucionesaustral.com", headers=headers)
records = res.json().get('result', [])
if records:
    record_id = records[0]['id']
    res = requests.put(f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dns_records/{record_id}", headers=headers, json=dns_record)
else:
    res = requests.post(f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dns_records", headers=headers, json=dns_record)

if not res.json().get('success'):
    print("Error routing DNS:", res.json())
    exit(1)
print("DNS routed successfully!")
