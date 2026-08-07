import requests
import json

TOKEN = open('.cloudflare_token').read().strip()
ACCOUNT_ID = '2a49278db7ba9207c09be9d2c3e9669a'
ZONE_ID = '6904c05ddc4a10898d60f7bf50e86938'
tunnel_id = '557b120e-553b-42f5-bc65-d2ffb9800ea6'

headers = {
    'Authorization': f'Bearer {TOKEN}',
    'Content-Type': 'application/json'
}

# Configure Tunnel Routing
print("Configuring tunnel routing for WG-Easy...")
config = {
    "config": {
        "ingress": [
            {
                "hostname": "git.solucionesaustral.com",
                "service": "http://server:3000"
            },
            {
                "hostname": "git-ssh.solucionesaustral.com",
                "service": "tcp://server:22"
            },
            {
                "hostname": "wg.solucionesaustral.com",
                "service": "http://wg-easy:51821"
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

# Route DNS for WG-Easy
print("Routing DNS for wg.solucionesaustral.com...")
dns_record = {
    "type": "CNAME",
    "name": "wg",
    "content": f"{tunnel_id}.cfargotunnel.com",
    "proxied": True
}
res = requests.get(f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dns_records?name=wg.solucionesaustral.com", headers=headers)
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
