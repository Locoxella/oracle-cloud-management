import requests

TOKEN = "REDACTED_CLOUDFLARE_API_TOKEN"
ACCOUNT_ID = "2a49278db7ba9207c09be9d2c3e9669a"
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

CLIENT_ID = "REDACTED_GOOGLE_CLIENT_ID"
CLIENT_SECRET = "REDACTED_GOOGLE_CLIENT_SECRET"

# 1. Check existing IdPs
print("🔍 Checking existing Identity Providers in Cloudflare...")
r = requests.get(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/identity_providers", headers=HEADERS)
idps = r.json().get("result", [])

google_idp_id = None
for idp in idps:
    if idp["type"] == "google":
        google_idp_id = idp["id"]
        print(f"✅ Found existing Google IdP: {google_idp_id}")
        break

if not google_idp_id:
    print("🚀 Adding Google Identity Provider to Cloudflare Access...")
    idp_payload = {
        "name": "Google Login",
        "type": "google",
        "config": {
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET
        }
    }
    r = requests.post(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/identity_providers", headers=HEADERS, json=idp_payload)
    res = r.json()
    if not res.get("success"):
        print("❌ Failed to create Google IdP:", res)
        exit(1)
    google_idp_id = res["result"]["id"]
    print(f"✅ Google Identity Provider added with ID: {google_idp_id}")

# 2. Get Access App ID for wg.solucionesaustral.com
r = requests.get(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps", headers=HEADERS)
apps = r.json().get("result", [])
app_id = None
for app in apps:
    if app["domain"] == "wg.solucionesaustral.com":
        app_id = app["id"]
        break

if app_id:
    print(f"🔄 Updating App {app_id} to enable Google Identity Provider...")
    # Update app allowed_idps
    app_update_payload = {
        "allowed_idps": [google_idp_id]
    }
    r = requests.put(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps/{app_id}", headers=HEADERS, json=app_update_payload)
    res = r.json()
    if res.get("success"):
        print("✅ App updated successfully with Google IdP!")
    else:
        print("⚠️ Warning updating app:", res)
else:
    print("❌ Access App for wg.solucionesaustral.com not found!")

