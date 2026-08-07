import requests

TOKEN = "REDACTED_CLOUDFLARE_API_TOKEN"
ACCOUNT_ID = "2a49278db7ba9207c09be9d2c3e9669a"
APP_ID = "c26820fc-79c8-4a01-8c39-ddc33e93a3d8"
GOOGLE_IDP_ID = "b02151b8-b595-42b6-b3f4-285268aca3f6"

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# Fetch full app first
r = requests.get(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps/{APP_ID}", headers=HEADERS)
app = r.json()["result"]

app["allowed_idps"] = [GOOGLE_IDP_ID]

r = requests.put(f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/access/apps/{APP_ID}", headers=HEADERS, json=app)
res = r.json()
if res.get("success"):
    print("✅ App successfully updated to use Google Login exclusively!")
else:
    print("❌ Error:", res)
