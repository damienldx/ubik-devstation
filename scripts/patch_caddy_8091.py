#!/usr/bin/env python3
"""
patch_caddy_8091.py — Replace the :8091 block in /etc/caddy/Caddyfile
to serve UBIK frontend from /var/www/ubik instead of proxying the SSH tunnel.
Idempotent: skips if the block already contains "root * /var/www/ubik".
"""
import subprocess
import sys

CADDYFILE = "/etc/caddy/Caddyfile"

NEW_BLOCK = """\
:8091 {
    header {
        -X-Frame-Options
        Access-Control-Allow-Origin *
    }

    handle /relay* {
        reverse_proxy localhost:7894
    }

    handle /api/* {
        reverse_proxy localhost:8765
    }

    handle /pty* {
        reverse_proxy localhost:8765
    }

    handle {
        root * /var/www/ubik
        file_server
        try_files {path} /index.html
    }

    @html {
        path *.html
        path /
    }
    header @html Cache-Control "no-cache, no-store, must-revalidate"
    header /assets/* Cache-Control "public, max-age=31536000, immutable"
}"""

with open(CADDYFILE) as f:
    content = f.read()

if "root * /var/www/ubik" in content:
    print("Caddyfile already patched — skipping.")
    sys.exit(0)

# Find :8091 block with brace-counting (handles any nesting depth)
start = content.find(":8091 {")
if start == -1:
    print("ERROR: Could not find :8091 block in Caddyfile.", file=sys.stderr)
    sys.exit(1)

depth, i = 0, start
while i < len(content):
    if content[i] == "{":
        depth += 1
    elif content[i] == "}":
        depth -= 1
        if depth == 0:
            end = i + 1
            break
    i += 1
else:
    print("ERROR: Unbalanced braces in :8091 block.", file=sys.stderr)
    sys.exit(1)

patched = content[:start] + NEW_BLOCK + content[end:]

with open(CADDYFILE, "w") as f:
    f.write(patched)

print("Caddyfile patched. Reloading Caddy…")
subprocess.run(["sudo", "systemctl", "reload", "caddy"], check=True)
print("Done.")
