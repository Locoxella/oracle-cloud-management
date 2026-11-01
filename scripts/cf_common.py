import os

ACCOUNT_ID = os.getenv("CLOUDFLARE_ACCOUNT_ID", "2a49278db7ba9207c09be9d2c3e9669a")

def get_cloudflare_token():
    token = os.getenv("CLOUDFLARE_API_TOKEN")
    if token:
        return token
    for candidate in [".cloudflare_token", "../.cloudflare_token", os.path.expanduser("~/.cloudflare_token")]:
        if os.path.exists(candidate):
            with open(candidate) as f:
                return f.read().strip()
    raise RuntimeError(
        "Missing Cloudflare API Token. Set CLOUDFLARE_API_TOKEN environment variable or .cloudflare_token file."
    )

def get_headers():
    token = get_cloudflare_token()
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
