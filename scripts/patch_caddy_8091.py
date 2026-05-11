#!/usr/bin/env python3
"""
patch_caddy_8091.py — Replace the :8091 block in /etc/caddy/Caddyfile
to serve UBIK frontend from /var/www/ubik instead of proxying the SSH tunnel.
Idempotent: skips if the block already contains "root * /var/www/ubik".
"""
import re
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

# Replace the :8091 { ... } block (greedy match across lines)
patched = re.sub(r":8091 \{[^}]*(?:\{[^}]*\}[^}]*)?\}", NEW_BLOCK, content, flags=re.DOTALL)

if patched == content:
    print("ERROR: Could not find :8091 block in Caddyfile.", file=sys.stderr)
    sys.exit(1)

with open(CADDYFILE, "w") as f:
    f.write(patched)

print("Caddyfile patched. Reloading Caddy…")
subprocess.run(["sudo", "systemctl", "reload", "caddy"], check=True)
print("Done.")
