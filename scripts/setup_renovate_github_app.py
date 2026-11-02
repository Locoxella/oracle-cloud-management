#!/usr/bin/env python3
"""
Automated GitHub App Creator for Renovate Bot via GitHub App Manifest.

This script:
1. Spins up a temporary local HTTP server (port 8921).
2. Serves an auto-submitting form to GitHub with pre-configured scoped permissions:
   - contents: write
   - pull_requests: write
   - issues: write
   - workflows: write
   - webhooks: disabled
3. Opens the URL in the local browser.
4. User clicks "Create GitHub App from manifest" (one click).
5. GitHub redirects back to http://127.0.0.1:8921/callback?code=...
6. Exchanges the temporary code with GitHub API for the App ID and RSA Private Key.
7. Automatically configures APPLICATION_ID and APPLICATION_PRIVATE_KEY in repo secrets via `gh secret set`.
8. Redirects the browser to the App installation page so the user can click "Install".
"""

import http.server
import json
import os
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
import webbrowser

PORT = 8921
TARGET_REPO = "Locoxella/oracle-cloud-management"
APP_NAME = "locoxella-renovate-bot"

MANIFEST = {
    "name": APP_NAME,
    "url": f"https://github.com/{TARGET_REPO}",
    "hook_attributes": {
        "url": f"https://github.com/{TARGET_REPO}",
        "active": False
    },
    "redirect_url": f"http://127.0.0.1:{PORT}/callback",
    "public": False,
    "default_permissions": {
        "contents": "write",
        "pull_requests": "write",
        "issues": "write",
        "workflows": "write"
    },
    "default_events": []
}

class ManifestHandler(http.server.BaseHTTPRequestHandler):
    app_result = None

    def log_message(self, format, *args):
        # Quiet standard HTTP access logging to keep terminal output clean
        pass

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/":
            manifest_json = json.dumps(MANIFEST)
            html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Register Renovate GitHub App</title>
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #0d1117;
      color: #c9d1d9;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }}
    .box {{
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 8px;
      padding: 32px;
      max-width: 480px;
      text-align: center;
      box-shadow: 0 8px 24px rgba(0,0,0,0.5);
    }}
    h1 {{ font-size: 20px; color: #58a6ff; margin-top: 0; }}
    p {{ font-size: 14px; line-height: 1.5; color: #8b949e; }}
    button {{
      background: #238636;
      color: #fff;
      border: none;
      padding: 10px 24px;
      font-size: 15px;
      font-weight: 600;
      border-radius: 6px;
      cursor: pointer;
      margin-top: 16px;
    }}
    button:hover {{ background: #2ea043; }}
  </style>
</head>
<body>
  <div class="box">
    <h1>🤖 Register Renovate GitHub App</h1>
    <p>Redirecting to GitHub to generate the App with scoped permissions...</p>
    <form id="manifest-form" action="https://github.com/settings/apps/new" method="post">
      <input type="hidden" name="manifest" value='{manifest_json}'>
      <button type="submit">Click here to continue to GitHub</button>
    </form>
    <script>
      setTimeout(function() {{
        document.getElementById('manifest-form').submit();
      }}, 300);
    </script>
  </div>
</body>
</html>"""
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(html.encode("utf-8"))

        elif parsed.path == "/callback":
            query = urllib.parse.parse_qs(parsed.query)
            code = query.get("code", [None])[0]

            if not code:
                self.send_response(400)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"Missing code in callback query")
                return

            try:
                # Exchange temporary code for App credentials
                req = urllib.request.Request(
                    f"https://api.github.com/app-manifests/{code}/conversions",
                    data=b"",
                    headers={
                        "Accept": "application/vnd.github+json",
                        "User-Agent": "Locoxella-Renovate-Setup"
                    },
                    method="POST"
                )
                with urllib.request.urlopen(req) as resp:
                    resp_data = json.loads(resp.read().decode("utf-8"))

                ManifestHandler.app_result = resp_data
                app_id = str(resp_data.get("id"))
                pem = resp_data.get("pem")
                slug = resp_data.get("slug", APP_NAME)

                print(f"\n[+] GitHub App successfully created: {resp_data.get('name')} (ID: {app_id})")
                print(f"[+] Setting repository secrets in {TARGET_REPO}...")

                # Set APPLICATION_ID secret
                subprocess.run(
                    ["gh", "secret", "set", "APPLICATION_ID", "-R", TARGET_REPO, "--body", app_id],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                print(f"    ✔ APPLICATION_ID set")

                # Set APPLICATION_PRIVATE_KEY secret
                subprocess.run(
                    ["gh", "secret", "set", "APPLICATION_PRIVATE_KEY", "-R", TARGET_REPO, "--body", pem],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                print(f"    ✔ APPLICATION_PRIVATE_KEY set")

                install_url = f"https://github.com/apps/{slug}/installations/new"

                success_html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Setup Complete!</title>
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #0d1117;
      color: #c9d1d9;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }}
    .box {{
      background: #161b22;
      border: 1px solid #238636;
      border-radius: 8px;
      padding: 32px;
      max-width: 520px;
      text-align: center;
      box-shadow: 0 8px 24px rgba(0,0,0,0.5);
    }}
    h1 {{ font-size: 22px; color: #3fb950; margin-top: 0; }}
    p {{ font-size: 14px; line-height: 1.5; color: #8b949e; }}
    .btn {{
      display: inline-block;
      background: #238636;
      color: #fff;
      text-decoration: none;
      padding: 12px 24px;
      font-size: 15px;
      font-weight: 600;
      border-radius: 6px;
      margin-top: 20px;
    }}
    .btn:hover {{ background: #2ea043; }}
  </style>
</head>
<body>
  <div class="box">
    <h1>🎉 GitHub App Created & Secrets Set!</h1>
    <p>Repository secrets <code>APPLICATION_ID</code> and <code>APPLICATION_PRIVATE_KEY</code> are now securely configured in <strong>{TARGET_REPO}</strong>.</p>
    <p>Final Step: Install the App on your repository to grant it access.</p>
    <a class="btn" href="{install_url}">Install App on Repository</a>
    <script>
      setTimeout(function() {{
        window.location.href = "{install_url}";
      }}, 1200);
    </script>
  </div>
</body>
</html>"""
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(success_html.encode("utf-8"))

            except Exception as e:
                print(f"[!] Error handling manifest callback: {e}", file=sys.stderr)
                self.send_response(500)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(f"Error: {e}".encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

def main():
    server_address = ("127.0.0.1", PORT)
    httpd = http.server.HTTPServer(server_address, ManifestHandler)

    print("=" * 70)
    print("🤖 AUTOMATED GITHUB APP CREATION FOR RENOVATE")
    print("=" * 70)
    print(f"Target Repository : {TARGET_REPO}")
    print(f"App Name          : {APP_NAME}")
    print(f"Listening on      : http://127.0.0.1:{PORT}")
    print("-" * 70)
    print("Opening browser for one-click confirmation...")

    def open_browser():
        time.sleep(0.5)
        webbrowser.open(f"http://127.0.0.1:{PORT}")

    threading.Thread(target=open_browser, daemon=True).start()

    while ManifestHandler.app_result is None:
        httpd.handle_request()

    print("-" * 70)
    print("✅ Setup complete! App is created and secrets are configured.")
    print("=" * 70)

if __name__ == "__main__":
    main()
