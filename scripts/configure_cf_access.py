import requests
from cf_common import ACCOUNT_ID, get_headers

HEADERS = get_headers()

# 1. Check if app already exists
print("🔍 Checking existing Access Applications...")
r = requests.get(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps", headers=HEADERS)
apps = r.json().get("result", [])
app_id = None
for app in apps:
    if app["domain"] == "wg.solucionesaustral.com":
        app_id = app["id"]
        print(f"✅ App already exists with ID: {app_id}")
        break

# 2. Create app if not exists
if not app_id:
    print("🚀 Creating new Cloudflare Access Application for wg.solucionesaustral.com...")
    app_payload = {
        "name": "WG-Easy VPN Admin",
        "domain": "wg.solucionesaustral.com",
        "type": "self_hosted",
        "session_duration": "24h"
    }
    r = requests.post(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps", headers=HEADERS, json=app_payload)
    res = r.json()
    if not res.get("success"):
        print("❌ Failed to create App:", res)
        exit(1)
    app_id = res["result"]["id"]
    print(f"✅ App created successfully with ID: {app_id}")

# 3. Check existing policies
print("🔍 Checking existing policies...")
r = requests.get(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps/{app_id}/policies", headers=HEADERS)
policies = r.json().get("result", [])
if policies:
    print("✅ Policy already exists!")
else:
    print("🚀 Creating allow policy for locoxella@gmail.com...")
    policy_payload = {
        "name": "Allow Owner",
        "decision": "allow",
        "include": [{"email": {"email": "locoxella@gmail.com"}}]
    }
    r = requests.post(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps/{app_id}/policies", headers=HEADERS, json=policy_payload)
    res = r.json()
    if not res.get("success"):
        print("❌ Failed to create Policy:", res)
        exit(1)
    print("✅ Policy created successfully!")
